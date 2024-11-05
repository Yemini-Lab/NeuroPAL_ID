classdef nd2

    properties
    end

    properties (Access = public, Constant)
        channel_keys = {'ChannelName', 'ChannelOrder', 'ChannelCount', 'ChannelColor'};
        name_substr = 'Global Name #'; 
    end
    
    methods (Static, Access = public)
        function [obj, metadata] = open(file)
            f = bfGetReader(file);

            metadata = struct( ...
                'path', {file}, ...
                'order', {f.getDimensionOrder}, ...
                'nx', {f.getSizeX}, ...
                'ny', {f.getSizeY}, ...
                'nz', {f.getSizeZ}, ...
                'nc', {f.getSizeC}, ...
                'nt', {f.getSizeT}, ...
                'has_dic', {1}, ...
                'has_gfp', {1}, ...
                'bit_depth', {f.getMetadataStore.getPixelsSignificantBits(0).getValue()}, ...
                'rgbw', {[1 2 3 4]}, ...
                'scale', {[0 0 0]});

            if DataHandling.Lazy.file.is_lazy
                obj = f;
            else
                obj = bfOpen(file);
                obj = obj{1};
            end

        end

        function [names, hash_names] = get_channels(file)
            names = {};
            for c=1:file.getSizeC
                names{end+1} = file.getMetadataStore.getChannelName(0, c - 1);
            end

            hash_names = DataHandling.Helpers.nd2.get_keys(file, DataHandling.Helpers.nd2.name_substr);
        end

        function obj = get_plane(varargin)
            metadata = DataHandling.Lazy.file.metadata;
            t = Program.GUIHandling.current_frame;
        
            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', t);
            parse(p, varargin{:});
        
            file = DataHandling.Lazy.file.current_file;  % Current file's reader object.
        
            % Zero-based origins
            x0 = min(p.Results.x);
            y0 = min(p.Results.y);
        
            % Correct width and height calculations
            width = max(p.Results.x);
            height = max(p.Results.y);
        
            % Determine the number of planes
            numZ = numel(p.Results.z);
            numC = numel(p.Results.c);
            numT = numel(p.Results.t);
        
            % Preallocate obj as a multidimensional array
            obj = zeros(height, width, numZ, numC, numT, 'like', metadata.ml_bit_depth);
        
            % Loop over all combinations of z, c, t
            for idxZ = 1:numZ
                for idxC = 1:numC
                    for idxT = 1:numT
                        z = p.Results.z(idxZ);
                        c = p.Results.c(idxC);
                        t = p.Results.t(idxT);
        
                        % Calculate plane index (1-indexed)
                        planeIndex = file.getIndex(z - 1, c - 1, t - 1) + 1;
        
                        % Retrieve the plane
                        plane = bfGetPlane(file, planeIndex, x0, y0, width, height);
        
                        % Store the plane in the multidimensional array
                        obj(:, :, idxZ, idxC, idxT) = plane;
                    end
                end
            end
        end
    end

    methods (Static, Access = private)
        function obj = get_keys(file, query, scope)
            [globals, series] = DataHandling.Helpers.nd2.parse_keys(file);
            keys = struct('globals', {fieldnames(globals)}, 'series', {fieldnames(series)});
            
            if ~exist('scope', 'var')
                obj = struct( ...
                    'globals', {DataHandling.Helpers.nd2.get_keys(file, query, 'globals')}, ...
                    'series', {DataHandling.Helpers.nd2.get_keys(file, query, 'series')});
                return
            end

            target_keys = keys.(scope);
            idx = contains(target_keys, DataHandling.Helpers.java.to_valid(query));
            str = string(target_keys(idx));
            order = string({str{end:-1:1}});

            switch scope
                case 'globals'
                    values = string(cellfun(@(x)globals.get(x), order, 'UniformOutput', false));
                case 'series'
                    values = string(cellfun(@(x)series.get(x), order, 'UniformOutput', false));
            end

            obj = values(values~="NA");
        end

        function [globals, series] = parse_keys(file)
            globals = DataHandling.Helpers.java.parse_hashtable(file.getGlobalMetadata);
            series =  DataHandling.Helpers.java.parse_hashtable(file.getSeriesMetadata);
        end
    end
end

