classdef file

    properties
    end
    
    methods (Static)
        function package = current_file(new_file)
            persistent instance
            if nargin > 0
                instance = new_file;
            end

            package = instance;
        end

        function package = metadata(new_metadata)
            persistent current_metadata
            if nargin > 0
                new_metadata.is_video = new_metadata.nt > 1;
                current_metadata = new_metadata;
            end

            package = current_metadata;
        end

        function read(path)
            %% Reads in file and generates the following:
            % (Persistent) current_file: Reader object that can be referenced globally.
            % (Persistent) helper: Support class specific to supported file formats.
            % (Persistent) Metadata: Struct with k-v pairs...
            %   path: Path to file.
            %   fmt: File extension.
            %   order: xyzc/t load order.
            %   nx, ny, nz, nc, nt: Array dimensions.
            %   has_dic, has_gfp: Booleans indicating presence of relevant channel.
            %   bit_depth: Bit depth.
            %   RGBW: Array of indices corresponding to the R, G, B, and W channels.
            %   channels: Struct with k-v pairs...
            %       as_loaded: Channels as loaded from raw file.
            %       order: Indices of all channels, in autosorted order.
            %       names: Names of all valid channels, in autosorted order.
            %       null_channels: Indices of invalid channels in autosorted array.
            %       as_rendered: Indices of all valid channels as rendered from processing array.

            [~, ~, ext] = fileparts(path); ext = ext(2:end);                                            % Get file extension.
            helper = DataHandling.file.get_helper(ext);                                                 % Identify & define helper script.

            [f_obj, f_metadata] = DataHandling.(helper).open(path);                                     % Read file metadata.
            [~, f_metadata.ml_bit_depth] = DataHandling.Types.getMATLABDataType(f_metadata.bit_depth);  % If necessary, convert data type to one MATLAB can work with.
            
            f_metadata.channels = DataHandling.channels.get(f_obj);                                     % Grab channel info, add to metadata.
            f_metadata.nc = length(f_metadata.channels.as_rendered);                                    % Update number of channels according to validated key.
            f_metadata.fmt = ext;                                                                       % Add file extension to metadata.

            DataHandling.file.current_file(f_obj);                                                      % Set file object as current file.
            DataHandling.file.metadata(f_metadata);                                                     % Set metadata struct as current file.
        end

        function [as_loaded, as_loaded_hash] = get_channels(file)
            if ~exist('file', 'var')
                file = DataHandling.file.current_file;
            end

            helper = DataHandling.file.get_helper;
            [as_loaded, as_loaded_hash] = DataHandling.(helper).get_channels(file);
        end

        function arr = get_channel(c)
            helper = DataHandling.file.get_helper;
            arr = DataHandling.(helper).get_plane('c', c);
        end

        function arr = get_slice(z)
            helper = DataHandling.file.get_helper;
            arr = DataHandling.(helper).get_plane('z', z);
        end

        function arr = get_frame(t)
            helper = DataHandling.file.get_helper;
            arr = DataHandling.(helper).get_plane('t', t);
        end

        function arr = get_plane(varargin)
            helper = DataHandling.file.get_helper;
            metadata = DataHandling.file.metadata;

            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', 1);
            parse(p, varargin{:});

            arr = DataHandling.(helper).get_plane( ...
                'x', p.Results.x, ...
                'y', p.Results.y, ...
                'z', p.Results.z, ...
                'c', p.Results.c, ...
                't', p.Results.t);
        end

        function [f_path, f_obj] = create_cache()
            [f_path, f_obj] = Program.Routines.create_cache();
        end
    end

    methods (Static, Access = private)
        function helper = get_helper(ext)
            persistent current_helper

            if exist('ext', 'var')
                if ~isfile(fullfile('+DataHandling', '+Helpers', sprintf('%s.m', ext)))
                    error("No helper script available for %s file format.", ext);
                else 
                    current_helper = fullfile('+DataHandling', '+Helpers', sprintf('%s.m', ext));
                end
            end

            helper = current_helper;            
        end
    end
end

