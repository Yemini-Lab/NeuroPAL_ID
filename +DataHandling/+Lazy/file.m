classdef file
    %FILE_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        current_file;           % Currently loaded file. Reader object if lazy loaded, otherwise array.
        is_lazy;                % Flag indicating whether the file is being handled in chunks.
        fmt;                    % File extension without a leading period (i.e. "nwb", not ".nwb").
    end
    
    methods
        function code = read(file, lazy_flag)
            if ~exist('lazy_flag', 'var')
                [DataHandling.file.is_lazy, ~, ~] = Program.preprocess.check_memory(file);
            else
                DataHandling.file.is_lazy = lazy_flag;
            end

            [~, ~, ext] = fileparts(file); ext = ext(2:end);
            helper = DataHandling.file.get_helper(ext);
            [f_obj, f_metadata] = DataHandling.(helper).open(file);

            DataHandling.file.current_file = f_obj;
            DataHandling.file.metadata(f_metadata);
            DataHandling.file.fmt = ext;
        end

        function package = metadata(reset)
            persistent instance

            if ~exist('reset', 'var')
                package = instance;
            else
                instance = reset;
            end
        end

        function dims = get_dims(order)
            if ~exist('order', 'var')
                order = 'xyzct';
            end

            dims = [];
            for n=1:length(DataHandling.file.metadata().order)
                dims = [dims, dims.(sprintf("n%s", order{n}))];
            end
        end

        function helper = get_helper(ext)
            if ~exist('ext', 'var')
                ext = DataHandling.file.fmt;
            end

            helper = sprintf("Helpers.%s", ext);
            if ~isfile(sprintf("+DataHandling\%s.m", helper))
                error("No helper script available for %s file format.", ext);
            end
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
            f_metadata = DataHandling.file.metadata();
            arr = DataHandling.(helper).get_plane(varargin);
        end

        function [f_path, f_obj] = create_cache(data_flag)
            metadata = DataHandling.file.metadata();

            f_obj = struct( ...
                'version', Program.ProgramInfo.version, ...
                'Writable', true);

            dic = Program.channel_handler.has_dic;
            gfp = Program.channel_handler.has_gfp;
            rgbw = Program.channel_handler.get('rgbw');
            gammas = Program.channel_handler.get('gammas');

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
            
            f_path = strrep(metadata.path, DataHandling.file.fmt, 'mat');
            save(f_path, "f_obj", "-struct", '-v7.0');


            h_write = matfile(f_path);
            h_write.data = zeros([metadata.ny, metadata.nx, metadata.nz, metadata.nc, metadata.nt], metadata.bit_depth);

            if exist('data_flag', 'var')
                if is_video
                    for t=1:metadata.nt
                        h_write.data(:, :, :, :, t) = DataHandling.file.get_frame(t);
                    end
                    
                else
                    for z=1:metadata.nz
                        h_write.data(:, :, z, :) = DataHandling.file.get_slice(z);
                    end

                end
            end

            DataHandling.file.cache_file = h_write;
        end
    end
    
    methods (Static)
        function f_size = check_size         
            if strcmp(DataHandling.file.fmt, 'nwb')
                f_size = DataHandling.Helper.nwb.get_size;
            else
                f_size = dir(DataHandling.file.metadata().path).bytes;
            end
        end
    end
end

