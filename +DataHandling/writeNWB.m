classdef writeNWB
    % Functions responsible for handling our dynamic GUI solutions.

    properties(Constant, Access=public)
    end

    methods (Static)

        function code = write_order(app, path, progress)
            % Full-shot NWB save routine

            if ~exist('progress', 'var')
                progress = struct();
            end

            % Grab NWB-compatible metadata from nwbsave.mlapp
            progress.Message = 'Parsing metadata...';
            [ctx, device_table, optical_table] = Program.GUIHandling.read_gui(app);

            % Grab data flags from visualize_light.mlapp so we know which
            % parts of the save routine to skip.
            progress.Message = 'Checking flags...';
            ctx.flags = Program.GUIHandling.global_grab('NeuroPAL ID', 'data_flags');

            % Grab NWB-compatible data from visualize_light.mlapp
            progress.Message = 'Loading volume data...';
            
            % Check what data is actually available
            colormap_data = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_data');
            video_info = Program.GUIHandling.global_grab('NeuroPAL ID', 'video_info');
            
            % Determine what data types we have
            has_colormap = ~isempty(colormap_data);
            has_video = ~isempty(video_info);
            
            if ~has_colormap && ~has_video
                error('No image or video data available');
            end
            
            % Validate required context fields
            required_ctx_fields = {'worm', 'author'};
            for field = required_ctx_fields
                if ~isfield(ctx, field{1})
                    error('Missing required context field: %s', field{1});
                end
            end
            
            % Only populate data structures for available data types
            if has_colormap
                ctx.colormap.data = colormap_data;
                ctx.neurons.colormap = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_neurons');
                
                % Validate colormap data structure
                if ~isnumeric(colormap_data) || ndims(colormap_data) < 3
                    error('Invalid colormap data format');
                end
            end
            
            if has_video
                ctx.video.info = video_info;
                ctx.neurons.video = Methods.ChunkyMethods.stream_neurons('annotations');
                ctx.neurons.activity_data = Program.GUIHandling.global_grab('NeuroPAL ID', 'activity_table');
                
                % Validate video info structure
                if ~isstruct(video_info)
                    error('Video info must be a structure');
                end
            end

            % Build nwb file.
            progress.Message = 'Initializing file...';
            ctx.build = struct();
            ctx.build.file = DataHandling.writeNWB.create_file(ctx);
            ctx.build.modules = struct();
            
            % Initialize variable to store devices objects.
            devices = [];

            progress.Message = 'Parsing hardware data...';
            % Iterate over hardware devices
            for eachDevice=1:size(device_table, 1)
                
                % Get relevant name, description, & manufacturer, ensuring they are char arrays
                name = char(device_table{eachDevice, 1});
                desc = char(device_table{eachDevice, 2});
                manu = char(device_table{eachDevice, 3});

                % Create device object & add to device array.
                new_device = DataHandling.writeNWB.create_device(name, desc, manu);
                ctx.build.file.general_devices.set(name, new_device);

                % If current device was selected as colormap microscope,
                % save the object for later (only if we have colormap data).
                if has_colormap && strcmp(strtrim(char(name)), strtrim(char(ctx.colormap.device)))
                    ctx.colormap.device = new_device;
                end

                if has_video && strcmp(strtrim(char(name)), strtrim(char(ctx.video.device)))
                    ctx.video.device = new_device;
                end
            end

            % Create optical channel objects.
            progress.Message = 'Parsing channel data...';
            ctx.optical_metadata = DataHandling.writeNWB.create_channels(optical_table);
            
            % Initialize struct to store NWB modules.
            progress.Message = 'Building modules...';

            % Create processing module & assign all objects containing work product.
            ctx.build.processing_modules = struct( ...
                'CalciumActivity', types.core.ProcessingModule('description', 'Calcium time series metadata, segmentation, and fluorescence data.'), ...
                'ProgramSettings', types.core.ProcessingModule('description', 'Various NeuroPAL_ID settings which specify how the colormap is processed once loaded into the program.'));

            % Create required volume objects only if we have the corresponding data.
            if has_colormap && ctx.flags.NeuroPAL_Volume
                progress.Message = 'Populating NeuroPAL volume...';
                ctx.colormap.imaging_volume = DataHandling.writeNWB.create_volume('colormap', 'imaging', ctx);
                
                % Initialize acquisition module if it doesn't exist
                if ~isfield(ctx.build.modules, 'acquisition')
                    ctx.build.modules.acquisition = struct();
                end
                ctx.build.modules.acquisition.NeuroPALImVol = ctx.colormap.imaging_volume;

                ctx.colormap.multichannel_volume = DataHandling.writeNWB.create_volume('colormap', 'multichannel', ctx);
                ctx.build.modules.acquisition.NeuroPALImageRaw = ctx.colormap.multichannel_volume;
                
                progress.Message = 'Populating NeuroPAL settings...';
                gammas = types.hdmf_common.VectorData( ...
                    'description', 'channel gamma values', ...
                    'data', ctx.colormap.prefs.gamma);

                ctx.colormap.settings = types.hdmf_common.DynamicTable( ...
                    'description', 'NeuroPAL_ID Settings', ...
                    'colnames', {'gammas'}, ...
                    'gammas', gammas, ...
                    'id', types.hdmf_common.ElementIdentifiers('data', 0:length(gammas)-1));

                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.NeuroPAL_IDSettings = ctx.colormap.settings;
            end

            if has_colormap && (ctx.flags.Neurons || ctx.flags.Neuronal_Identities)
                progress.Message = 'Populating neuronal identities...';
                ctx.neurons.colormap = DataHandling.writeNWB.create_segmentation('colormap', ctx);
                
                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.ColormapNeurons =  ctx.neurons.colormap;
            end

            if has_video && ctx.flags.Video_Volume
                progress.Message = 'Populating video volume...';
                ctx.video.imaging_volume = DataHandling.writeNWB.create_volume('video', 'imaging', ctx);
                
                % Initialize acquisition module if it doesn't exist
                if ~isfield(ctx.build.modules, 'acquisition')
                    ctx.build.modules.acquisition = struct();
                end
                ctx.build.modules.acquisition.CalciumImVol = ctx.video.imaging_volume;

                ctx.video.multichannel_volume = DataHandling.writeNWB.create_volume('video', 'multichannel', ctx);
                ctx.build.modules.acquisition.CalciumImageSeries = ctx.video.multichannel_volume;
            end

            if has_video && ctx.flags.Tracking_ROIs
                progress.Message = 'Populating tracking ROIs...';
                ctx.neurons.video = DataHandling.writeNWB.create_segmentation('video', ctx);
                
                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.TrackedNeuronROIs = ctx.neurons.video;
            end

            if has_video && ctx.flags.Neuronal_Activity
                progress.Message = 'Populating neuronal activity...';
                ctx.neurons.activity = DataHandling.writeNWB.create_traces(ctx);
                
                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.ActivityTraces = ctx.neurons.activity;
            end

            if ctx.flags.Stimulus_Files
                progress.Message = 'Populating stimuli...';
                switch class(ctx.neurons.stim_file)
                    case {'char', 'string'}
                        ctx.neurons.stim_table = DataHandling.readStimFile(ctx.neurons.stim_file);
                    case 'table'
                        ctx.neurons.stim_table = ctx.neurons.stim_file;
                end

                stim_series = types.core.AnnotationSeries( ...
                    'name', 'StimulusInfo', ...
                    'description', 'Denotes which stimulus was released on which frames.', ...
                    'timestamps', ctx.neurons.stim_table{:, 1}, ...
                    'data', ctx.neurons.stim_table{:, 2});

                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.StimulusInfo = stim_series;
            end

            % Check if NWB file to be saved already exists.
            progress.Message = 'Writing to file...';
            
            module_names = fieldnames(ctx.build.modules);
            processing_names = fieldnames(ctx.build.processing_modules);
            for mod=1:length(module_names)
                parent = module_names{mod};
                obj_struct = ctx.build.modules.(parent);
                obj_names = fieldnames(obj_struct);

                for obj=1:length(obj_names)
                    obj_name = obj_names{obj};
                    obj_data = obj_struct.(obj_name);

                    switch class(obj_data)
                        case {'types.ndx_multichannel_volume.MultiChannelVolume', 'types.ndx_multichannel_volume.MultiChannelVolumeSeries'}
                            ctx.build.file.(parent).set(obj_name, obj_data);

                        case 'types.ndx_multichannel_volume.ImagingVolume'
                            ctx.build.file.general_optophysiology.set(obj_name, obj_data);

                        case {'types.hdmf_common.DynamicTable', 'types.core.PlaneSegmentation', 'types.ndx_multichannel_volume.VolumeSegmentation'}
                            if any(ismember('gammas', obj_data.colnames))
                                ctx.build.processing_modules.('ProgramSettings').dynamictable.set(obj_name, obj_data);
                            else
                                ctx.build.processing_modules.('CalciumActivity').dynamictable.set(obj_name, obj_data);
                            end

                        case {'types.core.NWBDataInterface', 'types.core.TimeSeries', 'types.core.RoiResponseSeries'}
                            ctx.build.processing_modules.('CalciumActivity').nwbdatainterface.set(obj_name, obj_data);

                        otherwise
                            class(obj_data)
                    end
                end
            end

            for proc=1:length(processing_names)
                name = processing_names{proc};
                module = ctx.build.processing_modules.(name);
                ctx.build.file.processing.set(name, module);
            end

            % Fix imaging plane device references before export
            try
                ctx.build.file = DataHandling.writeNWB.fix_imaging_plane_export(ctx.build.file);
            catch ME
                warning('Could not fix imaging plane references: %s', ME.message);
            end

            % Export NWB file with error handling
            try
                if ~exist(path, "file")
                    % Save new file
                    progress.Message = 'Exporting NWB file...';
                    nwbExport(ctx.build.file, path);
                    fprintf('Successfully saved NWB file: %s\n', path);
                    
                    % Create companion ID file
                    DataHandling.writeNWB.create_companion_id_file(path, progress);
                else
                    % Merge with existing file
                    progress.Message = 'Merging with existing NWB file...';
                    warning('File %s already exists. Creating merged file with "-new" suffix.', path);
                    
                    existing_nwb = nwbRead(path);
                    
                    % Merge data structures safely
                    if ~isempty(ctx.build.file.acquisition)
                        existing_nwb.acquisition = types.untyped.Set(existing_nwb.acquisition, ctx.build.file.acquisition);
                    end
                    if ~isempty(ctx.build.file.processing)
                        existing_nwb.processing = types.untyped.Set(existing_nwb.processing, ctx.build.file.processing);
                    end
                    if ~isempty(ctx.build.file.general_subject)
                        existing_nwb.general_subject = ctx.build.file.general_subject;
                    end
                    
                    new_path = strrep(path, '.nwb', '-new.nwb');
                    nwbExport(existing_nwb, new_path);
                    fprintf('Successfully saved merged NWB file: %s\n', new_path);
                    
                    % Create companion ID file for merged file
                    DataHandling.writeNWB.create_companion_id_file(new_path, progress);
                end
            catch ME
                error('Failed to export NWB file: %s\nStack trace:\n%s', ME.message, getReport(ME));
            end

            % Return code 0 to indicate that there were no issues.
            code = 0;
        end

        function nwb_file = create_file(ctx)
            session_date = datetime(posixtime(ctx.worm.session_date),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');

            nwb_file = NwbFile( ...
                'session_description', ctx.author.data_description, ...
                'identifier', ctx.worm.identifier, ...
                'session_start_time', session_date, ...
                'general_lab', ctx.author.credit, ...
                'general_institution', ctx.author.institution, ...
                'general_related_publications', ctx.author.related_publication);

            % Populate subject data
            nwb_file.general_subject = types.ndx_multichannel_volume.CElegansSubject(...
                'subject_id', ctx.worm.identifier, ...
                'age', ctx.worm.age, ...
                'date_of_birth', session_date, ...
                'growth_stage', ctx.worm.age, ...
                'cultivation_temp', ctx.worm.cultivation_temp, ...
                'description', ctx.worm.notes, ...
                'species', 'http://purl.obolibrary.org/obo/NCBITaxon_6239', ...
                'sex', ctx.worm.sex, ...
                'strain', ctx.worm.strain);
        end

        function device = create_device(name, description, manufacturer)
            device = types.core.Device(...
                'name', name, ...
                'description', description, ...
                'manufacturer', manufacturer ...
                );
        end

        function nwb_module = create_module(module, ctx)
            switch module
                case 'acquisition'
                    nwb_module = types.core.AcquisitionModule( ...
                        'name', 'NeuroPAL', ...
                        'description', ctx.colormap.notes);
                case 'processing'
                    nwb_module = types.core.ProcessingModule( ...
                        'name', 'NeuroPAL', ...
                        'description', ctx.colormap.notes);
            end
        end

        function optical_metadata = create_channels(optical_table)
            % Populate channel data
            OptChannels = [];
            OptChanRefData = [];
            
            % Populate device data
            for eachChannel = 1:size(optical_table, 1)
                name = optical_table(eachChannel, 1);
                desc = optical_table(eachChannel, 2);

                ex_lambda = optical_table(eachChannel, 3);
                ex_low = optical_table(eachChannel, 4);
                ex_high = optical_table(eachChannel, 5);
                
                % Use str2double instead of deprecated str2num
                try
                    ex_range = [str2double(ex_low{1}), str2double(ex_high{1})];
                catch
                    warning('Could not parse excitation range for channel %d, using defaults', eachChannel);
                    ex_range = [400, 500]; % Default range
                end

                em_lambda = optical_table(eachChannel, 6);
                em_low = optical_table(eachChannel, 7);
                em_high = optical_table(eachChannel, 8);
                
                try
                    em_range = [str2double(em_low{1}), str2double(em_high{1})];
                catch
                    warning('Could not parse emission range for channel %d, using defaults', eachChannel);
                    em_range = [500, 600]; % Default range
                end
            
                OptChan = types.ndx_multichannel_volume.OpticalChannelPlus( ...
                    'name', name, ...
                    'description', desc, ...
                    'excitation_lambda', ex_lambda, ...
                    'excitation_range', ex_range, ...
                    'emission_lambda', em_lambda, ...
                    'emission_range', em_range ...
                    );
                
                OptChannels = [OptChannels, OptChan];
                
                % Create reference string with proper error handling
                try
                    bandwidth = str2double(em_high{1}) - str2double(em_low{1});
                    new_line = sprintf('%s-%s-%dnm', ex_lambda{1}, em_lambda{1}, round(bandwidth));
                catch
                    new_line = sprintf('%s-%s-default', ex_lambda{1}, em_lambda{1});
                end
                OptChanRefData = [OptChanRefData, new_line];
            end           
            
            orderOpticalChannels = types.ndx_multichannel_volume.OpticalChannelReferences( ...
                'channels', OptChanRefData);

            optical_metadata = struct( ...
                'channels', OptChannels, ...
                'reference_data', OptChanRefData, ...
                'order', orderOpticalChannels);
        end

        function nwb_volume = create_volume(preset, module, ctx)
            switch module
                case 'imaging'
                    nwb_volume = types.ndx_multichannel_volume.ImagingVolume( ...
                        'opticalchannelplus', ctx.optical_metadata.channels, ...
                        'order_optical_channels', ctx.optical_metadata.order, ...
                        'description', ctx.(preset).description, ...
                        'device', ctx.(preset).device, ...
                        'location', ctx.worm.body_part, ...
                        'grid_spacing', ctx.(preset).grid_spacing.values, ...
                        'grid_spacing_unit', ctx.(preset).grid_spacing.unit, ...
                        'origin_coords', [0, 0, 0], ...
                        'origin_coords_unit', ctx.(preset).grid_spacing.unit, ...
                        'reference_frame', ['Worm ', ctx.worm.body_part]);
                case 'multichannel'
                    if strcmp(preset, 'colormap')
                        original_data = ctx.(preset).data;
                        if isa(original_data, 'double')
                            % Get data range and determine appropriate scaling
                            data_min = min(original_data(:));
                            data_max = max(original_data(:));
                            
                            % Use more conservative scaling to preserve precision
                            % Scale to uint16 range unless data requires larger range
                            if data_max > data_min
                                data_range = data_max - data_min;
                                if data_range <= 1.0
                                    % Normalized data (0-1), scale to uint16
                                    scaled_data = (original_data - data_min) / data_range * 65535;
                                    converted_data = uint16(round(scaled_data));
                                else
                                    % Larger range, use uint32 for better precision
                                    scaled_data = (original_data - data_min) / data_range * 4294967295;
                                    converted_data = uint32(round(scaled_data));
                                end
                            else
                                % Constant data
                                converted_data = uint16(zeros(size(original_data)));
                            end
                        else
                            % Already integer type, convert to uint64 for consistency
                            converted_data = uint64(original_data);
                        end
                        
                        nwb_volume = types.ndx_multichannel_volume.MultiChannelVolume( ...
                            'description', ctx.(preset).description, ...
                            'RGBW_channels', ctx.(preset).prefs.RGBW, ...
                            'data', converted_data, ...
                            'imaging_volume', types.untyped.SoftLink('/general/optophysiology/NeuroPALImVol'));
                    elseif strcmp(preset, 'video')
                        rf_app = Program.GUIHandling.get_parent_app(Program.GUIHandling.global_grab('NeuroPAL ID', 'CELL_ID'));
                        
                        % Validate video info fields
                        required_fields = {'ny', 'nx', 'nz', 'nc', 'nt'};
                        for field = required_fields
                            if ~isfield(ctx.(preset).info, field{1}) || isempty(ctx.(preset).info.(field{1}))
                                error('Missing required video info field: %s', field{1});
                            end
                        end
                        
                        % Create preview with first 2 frames for validation
                        try
                            video_preview = zeros([ctx.(preset).info.ny ctx.(preset).info.nx ctx.(preset).info.nz ctx.(preset).info.nc 2]);
                            video_preview(:, :, :, :, 1) = rf_app.retrieve_frame(1);
                            video_preview(:, :, :, :, 2) = rf_app.retrieve_frame(2);
                        catch ME
                            warning('Could not retrieve video frames: %s', ME.message);
                            video_preview = zeros([ctx.(preset).info.ny ctx.(preset).info.nx ctx.(preset).info.nz ctx.(preset).info.nc 2]);
                        end

                        % TODO: Fix DataPipe to reference actual video source instead of preview
                        % This currently only saves 2 frames - needs proper video streaming implementation
                        data_pipe = types.untyped.DataPipe( ...
                            'data', uint64(video_preview), ...
                            'maxSize', [ctx.(preset).info.ny ctx.(preset).info.nx ctx.(preset).info.nz ctx.(preset).info.nc ctx.(preset).info.nt], ...
                            'axis', 5);

                        if ~isfield(ctx.(preset), 'scan_rate')
                            ctx.(preset).scan_line_rate = 1;
                            ctx.(preset).scan_rate = 1;
                        end

                        nwb_volume = types.ndx_multichannel_volume.MultiChannelVolumeSeries( ...
                            'description', ctx.(preset).description, ...
                            'data', data_pipe, ...
                            'device', ctx.(preset).device, ...
                            'imaging_volume', types.untyped.SoftLink('/general/optophysiology/CalciumImVol'));
                    end
            end
        end

        function obj = create_segmentation(preset, ctx)
            switch preset
                case 'colormap'        
                    positions = ctx.neurons.(preset).get_positions;
                    
                    % Create proper SoftLink references
                    imaging_volume_link = types.untyped.SoftLink('/general/optophysiology/NeuroPALImVol');
                    
                    obj = types.ndx_multichannel_volume.VolumeSegmentation( ...
                        'colnames', {'voxel_mask'}, ...
                        'description', ctx.neurons.id_description, ...
                        'voxel_mask', types.hdmf_common.VectorData('description', 'Neuron ROIs', 'data', positions'), ...
                        'id', types.hdmf_common.ElementIdentifiers('data', 0:length(positions')-1), ...
                        'imaging_volume', imaging_volume_link, ...
                        'imaging_plane', imaging_volume_link);

                    labels = {};
                    for n=1:length(ctx.neurons.(preset).neurons)
                        labels{end+1} = ctx.neurons.(preset).neurons(n).annotation;
                    end

                    obj.addColumn('neuron_ids', types.hdmf_common.VectorData('description', 'Neuron IDs', 'data', labels'));

                case 'video'
                    positions = ctx.neurons.(preset).positions;
                    
                    % Create proper SoftLink reference for video
                    video_imaging_volume_link = types.untyped.SoftLink('/general/optophysiology/CalciumImVol');
                    
                    obj = types.core.PlaneSegmentation( ...
                        'name', 'TrackedNeurons', ...
                        'colnames', {'voxel_mask', 'labels'}, ...
                        'description', ctx.video.tracking_notes, ...
                        'voxel_mask', types.hdmf_common.VectorData('description', 'Neuron ROIs', 'data', positions'), ...
                        'labels', types.hdmf_common.VectorData('description', 'Neuron IDs', 'data', ctx.neurons.(preset).labels), ...
                        'id', types.hdmf_common.ElementIdentifiers('data', 0:length(positions')-1), ...
                        'imaging_plane', video_imaging_volume_link);
            end
        end

        function obj = create_traces(ctx)
            % Validate activity data exists
            if isempty(ctx.neurons.activity_data)
                error('No activity data available for trace creation');
            end
            
            % Validate video segmentation exists
            if isempty(ctx.neurons.video)
                error('No video segmentation available for trace creation');
            end
            
            % Create table region with proper indexing
            num_rois = length(ctx.neurons.video);
            roi_indices = 0:(num_rois-1);  % 0-based indexing for NWB
            
            roi_table_region = types.hdmf_common.DynamicTableRegion( ...
                'table', types.untyped.ObjectView(ctx.neurons.video), ...
                'description', ctx.video.tracking_notes, ...
                'data', roi_indices);

            % Convert activity data and validate dimensions
            activity_array = table2array(ctx.neurons.activity_data);
            if size(activity_array, 2) ~= num_rois
                warning('Activity data dimensions do not match number of ROIs. Adjusting...');
                % Take minimum to avoid index errors
                min_size = min(size(activity_array, 2), num_rois);
                activity_array = activity_array(:, 1:min_size);
                roi_indices = roi_indices(1:min_size);
                roi_table_region.data = roi_indices;
            end

            obj = types.core.RoiResponseSeries( ...
                'name', 'SignalCalciumImResponseSeries', ...
                'rois', roi_table_region, ...
                'data', activity_array, ...
                'data_unit', 'lumens', ...
                'starting_time_rate', 1.0, ...
                'starting_time', 0.0);
        end

        function nwb_obj = fix_imaging_plane_export(nwb_obj)
            % Fix imaging plane device references before export
            
            try
                % Ensure general optophysiology structure exists
                if ~isprop(nwb_obj, 'general_optophysiology') || isempty(nwb_obj.general_optophysiology)
                    return;
                end
                
                imaging_planes = nwb_obj.general_optophysiology;
                
                % Ensure devices exist
                if ~isprop(nwb_obj, 'general_devices') || isempty(nwb_obj.general_devices)
                    % Create a default device if none exists
                    device = types.core.Device('description', 'Default imaging device');
                    nwb_obj.general_devices = types.untyped.Set();
                    nwb_obj.general_devices.set('default_device', device);
                    default_device_ref = types.untyped.SoftLink('/general/devices/default_device');
                else
                    devices = nwb_obj.general_devices;
                    device_keys = keys(devices);
                    if ~isempty(device_keys)
                        % Use reference to existing device
                        default_device_ref = types.untyped.SoftLink(['/general/devices/' device_keys{1}]);
                    else
                        % Create a default device
                        device = types.core.Device('description', 'Default imaging device');
                        devices.set('default_device', device);
                        default_device_ref = types.untyped.SoftLink('/general/devices/default_device');
                    end
                end
                
                % Fix each imaging plane's device reference
                if isa(imaging_planes, 'types.untyped.Set')
                    plane_keys = keys(imaging_planes);
                    for i = 1:length(plane_keys)
                        plane = imaging_planes.get(plane_keys{i});
                        if isempty(plane.device) || ~isa(plane.device, 'types.untyped.SoftLink')
                            fprintf('Fixing device reference for imaging plane: %s\n', plane_keys{i});
                            plane.device = default_device_ref;
                        end
                    end
                end
                
            catch ME
                warning('Could not fix imaging plane device references: %s', ME.message);
                fprintf('Stack trace:\n');
                for i = 1:length(ME.stack)
                    fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
                end
            end
        end

        function create_companion_id_file(nwb_path, progress)
            %CREATE_COMPANION_ID_FILE Create companion _ID.mat file for saved NWB file
            %
            % This function creates the companion _ID.mat file that contains
            % neuron annotations, detection parameters, and other analysis data
            % when saving an NWB file with a custom name.
            %
            % Input:
            %   nwb_path = path to the saved NWB file
            %   progress = progress dialog structure (optional)
            
            try
                if exist('progress', 'var') && ~isempty(progress)
                    progress.Message = 'Creating companion ID file...';
                end
                
                % Generate the companion ID file path
                id_file_path = strrep(nwb_path, '.nwb', '_ID.mat');
                
                % Get current app instance to access neuron data
                app = Program.app;
                
                % Check if we have neuron data to save
                if isempty(app.image_neurons) || isempty(app.image_neurons.neurons)
                    fprintf('No neuron data available to save in companion ID file.\n');
                    return;
                end
                
                % Prepare data for saving
                version = Program.ProgramInfo.version;
                neurons = app.image_neurons;
                
                % Get mp_params (matching pursuit parameters)
                if isfield(app, 'mp_params') && ~isempty(app.mp_params)
                    mp_params = app.mp_params;
                    % Update k parameter to reflect current neuron count
                    mp_params.k = length(neurons.neurons);
                else
                    % Create default mp_params if not available
                    mp_params = [];
                    mp_params.hnsz = [7, 7, 3]; % Default half neighborhood size
                    mp_params.k = length(neurons.neurons);
                    mp_params.exclusion_radius = 1.5;
                    mp_params.min_eig_thresh = 0.1;
                end
                
                % Save the companion ID file
                save(id_file_path, 'version', 'neurons', 'mp_params', '-v7.3');
                
                fprintf('Successfully created companion ID file: %s\n', id_file_path);
                
            catch ME
                warning('Failed to create companion ID file: %s', ME.message);
                fprintf('Stack trace:\n%s\n', getReport(ME));
            end
        end
    end
end