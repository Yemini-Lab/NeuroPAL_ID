classdef nd2
    % ND2 Class for handling and extracting metadata and images from ND2 files.
    
    properties (Access = public, Constant)
        key_map = dictionary( ...
            'xy_scale', {'dCalibration'}, ...
            'z_scale', {'dZStep'});

        channel_keys = {'ChannelName', 'ChannelOrder', 'ChannelCount', 'ChannelColor'}; % Keys used to identify channel metadata
        name_substr = 'Global Name #'; % Base substring used to identify channel names globally
    end
    
    methods (Static, Access = public)

        function ttl = get_ttl(file)
            ttl_keys = DataHandling.Helpers.nd2.get_ttl_keys(file);
        end

        function ttl = get_ttl_keys(file, target)
            if ~exist('target', 'var')
                ttl = struct();
                ttl.names = DataHandling.Helpers.nd2.get_ttl_keys(file, 'name');
                ttl.states = DataHandling.Helpers.nd2.get_ttl_keys(file, 'state');
                return
            end

            switch class(file)
                case 'loci.formats.ChannelSeparator'
                    reader = file;
                case {'string', 'char'}
                    reader = bfGetReader(file);
                otherwise
                    return
            end

            % Retrieve the global metadata
            meta = reader.getGlobalMetadata();
            
            if isempty(meta)
                error('No global metadata returned. Your ND2 may not contain global metadata or the Bio-Formats version is limited.');
            end
            
            % Get the set of keys from the metadata (Java Set object)
            switch target
                case 'name'
                    query = 'ttloutputshortname';
                case 'state'
                    query = 'ttloutputstate';
            end

            [keys, values, count] = DataHandling.Helpers.java.search_key(meta, query);
            ttl = struct( ...
                'keys', {keys}, ...
                'values', {values}, ...
                'count', {count});

            if ttl.count == 0
                warning('No TTL output channel names found.');
            end
        end

        function get_ttl_data(file)
            
            % 2. Determine number of frames in the series
            seriesIndex = 0;
            reader.setSeries(seriesIndex);
            numFrames = reader.getImageCount();  % total plane count (for a single Z stack, this equals number of T frames)
            
            % We can see how many series exist, but often ND2 has just one series
            seriesCount = reader.getSeriesCount();
            for s = 0:seriesCount-1
                fprintf('== Series %d ==\n', s);
                reader.setSeries(s);
                nPlanes = reader.getImageCount();  % planes = Z*C*T, not frames alone
                
                for p = 0:nPlanes-1
                    % Print the global metadata keys for debugging
                    fprintf('-- Plane index %d --\n', p);
                    
                    % Attempt to fetch any metadata
                    % (Bio-Formats often uses separate 'core' or 'plane' metadata structures)
                    planeMeta = reader.getPlaneMetadata(p);
                    
                    if ~isempty(planeMeta)
                        planeKeys = planeMeta.keySet().iterator();
                        while planeKeys.hasNext()
                            key = planeKeys.next();
                            val = planeMeta.get(key);
                            fprintf('%s = %s\n', char(key), char(val));
                        end
                    else
                        disp('No plane metadata found for this plane.');
                    end
                end
            end

        end

        function [obj, metadata] = open(file)
            % OPEN Open an ND2 file, returning a reader object or image data and metadata.
            %
            % Parameters:
            %   file - Path to the ND2 file.
            %
            % Returns:
            %   obj - Reader object or image data depending on lazy loading status.
            %   metadata - Struct containing metadata information for the file.

            f = bfGetReader(file); % Initialize Bio-Formats reader with the file path.

            % Collect metadata details about the ND2 file
            metadata = struct( ...
                'path', {file}, ...
                'bit_depth', {f.getMetadataStore.getPixelsSignificantBits(0).getValue()}, ...
                'scale', {[0 0 0]});

            metadata.dimensions = DataHandling.Helpers.nd2.get_dimensions(f);
            metadata.channels = DataHandling.Helpers.nd2.get_channels(f);

            % Load the file data or return a lazy reader object depending on the file handling mode
            if Program.states.instance().is_lazy
                obj = f; % Return lazy file reader if lazy loading is enabled.
            else
                obj = bfOpen(file); % Load full file data.
                obj = obj{1}; % Use the first item if the file contains a list.
            end

        end

        function np_file = to_npal(file)
            %CONVERTND2 Convert an ND2 file to NeuroPAL format.
            %
            % nd2_file = the ND2 file to convert
            % np_file = the NeuroPAL format file

            f = bfGetReader(file);                                              % Get reader object.

            nx = f.getSizeX;                                                    % Get width.
            ny = f.getSizeY;                                                    % Get height.
            nz = f.getSizeZ;                                                    % Get depth.
            nc = f.getSizeC;                                                    % Get channel count.
            nt = f.getSizeT;                                                    % Get frame count.

            bits = f.getMetadataStore.getPixelsSignificantBits(0).getValue();   % Get bit depth.
            bit_depth = sprintf("uint%.f", bits);                               % Convert bit depth to class string.

            data = [];                                                          % Initialize data as proportionate zero array.

            info = struct('file', {file});                                      % Initialize info struct.
            info.scale = DataHandling.Helpers.nd2.parse_scale(f);               % Set image scale

            info.channel_names = DataHandling.Helpers.nd2.get_channel_names(f);           % Get channel names.
            channels = Program.Handlers.channels.parse_info(info.channel_names);          % Get channel indices from names.
            
            [~, has_duplicate, duplicate_indices] = Program.Validation.check_for_duplicate_fluorophores(channels);
            if has_duplicate && ~isempty(duplicate_indices)
                Program.Handlers.channels.add_reference(info.channel_names{duplicate_indices})
            end

            info.RGBW = arrayfun(@(x) find(channels == x), 1:4, 'UniformOutput', false);                    % Set RGBW indices.
            if iscell(info.RGBW)
                info.RGBW = cell2mat(info.RGBW);
            end

            info.DIC = find(ismember(channels, 5));                             % Set DIC if present, else set to 0.
            if isempty(info.DIC)
                info.DIC = 0;
            end

            info.GFP = find(ismember(channels, 6));                             % Set GFP is present, else set to 0.
            if isempty(info.GFP)
                info.GFP = 0;
            end

            info.bit_depth = bit_depth;
            
            % Determine the gamma.
            info.gamma = Program.Handlers.channels.config{'default_gamma'};     % Set gamma to default since we can't get it from ND2 hashtable.
            
            % Initialize the user preferences.
            prefs.RGBW = info.RGBW;
            prefs.DIC = info.DIC;
            prefs.GFP = info.GFP;
            prefs.gamma = info.gamma;
            prefs.rotate.horizontal = false;
            prefs.rotate.vertical = false;
            prefs.z_center = ceil(nz / 2);
            prefs.is_Z_LR = true;
            prefs.is_Z_flip = true;
            
            % Initialize the worm info.
            worm.body = 'Head';
            worm.age = 'Adult';
            worm.sex = 'XX';
            worm.strain = '';
            worm.notes = '';
            
            % Save the ND2 file to our MAT file format.
            np_file = strrep(file, 'nd2', 'mat');
            version = Program.information.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');

            DataHandling.Helpers.nd2.write_data(np_file, f);
        end

        function dimension_struct = get_dimensions(file)
            dimension_struct = struct( ...
                'order', {char(file.getDimensionOrder)}, ...
                'nx', {file.getSizeX}, ...
                'ny', {file.getSizeY}, ...
                'nz', {file.getSizeZ}, ...
                'nc', {file.getSizeC}, ...
                'nt', {file.getSizeT});
        end

        function channel_struct = get_channels(reader)            
            channel_struct = struct( ...
                'names', {DataHandling.Helpers.nd2.get_channel_names(reader)}, ...
                'order', {Program.Handlers.channels.parse_order(names)}, ...
                'has_bools', {Program.Handlers.channels.parse_presence(names)});
        end

        function names = get_channel_names(reader)
            names = {};

            if isstring(reader) || ischar(reader)
                reader = bfGetReader(reader);
            end

            for c = 1:reader.getSizeC
                names{end+1} = string(reader.getMetadataStore.getChannelName(0, c - 1));
            end

            names = string(names);
        end


        function [f_nc, f_ch_names, f_ch_order] = channels_from_file(file)
            [~, ~, fmt] = fileparts(file);

            switch fmt
                case '.nd2'
                    f_data = bfopen(file);
                    f_metadata = f_data{cellfun(@(x)isa(x,'java.util.Hashtable'), f_data)};
                    f_metadata_keys = string(f_metadata.keySet.toArray);
                    f_ch_idx = contains(f_metadata_keys, 'Global Name #');
                    f_ch_str = string({f_metadata_keys{f_ch_idx}});
                    f_ch_order = string({f_ch_str{end:-1:1}});
                    f_ch_names = string(cellfun(@(x)f_metadata.get(x), f_ch_order, 'UniformOutput', false));
                    f_ch_names = f_ch_names(f_ch_names~="NA");
                    f_nc = length(f_ch_names);

                    fprintf("File %s contains %.f channels in this order:\n%s\n%s.", file, f_nc, join(f_ch_order, ', '), join(f_ch_names, ', '))

                case '.nwb'
                case '.mat'
            end
        end

        function [sorted_names, permute_record] = autosort(channels)
            Program.Handlers.dialogue.add_task('Interpreting channel names...');
            channels = string(channels(:));
            n_names = numel(channels);
        
            f_ch_names_lower = lower(channels);
        
            labels_order = keys(Program.channel_handler.fluorophore_mapping);
        
            labels = strings(n_names, 1);
        
            for j = 1:numel(labels_order)
                key = labels_order{j};
                synonyms = Program.channel_handler.fluorophore_mapping(key);
                synonyms_lower = lower(string(synonyms{1}));
        
                is_match = ismember(f_ch_names_lower, synonyms_lower);
                labels(is_match) = key;
            end
        
            sorted_names = strings(0, 1);
            permute_record = [];
        
            for j = 1:numel(labels_order)
                key = labels_order{j};

                idx = find(labels == key);

                sorted_names = [sorted_names; channels(idx)];
                permute_record = [permute_record; idx];
            end
        
            unmatched_idx = find(labels == "");
            if ~isempty(unmatched_idx)
                sorted_names = [sorted_names; channels(unmatched_idx)];
                permute_record = [permute_record; unmatched_idx];
            end

            Program.Handlers.dialogue.resolve();
        end

        function obj = get_plane(file, varargin)
            % GET_PLANE Extract a specific plane or slice from the ND2 file based on the given coordinates.
            %
            % Parameters:
            %   varargin - Input parser options for x, y, z, c, t dimensions.
            %
            % Returns:
            %   obj - Multidimensional array containing image planes.

            if ischar(file) || isstring(file)
                file = Program.GUIPreferences.instance().image_dir;
            end

            t = Program.GUIHandling.current_frame; % Retrieve the current time frame from GUI.

            % Set up input parser to handle variable input arguments
            p = inputParser;
            addOptional(p, 'x', 1:file.getSizeX);
            addOptional(p, 'y', 1:file.getSizeY);
            addOptional(p, 'z', 1:file.getSizeZ);
            addOptional(p, 'c', 1:file.getSizeC);
            addOptional(p, 't', t);
            parse(p, varargin{:});
        
            % Determine starting positions for extraction (zero-based)
            x0 = min(p.Results.x);
            y0 = min(p.Results.y);
        
            % Calculate the extraction dimensions
            width = max(p.Results.x);
            height = max(p.Results.y);
        
            % Set the number of planes in each dimension
            numZ = numel(p.Results.z);
            numC = numel(p.Results.c);
            numT = numel(p.Results.t);
        
            % Preallocate array to hold the extracted image planes
            obj = zeros(height, width, numZ, numC, numT, ...
                'like', file.getMetadataStore.getPixelsSignificantBits(0).getValue());
        
            % Loop through z, c, and t indices to retrieve planes
            for idxZ = 1:numZ
                for idxC = 1:numC
                    for idxT = 1:numT
                        % Retrieve coordinates in zero-based format
                        z = p.Results.z(idxZ);
                        c = p.Results.c(idxC);
                        t = max(p.Results.t(idxT), 1);
        
                        % Calculate the index for the specific plane in the reader object
                        planeIndex = file.getIndex(z - 1, c - 1, t - 1) + 1;
        
                        % Retrieve the plane data for the specified index
                        plane = bfGetPlane(file, planeIndex, x0, y0, width, height);
        
                        % Store the retrieved plane in the multidimensional array
                        obj(:, :, idxZ, idxC, idxT) = plane;
                    end
                end
            end
        end
    end

    methods (Static, Access = private)
        function [p, z, c, t] = parse_plane_idx(plane_idx)
            if ~isstring(plane_idx)
                plane_idx = string(plane_idx);
            end

            p = str2double(regexp(plane_idx, 'plane\s+(\d+)/\d+', 'tokens', 'once'));
            z = str2double(regexp(plane_idx, 'Z=(\d+)/\d+', 'tokens', 'once'));
            c = str2double(regexp(plane_idx, 'C=(\d+)/\d+', 'tokens', 'once'));
            t = str2double(regexp(plane_idx, 'T=(\d+)/\d+', 'tokens', 'once'));
        end

        function write_data(np_file, nd2_reader)
            Program.Handlers.dialogue.add_task('Writing data...');
            np_write = matfile(np_file, "Writable", true);
        
            nx = nd2_reader.getSizeX;
            ny = nd2_reader.getSizeY;
            nz = nd2_reader.getSizeZ;
            nc = nd2_reader.getSizeC;
            nt = nd2_reader.getSizeT;
        
            % Maximum memory to use for a single chunk:
            max_arr = memory().MaxPossibleArrayBytes * 0.90;
        
            % Determine the data class from config:
            dclass = Program.config.defaults{'class'};

            % Pre-allocate the entire output in the MAT-file:
            np_write.data = zeros(ny, nx, nz, nc, nt, dclass);
        
            switch dclass
                case 'single'
                    bytes_per_el = 4;
                case 'double'
                    bytes_per_el = 8;
                otherwise
                    bytes_per_el = str2double(dclass(5:end))/8;
            end

            ttl_bytes = ny * nx * nz * nc * nt * bytes_per_el;
            if ttl_bytes <= max_arr
                d_cell = bfopen(char(nd2_reader.getCurrentFile));
                d_cell = d_cell{1};
                n_planes = length(d_cell);
                data = zeros(ny, nx, nz, nc, nt, dclass);
                for pidx = 1:n_planes
                    [~, z, c, t] = DataHandling.Helpers.nd2.parse_plane_idx(d_cell{pidx, 2});
                    
                    %Program.Handlers.dialogue.add_task(sprintf( ...
                    %    'Plane %.f/%.f (z = %.f, c = %.f, t = %.f)...', ...
                    %    pidx, n_planes, z, c, t));
                    
                    Program.Handlers.dialogue.set_value(pidx/n_planes);
                    data(:, :, z, c, t) = d_cell{pidx, 1};
                    
                    %Program.Handlers.dialogue.resolve();
                end
                np_write.data = data;
            else
                if nt > 1
                    % --- For movies (nt > 1), chunk along the time dimension. ---
            
                    % Number of bytes in one full frame: (ny x nx x nz x nc)
                    bytes_per_frame = ttl_bytes / nt;
                    % Calculate how many frames to process at once:
                    chunk_size_t = max(1, floor(max_arr / bytes_per_frame));
            
                    t_start = 1;
                    while t_start <= nt
                        t_end = min(t_start + chunk_size_t - 1, nt);
                        Program.Handlers.dialogue.add_task(sprintf( ...
                            'Frames %.f-%.f (out of %.f)...', ...
                            t_start, t_end, nt));
            
                        % Read multiple frames in one go:
                        this_chunk = DataHandling.Helpers.nd2.get_plane( ...
                            nd2_reader, ...
                            'x', 1:nx, 'y', 1:ny, 'z', 1:nz, ...
                            'c', 1:nc, 't', t_start:t_end);
            
                        % Convert class and assign to MAT-file:
                        np_write.data(:,:,:,:, t_start:t_end) = ...
                            DataHandling.Types.to_standard(this_chunk);
            
                        % Update progress and move chunk window:
                        Program.Handlers.dialogue.set_value(t_end/nt);
                        t_start = t_end + 1;
                        Program.Handlers.dialogue.resolve();
                    end
            
                else
                    % --- Single time point: chunk along the z dimension. ---
            
                    % Number of bytes in one z-slab: (ny x nx x nc)
                    bytes_per_z_slab = ttl_bytes / nz;
                    % Calculate how many z-planes we can process at once:
                    chunk_size_z = max(1, floor(max_arr / bytes_per_z_slab));
            
                    z_start = 1;
                    while z_start <= nz
                        z_end = min(z_start + chunk_size_z - 1, nz);
                        Program.Handlers.dialogue.add_task(sprintf( ...
                            'Slices %.f-%.f (out of %.f)...', ...
                            z_start, z_end, nz));
            
                        % Read a chunk of z-slices:
                        this_chunk = DataHandling.Helpers.nd2.get_plane( ...
                            nd2_reader, ...
                            'x', 1:nx, 'y', 1:ny, 'z', z_start:z_end, ...
                            'c', 1:nc);
            
                        % Convert class and assign to MAT-file:
                        np_write.data(:,:, z_start:z_end, :) = ...
                            DataHandling.Types.to_standard(this_chunk);
            
                        % Update progress and move chunk window:
                        Program.Handlers.dialogue.set_value(z_end/nz);
                        z_start = z_end + 1;
                        Program.Handlers.dialogue.resolve();
                    end
                end
            end
        
            Program.Handlers.dialogue.resolve();
        end



        function scale = parse_scale(reader, pfx)
            key_map = DataHandling.Helpers.nd2.key_map;

            if ~exist('pfx', 'var')
                xy_scale = DataHandling.Helpers.nd2.get_keys(reader, key_map('xy_scale'), 'globals');
                z_scale = DataHandling.Helpers.nd2.get_keys(reader, key_map('z_scale'), 'globals');

                if isempty(xy_scale) || isempty(z_scale)
                    DataHandling.Helpers.nd2.parse_scale(reader, 'Global ');
                end

            else
                xy_scale = DataHandling.Helpers.nd2.get_keys(reader, sprintf("%s %s", pfx, key_map('xy_scale')), 'globals');
                z_scale = DataHandling.Helpers.nd2.get_keys(reader,  sprintf("%s %s", pfx, key_map('xy_scale')), 'globals');

            end

            if isempty(xy_scale) || isempty(z_scale)
                scale = [0 0 0];

            else
                scale = [ ...
                    str2num(xy_scale) ...
                    str2num(xy_scale) ...
                    str2num(z_scale)];
                
            end
        end

        function obj = get_keys(reader, query, scope)
            % GET_KEYS Retrieve specific keys from the file metadata.
            %
            % Parameters:
            %   file - File reader object.
            %   query - Query string for key matching.
            %   scope - Scope ('globals' or 'series') for metadata search.
            %
            % Returns:
            %   obj - Metadata values corresponding to the queried keys.
            Program.Handlers.dialogue.add_task('Retrieving keys from hashtable...');

            if iscell(query)
                query = query{1};
            end

            [globals, series] = DataHandling.Helpers.nd2.parse_keys(reader); % Parse metadata into globals and series.
            keys = struct('globals', {fieldnames(globals)}, 'series', {fieldnames(series)}); % Structure for keys.

            % Handle optional 'scope' argument
            if ~exist('scope', 'var')
                % Default case returns both global and series keys
                obj = struct( ...
                    'globals', {DataHandling.Helpers.nd2.get_keys(reader, query, 'globals')}, ...
                    'series', {DataHandling.Helpers.nd2.get_keys(reader, query, 'series')});
                return
            end

            % Retrieve and process keys within the specified scope
            target_keys = keys.(scope);
            idx = contains(target_keys, DataHandling.Helpers.java.to_valid(query)); % Match query to keys.
            str = string(target_keys(idx));
            order = string({str{end:-1:1}}); % Reverse order for certain operations.

            % Extract values based on scope and matched keys
            switch scope
                case 'globals'
                    values = string(cellfun(@(x)globals.(x), order, 'UniformOutput', false));
                case 'series'
                    values = string(cellfun(@(x)series.(x), order, 'UniformOutput', false));
            end

            % Filter out any "NA" values
            obj = values(values ~= "NA");

            Program.Handlers.dialogue.resolve();
        end

        function [globals, series] = parse_keys(reader)
            % PARSE_KEYS Parse global and series metadata tables if not already parsed.
            %
            % Parameters:
            %   file - File reader object containing metadata.
            %
            % Returns:
            %   globals - Parsed global metadata table.
            %   series - Parsed series metadata table.

            persistent g_table % Persistent global metadata table
            persistent s_table % Persistent series metadata table

            Program.Handlers.dialogue.add_task('Parsing hash keys...');

            % Parse global metadata only if not already done
            if isempty(g_table)
                g_table = DataHandling.Helpers.java.parse_hashtable(reader.getGlobalMetadata);
            end

            % Parse series metadata only if not already done
            if isempty(s_table)
                s_table = DataHandling.Helpers.java.parse_hashtable(reader.getSeriesMetadata);
            end

            globals = g_table;
            series = s_table;

            Program.Handlers.dialogue.resolve();
        end
    end
end
