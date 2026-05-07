classdef h5
    methods (Static)
        function [positions, labels] = load_tracks(filepath)
            [path, ~, ~] = fileparts(filepath);

            frame_results = h5read(filepath, '/t_idx');
            wlid_results = h5read(filepath, '/worldline_id');
            x_results = h5read(filepath, '/x');
            y_results = h5read(filepath, '/y');
            z_results = h5read(filepath, '/z');
    
            worldlines_file = fullfile(path, 'worldlines.h5');
            if isfile(worldlines_file)
                wl_idx = h5read(worldlines_file, '/id');
                wl_name = h5read(worldlines_file, '/name');
            else
                error('NeuroPAL_ID:MissingWorldlines', ...
                    ['Unable to import annotations because worldlines.h5 is ' ...
                    'missing. It must be in the same folder as the annotations file.']);
            end

            positions = [cast(frame_results+1, 'like', x_results), x_results, y_results, z_results];

            labels = cell(size(wlid_results));
            [~, idx] = ismember(wlid_results, wl_idx);
            for i = 1:length(wlid_results)
                if idx(i) > 0
                    labels{i} = DataHandling.Helpers.h5.string_value(wl_name, idx(i));
                else
                    labels{i} = 'Unknown';
                end
            end

            labels = labels';
        end

        function [annotations_file, worldlines_file] = write_tracks(video_info, video_neurons, annotations_file)
            if nargin < 3 || isempty(annotations_file)
                [path, ~, ~] = fileparts(video_info.file);
                annotations_file = fullfile(path, 'annotations.h5');
            end

            [path, ~, ~] = fileparts(annotations_file);
            if isempty(path)
                path = pwd;
                annotations_file = fullfile(path, annotations_file);
            end
            if ~isfolder(path)
                mkdir(path);
            end
            worldlines_file = fullfile(path, 'worldlines.h5');

            n_worldlines = numel(video_neurons);
            t_idx = uint32([]);
            x = single([]);
            y = single([]);
            z = single([]);
            worldline_id = uint32([]);
            parent_id = uint32([]);
            provenance = strings(0, 1);
            names = strings(n_worldlines, 1);
            colors = strings(n_worldlines, 1);

            for n = 1:n_worldlines
                names(n) = string(DataHandling.Helpers.h5.worldline_name(video_neurons(n), n));
                colors(n) = string(DataHandling.Helpers.h5.worldline_color(video_neurons(n)));

                if ~isfield(video_neurons(n), 'rois') || isempty(video_neurons(n).rois)
                    continue
                end

                for t = 1:min(numel(video_neurons(n).rois), video_info.nt)
                    roi = video_neurons(n).rois(t);
                    if ~DataHandling.Helpers.h5.has_roi_position(roi)
                        continue
                    end

                    t_idx(end+1, 1) = uint32(t - 1); %#ok<AGROW>
                    x(end+1, 1) = DataHandling.Helpers.h5.normalize_coordinate(roi.x_slice, video_info.nx); %#ok<AGROW>
                    y(end+1, 1) = DataHandling.Helpers.h5.normalize_coordinate(roi.y_slice, video_info.ny); %#ok<AGROW>
                    z(end+1, 1) = DataHandling.Helpers.h5.normalize_coordinate(roi.z_slice, video_info.nz); %#ok<AGROW>
                    worldline_id(end+1, 1) = uint32(n - 1); %#ok<AGROW>
                    parent_id(end+1, 1) = uint32(0); %#ok<AGROW>
                    provenance(end+1, 1) = string(DataHandling.Helpers.h5.provenance_name(video_neurons(n))); %#ok<AGROW>
                end
            end

            if isempty(t_idx)
                error('NeuroPAL_ID:NoVideoAnnotations', ...
                    'No video annotations are available to export.');
            end

            if isfile(annotations_file)
                delete(annotations_file);
            end
            if isfile(worldlines_file)
                delete(worldlines_file);
            end

            DataHandling.Helpers.h5.write_vector(annotations_file, '/id', uint32((1:numel(t_idx))'));
            DataHandling.Helpers.h5.write_vector(annotations_file, '/t_idx', t_idx);
            DataHandling.Helpers.h5.write_vector(annotations_file, '/x', x);
            DataHandling.Helpers.h5.write_vector(annotations_file, '/y', y);
            DataHandling.Helpers.h5.write_vector(annotations_file, '/z', z);
            DataHandling.Helpers.h5.write_vector(annotations_file, '/worldline_id', worldline_id);
            DataHandling.Helpers.h5.write_vector(annotations_file, '/parent_id', parent_id);
            DataHandling.Helpers.h5.write_string_vector(annotations_file, '/provenance', provenance);

            DataHandling.Helpers.h5.write_vector(worldlines_file, '/id', uint32((0:n_worldlines-1)'));
            DataHandling.Helpers.h5.write_string_vector(worldlines_file, '/name', names);
            DataHandling.Helpers.h5.write_string_vector(worldlines_file, '/color', colors);
        end

        function idx = denormalize_coordinate(coord, dim)
            idx = round(double(coord) * double(dim));
            idx = min(max(idx, 1), dim);
        end

        function color = color_value(values, idx)
            color = [0.8, 0.8, 0.8];
            if isnumeric(values)
                if isvector(values) && numel(values) >= 3
                    color = double(values(1:3));
                elseif ismatrix(values) && size(values, 2) >= idx && size(values, 1) >= 3
                    color = double(values(1:3, idx))';
                elseif ismatrix(values) && size(values, 1) >= idx && size(values, 2) >= 3
                    color = double(values(idx, 1:3));
                end
                color = min(max(color, 0), 1);
                return
            end

            value = char(string(DataHandling.Helpers.h5.string_value(values, idx)));
            if startsWith(value, '#') && strlength(string(value)) >= 7
                rgb = sscanf(value(2:7), '%2x%2x%2x');
                if numel(rgb) == 3
                    color = double(rgb(:))' ./ 255;
                end
            end
        end
    end

    methods (Static, Access = private)
        function write_vector(file, dataset, values)
            values = values(:);
            h5create(file, dataset, numel(values), 'Datatype', class(values));
            h5write(file, dataset, values);
        end

        function write_string_vector(file, dataset, values)
            values = string(values(:));
            h5create(file, dataset, numel(values), 'Datatype', 'string');
            h5write(file, dataset, values);
        end

        function value = normalize_coordinate(idx, dim)
            value = single((double(idx) - 0.5) / double(dim));
            value = single(min(max(value, eps('single')), 1 - eps('single')));
        end

        function tf = has_roi_position(roi)
            fields = {'x_slice', 'y_slice', 'z_slice'};
            tf = true;
            for i = 1:numel(fields)
                field = fields{i};
                tf = tf && isfield(roi, field) && ~isempty(roi.(field)) && ...
                    isnumeric(roi.(field)) && isscalar(roi.(field)) && isfinite(roi.(field));
            end
        end

        function name = worldline_name(video_neuron, idx)
            name = sprintf('Worldline %.f', idx);
            if isfield(video_neuron, 'worldline') && isfield(video_neuron.worldline, 'name') && ...
                    ~isempty(video_neuron.worldline.name)
                name = char(string(video_neuron.worldline.name));
            end
        end

        function color = worldline_color(video_neuron)
            color = '#cccccc';
            if isfield(video_neuron, 'worldline') && isfield(video_neuron.worldline, 'color') && ...
                    isnumeric(video_neuron.worldline.color) && numel(video_neuron.worldline.color) >= 3
                rgb = min(max(video_neuron.worldline.color(1:3), 0), 1);
                color = sprintf('#%02x%02x%02x', round(rgb(1) * 255), ...
                    round(rgb(2) * 255), round(rgb(3) * 255));
            end
        end

        function provenance = provenance_name(video_neuron)
            provenance = 'NPAL';
            if isfield(video_neuron, 'provenance') && ~isempty(video_neuron.provenance)
                provenance = char(extractBefore(string(video_neuron.provenance) + "    ", 5));
            end
        end

        function value = string_value(values, idx)
            if iscell(values)
                value = values{idx};
            else
                value = values(idx);
            end
            value = char(string(value));
        end
    end
end
