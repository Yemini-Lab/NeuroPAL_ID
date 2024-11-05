classdef file

    properties
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

        function read(path)
            [~, ~, ext] = fileparts(path); ext = ext(2:end);
            helper = DataHandling.Lazy.file.get_helper(ext);
            [f_obj, f_metadata] = DataHandling.(helper).open(path);
            [~, f_metadata.ml_bit_depth] = DataHandling.Types.getMATLABDataType(f_metadata.bit_depth);
            f_metadata.fmt = ext;

            DataHandling.Lazy.file.current_file(f_obj);
            DataHandling.Lazy.file.metadata(f_metadata);
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

        function helper = get_helper(ext)
            if ~exist('ext', 'var')
                f_metadata = DataHandling.Lazy.file.metadata();
                ext = f_metadata.fmt;
            end

            helper = sprintf("Helpers.%s", ext);
            if ~isfile(sprintf("+DataHandling\\+Helpers\\%s.m", ext))
                error("No helper script available for %s file format.", ext);
            end
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
            arr = DataHandling.(helper).get_plane(varargin);
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
            rgbw = metadata.rgbw;
            gammas = 1;

            f_obj.info = struct( ...
                'file', metadata.path, ...
                'scale', metadata.scale, ...
                'DIC', dic, ...
                'RGBW', rgbw, ...
                'GFP', gfp, ...
                'gamma', gammas, ...
                'is_video', metadata.is_video);

            f_obj.prefs = struct( ...
                'RGBW', rgbw, ...
                'DIC', dic, ...
                'GFP', gfp, ...
                'gamma', gammas, ...
                'lazy', 1);
            
            f_path = strrep(metadata.path, metadata.fmt, 'mat');
            save(f_path, "-struct", "f_obj", '-v7.3');

            h_write = matfile(f_path, "Writable", true);
            write_class = sprintf('uint%.f', metadata.ml_bit_depth);
            h_write.data = zeros(metadata.ny, metadata.nx, metadata.nz, metadata.nc, metadata.nt, write_class);

            d.Message = "Constructing cache file...";
            if metadata.is_video
                for t=1:metadata.nt
                    d.Value = t/metadata.nt;
                    h_write.data(:, :, :, :, t) = cast(DataHandling.Lazy.file.get_frame(t), write_class);
                end
                
            else
                for z=1:metadata.nz
                    d.Value = z/metadata.nz;
                    h_write.data(:, :, z, :) = cast(DataHandling.Lazy.file.get_slice(z), write_class);
                end

            end
        end
    end
end

