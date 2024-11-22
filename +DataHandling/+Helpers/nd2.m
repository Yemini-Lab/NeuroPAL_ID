classdef nd2
    % ND2 Class for handling and extracting metadata and images from ND2 files.
    
    properties (Access = public, Constant)
        key_map = dictionary( ...
            'xy_scale', {'Global dCalibration'}, ...
            'z_scale', {'Global dZStep'});

        channel_keys = {'ChannelName', 'ChannelOrder', 'ChannelCount', 'ChannelColor'}; % Keys used to identify channel metadata
        name_substr = 'Global Name #'; % Base substring used to identify channel names globally
    end
    
    methods (Static, Access = public)

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

            data = zeros(nx, ny, nz, nc, nt, bit_depth);                        % Initialize data as proportionate zero array.

            info = struct('file', {file});                                      % Initialize info struct.
            info.scale = DataHandling.Helpers.nd2.parse_scale(file);            % Set image scale

            channels = DataHandling.Helpers.nd2.get_channel_names(file);        % Get channel names.
            channels = Program.Handlers.channels.parse_info(channels);          % Get channel indices from names.
            info.RGBW = channels(1:4);                                          % Set RGBW indices.
            info.DIC = channels(5);                                             % Set DIC if present, else set to 0.
            info.GFP = channels(6);                                             % Set GFP is present, else set to 0.
            
            % Determine the gamma.
            info.gamma = NeuroPALImage.gamma_default;                           % Set gamma to default since we can't get it from ND2 hashtable.
            
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
            np_file = strrep(nd2_file, 'nd2', 'mat');
            version = ProgramInfo.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');

            DataHandling.Helpers.nd2.write_data(np_file, file);
        end

        function [image, metadata] = legacy_read(file)
            %IMREADND2 Read in a Nikon ND2 image.
            %
            %   [IMAGE, METADATA] = IMREADCZI(FILENAME)
            %
            %   Input:
            %   filename - the filename of the ND2 image
            %
            %   Outputs:
            %   image - the image, a struct with fields:
            %       pixels     = the number of pixels as (x,y,z)
            %       scale      = the pixel scale, in meters, as (x,y,z)
            %       channels   = the names of the channels
            %       colors     = the color for each channel as (R,G,B)
            %       dicChannel = the DIC channel number
            %       lasers     = the laser wavelength for each channel
            %       emissions  = the emssion band for each channel as (min,max)
            %       data       = the image data as (x,y,z,channel)
            %   metadata - the meta data, a struct with fields:
            %       keys      = the meta data keys (the names for the meta data)
            %       values    = the meta data values (the values for the meta data)
            %       hashtable = a Java Hashtable of keys and their values
            
            % Open the ND2 file.
            data = bfopen(filename);
            
            % Extract the metadata.
            hashtable = data{1,2};
            keys = arrayfun(@char, hashtable.keySet.toArray, 'UniformOutput', false);
            values = cellfun(@(x) hashtable.get(x), keys, 'UniformOutput', false);
            
            % Organize the metadata.
            metadata.keys = keys;
            metadata.values = values;
            metadata.hashtable = hashtable;
            
            % Initialize the image volume information.
            xPixelsI = find(contains(keys, 'Global uiWidth') ...
                & ~contains(keys, 'Bytes'), 1);
            yPixelsI = find(contains(keys, 'Global uiHeight') ...
                & ~contains(keys, 'Bytes'), 1);
            numZSlicesI = find(contains(keys, 'Global uiCount'), 1);
            xyScaleI = find(contains(keys, 'Global dCalibration'), 1);
            zScaleI = find(contains(keys, 'Global dZStep'), 1);
            
            % Extract the image volume information.
            image.pixels = [ ...
                values{xPixelsI}; ...
                values{yPixelsI}; ...
                values{numZSlicesI}];
            image.scale = [ ...
                values{xyScaleI}; ...
                values{xyScaleI}; ...
                values{zScaleI}];
            
            % Initialize the channel information.
            numChannelsI = find(contains(keys, 'Global Number of Picture Planes'), 1);
            channelsI = find(contains(keys, 'Global Name #'));
            
            % Extract the channel information.
            numChannels = round(str2double(values{numChannelsI}));
            channelKeys = keys(channelsI);
            channelValues = values(channelsI);
            image.channels = cell(numChannels,1);
            for i = 1:numChannels
                
                % Get the channel name.
                channelI = find(endsWith(channelKeys, num2str(i + 1)), 1);
                image.channels{i} = channelValues{channelI};
            end
            
            % Default to BGRW.
            % Note: can't find color info in the metafile.
            red = [1,0,0];
            green = [0,1,0];
            blue = [0,0,1];
            white = [1,1,1];
            image.colors = nan(numChannels,3);
            image.colors(1,:) = blue;
            image.colors(2,:) = green;
            image.colors(3,:) = red;
            for i = 4:numChannels
                image.colors(i,:) = white;
            end
            image.dicChannel = nan;
            
            % Try using the channel names to determine their colors.
            for i = 1:length(image.channels)
                wavelength = sscanf(image.channels{i}, '%f');
                
                % DIC.
                if isempty(wavelength) || isnan(wavelength) || wavelength < 350
                    image.dicChannel = i;
                    image.colors(i,:) = white;
                elseif wavelength < 440
                    image.colors(i,:) = blue;
                elseif wavelength < 530
                    image.colors(i,:) = green;
                else
                    image.colors(i,:) = red;
                end
            end
            
            % Organize the image volume.
            imageData = data{1,1};
            image.data = uint16(nan([image.pixels; numChannels]'));
            for i=1:size(imageData,1)
                
                % Get the image plane data.
                dataStrs = split(imageData{i,2}, ';');
                zStr = strtrim(dataStrs{end-1});
                cStr = strtrim(dataStrs{end});
                
                % Assemble the image.
                z = sscanf(zStr,'Z=%f');
                c = sscanf(cStr,'C=%f');
                if isempty(z) || isnan(z)
                    z = 1;
                end
                if isempty(c) || isnan(c)
                    c = 1;
                end
                image.data(:,:,z,c) = imageData{i,1}';
            end
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

        function channel_struct = get_channels(file)            
            channel_struct = struct( ...
                'names', {DataHandling.Helpers.nd2.get_channel_names(file)}, ...
                'order', {Program.Handlers.channels.parse_order(names)}, ...
                'has_bools', {Program.Handlers.channels.parse_presence(names)});
        end

        function names = get_channel_names(file)
            names = {};

            for c = 1:file.getSizeC
                names{end+1} = string(file.getMetadataStore.getChannelName(0, c - 1));
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

        end

        function obj = get_plane(varargin)
            % GET_PLANE Extract a specific plane or slice from the ND2 file based on the given coordinates.
            %
            % Parameters:
            %   varargin - Input parser options for x, y, z, c, t dimensions.
            %
            % Returns:
            %   obj - Multidimensional array containing image planes.

            metadata = DataHandling.file.metadata; % Retrieve file metadata.
            t = Program.GUIHandling.current_frame; % Retrieve the current time frame from GUI.

            % Set up input parser to handle variable input arguments
            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', t);
            parse(p, varargin{:});
        
            file = DataHandling.file.current_file;  % File reader object for ND2 data.
        
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
            obj = zeros(height, width, numZ, numC, numT, 'like', metadata.ml_bit_depth);
        
            % Loop through z, c, and t indices to retrieve planes
            for idxZ = 1:numZ
                for idxC = 1:numC
                    for idxT = 1:numT
                        % Retrieve coordinates in zero-based format
                        z = p.Results.z(idxZ);
                        c = p.Results.c(idxC);
                        t = p.Results.t(idxT);
        
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
        function data = get_data(file)
        end

        function write_data(np_file, nd2_file)

        end

        function obj = get_keys(file, query, scope)
            % GET_KEYS Retrieve specific keys from the file metadata.
            %
            % Parameters:
            %   file - File reader object.
            %   query - Query string for key matching.
            %   scope - Scope ('globals' or 'series') for metadata search.
            %
            % Returns:
            %   obj - Metadata values corresponding to the queried keys.

            [globals, series] = DataHandling.Helpers.nd2.parse_keys(file); % Parse metadata into globals and series.
            keys = struct('globals', {fieldnames(globals)}, 'series', {fieldnames(series)}); % Structure for keys.

            % Handle optional 'scope' argument
            if ~exist('scope', 'var')
                % Default case returns both global and series keys
                obj = struct( ...
                    'globals', {DataHandling.Helpers.nd2.get_keys(file, query, 'globals')}, ...
                    'series', {DataHandling.Helpers.nd2.get_keys(file, query, 'series')});
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
                    values = string(cellfun(@(x)globals.get(x), order, 'UniformOutput', false));
                case 'series'
                    values = string(cellfun(@(x)series.get(x), order, 'UniformOutput', false));
            end

            % Filter out any "NA" values
            obj = values(values ~= "NA");
        end

        function [globals, series] = parse_keys(file)
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

            % Parse global metadata only if not already done
            if isempty(g_table)
                g_table = DataHandling.Helpers.java.parse_hashtable(file.getGlobalMetadata);
            end

            % Parse series metadata only if not already done
            if isempty(s_table)
                s_table = DataHandling.Helpers.java.parse_hashtable(file.getSeriesMetadata);
            end

            globals = g_table;
            series = s_table;
        end
    end
end
