classdef nd2
    % ND2 Class for handling and extracting metadata and images from ND2 files.
    
    properties
        % No properties defined for instances of this class. All properties are static or constant.
    end
    
    properties (Access = public, Constant)
        % Constant properties for channel identification keys and naming convention.
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
                'order', {char(f.getDimensionOrder)}, ...
                'nx', {f.getSizeX}, ...
                'ny', {f.getSizeY}, ...
                'nz', {f.getSizeZ}, ...
                'nc', {f.getSizeC}, ...
                'nt', {f.getSizeT}, ...
                'has_dic', {1}, ... % Placeholder for differential interference contrast
                'has_gfp', {1}, ... % Placeholder for GFP channel presence
                'bit_depth', {f.getMetadataStore.getPixelsSignificantBits(0).getValue()}, ...
                'rgbw', {[1 2 3 4]}, ...
                'scale', {[0 0 0]});

            % Load the file data or return a lazy reader object depending on the file handling mode
            if Program.states.instance().is_lazy
                obj = f; % Return lazy file reader if lazy loading is enabled.
            else
                obj = bfOpen(file); % Load full file data.
                obj = obj{1}; % Use the first item if the file contains a list.
            end

        end

        function [names, hash_names] = get_channels(file)
            % GET_CHANNELS Retrieve channel names and hashed names from metadata.
            %
            % Parameters:
            %   file - File reader object containing ND2 metadata.
            %
            % Returns:
            %   names - List of channel names.
            %   hash_names - Hashed names based on specific queries.

            names = {};
            hash_names = {};

            % Loop through each channel, retrieving the name and associated hashed data
            for c = 1:file.getSizeC
                % Retrieve channel name by accessing metadata
                names{end+1} = string(file.getMetadataStore.getChannelName(0, c - 1));
                
                % Retrieve hashed name using a custom key based on channel index
                hash_names{end+1} = DataHandling.Helpers.nd2.get_keys(file, ...
                    append(DataHandling.Helpers.nd2.name_substr, num2str(c)));
            end

            % Convert names to string array format
            names = string(names);
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
