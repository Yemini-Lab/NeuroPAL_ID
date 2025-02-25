classdef mat
    
    properties
        % No properties defined for instances of this class. All properties are static or constant.
    end
    
    properties (Access = public, Constant)
    end
    
    methods (Static, Access = public)
        %% New
        function create(path, dims, dtype, metadata)
            array = zeros(dims, dtype);
            if exist('metadata', 'var')
                fstruct = struct( ...
                    'array', {array}, ...
                    'metadata', {metadata});
            else
                fstruct = struct( ...
                    'array', {array}, ...
                    'metadata', {[]});
            end
            
            save(path, '-struct', 'fstruct', '-v7.3');
        end

        function write(varargin)
            p = inputParser();
            addRequired(p, 'file');
            addRequired(p, 'arr');
            addParameter(p, 't',    []);  % default means "all"
            addParameter(p, 'z',    []);
            addParameter(p, 'mode', 'chunk'); % default read mode
            parse(p, varargin{:});
            cursor = rmfield(p.Results, {'mode', 'file', 'arr'});
            array = p.Results.arr;

            target_file = matfile(p.Results.file, 'Writable', true);
            if isempty(cursor.t)
                target_file.array(:, :, cursor.z, :) = array;
            elseif isempty(cursor.z)
                target_file.array(:, :, :, :, cursor.t) = array;
            else
                target_file.array(:, :, cursor.z, :, cursor.t) = array;
            end
        end

        function obj = get_reader(path)
            obj = matfile(path);
        end

        function metadata = get_metadata(obj)
            metadata = obj.read_obj.metadata;
        end

        function arr = read(obj, varargin)
            p = inputParser();
            addRequired(p, 'obj');
            addParameter(p, 't',    []);  % default means "all"
            addParameter(p, 'z',    []);
            addParameter(p, 'c',    []);
            addParameter(p, 'x',    []);
            addParameter(p, 'y',    []);
            addParameter(p, 'mode', 'chunk'); % default read mode
            parse(p, obj, varargin{:});
            cursor = rmfield(p.Results, {'mode', 'obj'});
            is_volume = isa(obj, 'volume');
            
            if strcmp(p.Results.mode, 'chunk') || ~all(structfun(@isempty, cursor))
                if is_volume
                    native_dims = obj.native_dims;
                    obj = obj.read_obj;
                else
                    native_dims = size(obj, 'array');
                end
    
                [order, dims] = Helpers.interpret_dimensions(native_dims);
                parameters = fieldnames(cursor);
    
                for p=1:length(parameters)
                    parameter = parameters{p};
                    if isempty(cursor.(parameter)) && isfield(dims, parameter)
                        cursor.(parameter) = 1:dims.(parameter);
                    end
                end
    
                fn = fieldnames(cursor);
                idx_cell = cellfun(@(f) cursor.(f), fn, 'UniformOutput', false);
                idx_cell = idx_cell(1:length(native_dims));
                indices = idx_cell(flip(order));
                arr = obj.array(indices{:});
            else
                arr = obj.array;
            end
        end

        %% Legacy
        function [obj, metadata] = open(file)
            f = matfile(file);
            info = f.info;

            % Collect metadata details about the ND2 file
            metadata = struct( ...
                'path', {info.file}, ...
                'bit_depth', {class(f.data)}, ...
                'scale', {info.scale});

            metadata.bit_depth = str2num(metadata.bit_depth(5:end));
            metadata.dimensions = DataHandling.Helpers.mat.get_dimensions(f);
            metadata.channels = DataHandling.Helpers.mat.get_channels(f);

            % Load the file data or return a lazy reader object depending on the file handling mode
            if Program.states.instance().is_lazy
                obj = f; % Return lazy file reader if lazy loading is enabled.
            else
                obj = f.data; % Load full file data.
            end

        end


        function dimension_struct = get_dimensions(file)
            dimensions = size(file, 'data');
            
            if length(dimensions) < 5
                nt = dimensions(5);
            else
                nt = 1;
            end

            dimension_struct = struct( ...
                'order', {char('xyzct')}, ...
                'nx', {dimensions(2)}, ...
                'ny', {dimensions(1)}, ...
                'nz', {dimensions(3)}, ...
                'nc', {dimensions(4)}, ...
                'nt', {nt});
        end

        function channel_struct = get_channels(file)            
            if file.version >= 2
                channel_struct = file.channels;
            else
                channel_struct = struct( ...
                    'names', {DataHandling.Helpers.nd2.get_channel_names(file)}, ...
                    'order', {Program.Handlers.channels.parse_order(names)}, ...
                    'has_bools', {Program.Handlers.channels.parse_presence(names)});
            end
        end

        function metadata = load_metadata(file)
            tdims = size(file, 'data');
            info = file.info;

            metadata = struct( ...
                'path', {info.file}, ...
                'nx', {tdims(2)}, ...
                'ny', {tdims(1)}, ...
                'nz', {tdims(3)}, ...
                'nc', {tdims(4)}, ...
                'has_dic', {info.GFP}, ... % Placeholder for differential interference contrast
                'has_gfp', {info.DIC}, ... % Placeholder for GFP channel presence
                'bit_depth', {class(file.data)}, ...
                'rgbw', {info.RGBW}, ...
                'scale', {info.scale});

            if length(tdims) > 4
                metadata.nt = tdims(5);
            else
                metadata.nt = 1;
            end

            metadata.channels = file.channels;
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
            switch class(file)
                case 'matlab.io.MatFile'
                    obj = file.data(p.Results.y, p.Results.x, p.Results.z, p.Results.c, p.Results.t);
                otherwise
                    obj = file(p.Results.y, p.Results.x, p.Results.z, p.Results.c, p.Results.t);
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
