classdef CellposeDetect
    %CELLPOSEDETECT Adapter for Cellpose-style centroid detections.

    methods(Static)
        function [supervoxels, params] = detect(titlestr, data, scale_um_xyz, options)
            %DETECT Run the Cellpose wrapper and convert centroids to supervoxels.

            arguments
                titlestr
                data
                scale_um_xyz double
                options.Mode (1,1) string = "cellpose"
                options.PythonExecutable (1,1) string = ""
                options.ModelPath (1,1) string = ""
                options.Prefix (1,1) string = ""
                options.MaskSource (1,1) string = "stitched"
                options.OutputDir (1,1) string = ""
                options.KeepArtifacts (1,1) logical = true
                options.SaveMasksMat (1,1) logical = true
                options.ColorReadoutData = []
            end

            prefix = char(options.Prefix);
            if isempty(strtrim(prefix))
                prefix = Methods.CellposeDetect.sanitizePrefix(titlestr);
            end

            response = Wrapper.runCellposeCentroids(data, scale_um_xyz, ...
                'Mode', options.Mode, ...
                'PythonExecutable', options.PythonExecutable, ...
                'ModelPath', options.ModelPath, ...
                'Prefix', prefix, ...
                'MaskSource', options.MaskSource, ...
                'OutputDir', options.OutputDir, ...
                'KeepArtifacts', options.KeepArtifacts, ...
                'SaveMasksMat', options.SaveMasksMat);

            params = Methods.CellposeDetect.buildParams(response, 0);
            if ~isfield(response, 'centroids_xyz') || isempty(response.centroids_xyz)
                supervoxels = [];
                return;
            end

            centroids = double(response.centroids_xyz);
            if isvector(centroids)
                centroids = reshape(centroids, 1, []);
            end

            color_readout_data = Methods.CellposeDetect.resolveColorReadoutData( ...
                data, options.ColorReadoutData);
            supervoxels = Methods.CellposeDetect.centroidsToSupervoxels( ...
                centroids, color_readout_data);
            params = Methods.CellposeDetect.buildParams(response, size(supervoxels.positions, 1));
        end

        function BatchDetect(file, worm, ~)
            %BATCHDETECT Batch detect neurons using Cellpose.

            % Setup the conversion progress bar.
            wait_title = 'Converting Image';
            wb = waitbar(0, 'Converting ...', 'Name', wait_title);
            wb.Children.Title.Interpreter = 'none';
            waitbar(0, wb, {file, 'Converting ...'}, 'Name', wait_title);

            try
                [data, info, prefs, ~, ~, ~, np_file, id_file] = ...
                    DataHandling.NeuroPALImage.open(file);
            catch
                warning('Cannot read: "%s"', file);
                return;
            end

            try
                close(wb);
            catch
                warning('Image conversion was canceled.');
            end

            save(np_file, 'worm', '-append');

            rgbw = prefs.RGBW(~isnan(prefs.RGBW));
            data_RGBW = data(:,:,:,rgbw);
            readout_RGBW = Methods.Preprocess.zscore_frame(data_RGBW);
            [sp, mp] = Methods.CellposeDetect.detect(file, data_RGBW, info.scale', ...
                'ColorReadoutData', readout_RGBW);

            version = Program.ProgramInfo.version;
            mp_params = mp;
            neurons = Neurons.Image(sp, worm.body, 'scale', info.scale');
            Methods.Utils.removeNearbyNeurons(neurons, 2, 2);
            save(id_file, 'version', 'neurons', 'mp_params');
        end

        function supervoxels = centroidsToSupervoxels(centroids, data)
            %CENTROIDSTOSUPERVOXELS Convert centroid rows into NeuroPAL supervoxels.

            volume_size = size(data);
            if numel(volume_size) < 4
                volume_size(4) = 1;
            end

            positions = Methods.CellposeDetect.clampCentroids(centroids, volume_size(1:3));
            num_centroids = size(positions, 1);
            num_channels = volume_size(4);

            supervoxels = struct();
            supervoxels.positions = positions;
            supervoxels.covariances = zeros(num_centroids, 3, 3);
            supervoxels.color = zeros(num_centroids, num_channels);
            supervoxels.color_readout = zeros(num_centroids, num_channels);
            supervoxels.baseline = zeros(num_centroids, num_channels);
            supervoxels.truncation = zeros(num_centroids, 1);

            default_covariance = diag([10, 10, 3]);
            for i = 1:num_centroids
                supervoxels.covariances(i,:,:) = default_covariance;

                pos = positions(i,:);
                voxel_color = squeeze(data(pos(1), pos(2), pos(3), :))';
                supervoxels.color(i,:) = voxel_color;
                supervoxels.color_readout(i,:) = voxel_color;
            end
        end

        function centroids = clampCentroids(centroids, volume_size_xyz)
            %CLAMPCENTROIDS Round and clamp centroid coordinates into the volume.

            centroids = round(double(centroids));
            for axis = 1:3
                centroids(:, axis) = max(1, min(volume_size_xyz(axis), centroids(:, axis)));
            end
        end

        function color_readout_data = resolveColorReadoutData(data, color_readout_data)
            %RESOLVECOLORREADOUTDATA Validate the volume used for neuron colors.

            if isempty(color_readout_data)
                color_readout_data = data;
                return;
            end

            data_size = size(data);
            readout_size = size(color_readout_data);
            if numel(data_size) < 4
                data_size(4) = 1;
            end
            if numel(readout_size) < 4
                readout_size(4) = 1;
            end

            if ~isequal(data_size(1:3), readout_size(1:3))
                error('Methods:CellposeDetect:ColorReadoutSizeMismatch', ...
                    ['ColorReadoutData must have the same spatial dimensions ' ...
                     'as the Cellpose detection volume.']);
            end
        end

        function prefix = sanitizePrefix(text_value)
            %SANITIZEPREFIX Create a filesystem-friendly output prefix.
            prefix = regexprep(char(string(text_value)), '[^\w\-.+]+', '_');
            prefix = regexprep(prefix, '_+', '_');
            prefix = regexprep(prefix, '^_+|_+$', '');
            if isempty(prefix)
                prefix = 'cellpose_volume';
            end
        end

        function params = buildParams(response, num_supervoxels)
            %BUILDPARAMS Normalize Cellpose response metadata into detector params.
            params = struct();
            params.k = num_supervoxels;
            params.detect_scale = 0;
            params.hnsz = [10, 10, 3];
            params.min_eig_thresh = 0;
            params.exclusion_radius = 0;
            params.backend = 'cellpose';

            if isfield(response, 'mode')
                params.mode = response.mode;
            end
            if isfield(response, 'coordinate_convention')
                params.coordinate_convention = response.coordinate_convention;
            end
            if isfield(response, 'mask_source_used')
                params.mask_source = response.mask_source_used;
            end
            if isfield(response, 'model_path')
                params.model_path = response.model_path;
            end
            if isfield(response, 'selected_mask_shape')
                params.selected_mask_shape = response.selected_mask_shape;
            end
            if isfield(response, 'mask_ids')
                params.mask_ids = response.mask_ids;
            end
            if isfield(response, 'voxel_counts')
                params.voxel_counts = response.voxel_counts;
            end
            if isfield(response, 'masks_mat_path')
                params.masks_mat_path = response.masks_mat_path;
            end
        end
    end
end
