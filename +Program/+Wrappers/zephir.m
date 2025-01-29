classdef zephir
    
    properties
    end
    
    methods (Static, Access = public)
        function config = config(new_config)
            persistent current_zephir_config

            if nargin > 0
                current_zephir_config = new_config;
            end

            config = current_zephir_config;
        end

        function config_path = request_config(args)
            app = Program.app;
            config = Program.Wrappers.zephir.config();

            for a=1:length(args)
                arg = args{a};
                if isempty(config.(arg))
                    switch arg
                        case 'channel'
                            config.dataset = 1;

                        case 'dataset'
                            config.dataset = app.video_info.path;
                            
                        case {'nx', 'ny', 'nz', 'nc', 'nt', 'dims', 'dimensions'}
                            config.nx = app.video_info.nx;
                            config.ny = app.video_info.ny;
                            config.nz = app.video_info.nz;
                            config.nc = app.video_info.nc;
                            config.nt = app.video_info.nt;

                        case 'cache'
                            config.cache = Program.Routines.Videos.cache.get().path;

                        case {'dim_index', 'dimensional_index'}
                            config.dim_index = Program.Routines.Videos.annotations.dimensional_index;

                    end
                end
            end

            Program.Wrappers.zephir.config(config);
            [path, name, ~] = fileparts(config.dataset);
            config_path = fullfile(path, name, 'mat');
            save(config_path, '-struct', 'config', '-v7.3');
        end

        function convert_annotations()
            config = Program.Wrappers.zephir.request_config({'cache', 'dim_index'});
            Program.Wrappers.zephir.run('convert', config);
        end

        function recommend_frames()
            config = Program.Wrappers.zephir.request_config({'channel', 'dataset', 'nx', 'ny', 'nz', 'nc', 'nt'});
            Program.Wrappers.zephir.run('recommend_frames', config);
        end

        function track_neurons()
            app = Program.app;
            args = app.compile_arguments();
            config = Program.Wrappers.zephir.request_config(fieldnames(args));
            Program.Wrappers.zephir.run('track_all', config);
        end

        function extract_activity()
            config = Program.Wrappers.zephir.request_config({'dataset'});
            Program.Wrappers.zephir.run('extract_traces', config);
        end

        function run(operation, config)
            app = Program.app;
            arguments = sprintf(' --operation=zephir_%s --config="%s"', operation, config);
            executable = fullfile(app.script_dir, sprintf('npal%s', app.script_ext));

            if ~isdeployed
                executable = sprintf('python %s', executable);
            end

            [status, output] = system([executable, arguments]);
        end
    end
end

