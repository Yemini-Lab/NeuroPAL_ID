classdef file

    properties (Constant, Access = public)
    end
    
    methods (Static)
        function package = current_file(new_file)
            persistent instance

            if exist('new_file', 'var')
                instance = new_file;
            end

            package = instance;
        end

        function package = metadata(new_metadata)
            persistent current_metadata

            if exist('new_metadata', 'var')
                new_metadata.is_video = new_metadata.nt > 1;
                current_metadata = new_metadata;
            end

            package = current_metadata;
        end

        function flag = is_lazy(state)
            persistent lazy_state

            if exist('state', 'var')
                lazy_state = state;
            elseif isempty(lazy_state)
                lazy_state = 0;
            end

            flag = lazy_state;
        end

        function flag = is_video(state)
            persistent video_state

            if exist('state', 'var')
                video_state = state;
            elseif isempty(video_state)
                video_state = 0;
            end

            flag = video_state;
        end

        function helper = get_helper(ext)
            persistent current_helper

            if exist('ext', 'var')
                if ~isfile(sprintf("+DataHandling\\+Helpers\\%s.m", ext))
                    error("No helper script available for %s file format.", ext);
                else 
                    current_helper = sprintf("Helpers.%s", ext);
                end
            end

            helper = current_helper;            
        end

        function reload(path)
            [~, ~, ext] = fileparts(path); ext = ext(2:end); 

            if ~strcmp(ext, 'mat')
                DataHandling.Lazy.file.read(path);
                return
            end

            f_obj = matfile(path);
            f_metadata = DataHandling.Helpers.mat.load_metadata(f_obj);

            DataHandling.Lazy.file.current_file(f_obj);                                                 % Set file object as current file.
            DataHandling.Lazy.file.metadata(f_metadata);                                                % Set metadata struct as current file.
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
            helper = DataHandling.Lazy.file.get_helper(ext);                                            % Identify & define helper script.

            [f_obj, f_metadata] = DataHandling.(helper).open(path);                                     % Read file metadata.
            [~, f_metadata.ml_bit_depth] = DataHandling.Types.getMATLABDataType(f_metadata.bit_depth);  % If necessary, convert data type to one MATLAB can work with.
            
            f_metadata.channels = DataHandling.channels.get(f_obj);                                     % Grab channel info, add to metadata.
            f_metadata.nc = length(f_metadata.channels.as_rendered);                                    % Update number of channels according to validated key.
            f_metadata.fmt = ext;                                                                       % Add file extension to metadata.

            DataHandling.Lazy.file.current_file(f_obj);                                                 % Set file object as current file.
            DataHandling.Lazy.file.metadata(f_metadata);                                                % Set metadata struct as current file.
        end

        function dims = get_dims(order)
            if ~exist('order', 'var')
                order = 'xyzct';
            end

            dims = [];
            for n=1:length(DataHandling.Lazy.file.metadata().order)
                dims = [dims, dims.(sprintf("n%s", order{n}))];
            end
        end

        function [as_loaded, as_loaded_hash] = get_channels(file)
            if ~exist('file', 'var')
                file = DataHandling.Lazy.file.current_file;
            end

            helper = DataHandling.Lazy.file.get_helper;
            [as_loaded, as_loaded_hash] = DataHandling.(helper).get_channels(file);
        end

        function arr = get_channel(c)
            helper = DataHandling.Lazy.file.get_helper;
            arr = DataHandling.(helper).get_plane('c', c);
        end

        function arr = get_slice(z)
            helper = DataHandling.Lazy.file.get_helper;
            arr = DataHandling.(helper).get_plane('z', z);
        end

        function arr = get_frame(t)
            helper = DataHandling.Lazy.file.get_helper;
            arr = DataHandling.(helper).get_plane('t', t);
        end

        function arr = get_plane(varargin)
            helper = DataHandling.Lazy.file.get_helper;
            metadata = DataHandling.Lazy.file.metadata;

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
            metadata = DataHandling.Lazy.file.metadata();

            window_fig = Program.GUIHandling.window_fig();
            d = uiprogressdlg(window_fig, "Message", "Reading metadata...", "Indeterminate", "off");

            f_obj = struct( ...
                'version', Program.ProgramInfo.version, ...
                'Writable', true);

            %{
            dic = Program.channel_handler.has_dic;
            gfp = Program.channel_handler.has_gfp;
            rgbw = Program.channel_handler.get('rgbw');
            gammas = Program.channel_handler.get('gammas');
            %}

            dic = metadata.has_dic;
            gfp = metadata.has_gfp;
            chan_order = metadata.channels.as_rendered;
            data_chans = metadata.channels.order(metadata.channels.order~=metadata.channels.null_channels);
            gammas = 1;

            f_obj.info = struct( ...
                'file', {metadata.path}, ...
                'scale', {metadata.scale}, ...
                'DIC', {dic}, ...
                'RGBW', {chan_order(1:4)}, ...
                'GFP', {gfp}, ...
                'chan_order', {chan_order}, ...
                'gamma', {gammas}, ...
                'is_video', {metadata.is_video});

            f_obj.prefs = struct( ...
                'RGBW', {chan_order(1:4)}, ...
                'DIC', {dic}, ...
                'GFP', {gfp}, ...
                'gamma', {gammas}, ...
                'lazy', {1});

            f_obj.worm = struct( ...
                'body', {''}, ...
                'age', {'Adult'}, ...
                'sex', {'XX'}, ...
                'strain', {''}, ...
                'notes', {''});

            f_obj.channels = metadata.channels;
            
            f_path = strrep(metadata.path, metadata.fmt, 'mat');
            save(f_path, "-struct", "f_obj", '-v7.3');

            h_write = matfile(f_path, "Writable", true);
            h_write.data = zeros(metadata.ny, metadata.nx, metadata.nz, metadata.nc, metadata.nt, Program.GUIHandling.standard_class);

            d.Message = "Constructing cache file...";
            if metadata.is_video
                for t=1:metadata.nt
                    d.Value = t/metadata.nt;
                    this_frame = DataHandling.Lazy.file.get_frame(t);
                    h_write.data(:, :, :, :, t) = DataHandling.Types.to_standard(this_frame(:, :, :, data_chans, :));
                end
                
            else
                for z=1:metadata.nz
                    d.Value = z/metadata.nz;
                    this_slice = DataHandling.Lazy.file.get_slice(z);
                    h_write.data(:, :, z, :) = DataHandling.Types.to_standard(this_slice(:, :, :, data_chans));
                end

            end
        end
    end
end

