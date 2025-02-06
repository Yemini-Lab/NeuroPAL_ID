classdef zephir
    
    properties (Constant)
        task_string = dictionary( ...
            'convert_annotations', {'Converting annotations'}, ...
            'recommend_frames', {'Calculating recommended frames'}, ...
            'track_neurons', {'Running tracking algorithm'}, ...
            'extract_activity', {'Extracting activity traces'});
    end
    
    methods (Static, Access = public)
        function config = config(new_config)
            persistent current_zephir_config

            if nargin > 0
                current_zephir_config = new_config;
            elseif isempty(current_zephir_config)
                current_zephir_config = struct('is_config', {1});
            end

            config = current_zephir_config;
        end

        function config_path = request_config(args)
            app = Program.app;
            config = Program.Wrappers.zephir.config();
            mcheck = {};

            for a=1:length(args)
                arg = args{a};
                if ~isfield(config, arg) || isempty(config.(arg))
                    switch arg
                        case 'channel'
                            config.channel = 1;

                        case 'dataset'
                            if isfield(app.video_info, 'file')
                                config.dataset = app.video_info.file;
                            elseif isfield(app.video_info, 'path')
                                config.dataset = app.video_info.path;
                            end
                            
                        case {'nx', 'ny', 'nz', 'nc', 'nt', 'dims', 'dimensions'}
                            if ~any(ismember(mcheck, 'dims'))
                                config.nx = app.video_info.nx;
                                config.ny = app.video_info.ny;
                                config.nz = app.video_info.nz;
                                config.nc = app.video_info.nc;
                                config.nt = app.video_info.nt;
                                mcheck{end+1} = 'dims';
                            end

                        case 't_list'
                            t_start = app.track_t_start_frame.Value;
                            t_end = app.track_t_end_frame.Value;
                            config.t_list = t_start:t_end;
                            config.t_list = config.t_list - 1;

                        case 'cache'
                            config.cache = Program.Routines.Videos.cache.get().path;

                        case {'dim_index', 'dimensional_index'}
                            config.dim_index = Program.Routines.Videos.annotations.dimensional_index;

                    end
                end
            end

            Program.Wrappers.zephir.config(config);
            [path, name, ~] = fileparts(config.dataset);
            config_path = fullfile(path, [name, '.mat']);
            save(config_path, '-struct', 'config', '-v7.3');
        end

        function convert_annotations()
            config = Program.Wrappers.zephir.request_config({'cache', 'dim_index'});
            Program.Wrappers.core.run('convert', config);
        end

        function recommend_frames()
            config = Program.Wrappers.zephir.request_config({'channel', 'dataset', 'nx', 'ny', 'nz', 'nc', 'nt'});
            Program.Wrappers.core.run('recommend_frames', config);
        end

        function track_neurons()
            app = Program.app;
            args = app.compile_arguments();
            config = Program.Wrappers.zephir.request_config(fieldnames(args));
            Program.Wrappers.core.run('track_all', config);
        end

        function extract_activity()
            config = Program.Wrappers.zephir.request_config({'dataset'});
            Program.Wrappers.core.run('extract_traces', config);
        end

        function aftercare(func)
            switch func
                case 'convert_annotations'
                    uiconfirm(Program.window, "Conversion finished.", "NeuroPAL_ID");

                case 'recommend_frames'
                    Program.Wrappers.zephir.set_bookmarks();

                case 'track_neurons'
                    Program.Wrappers.zephir.load_annotations();
                    
                case 'extract_activity'
                    Program.Wrappers.zephir.load_activity();
            end
        end
    end
end

