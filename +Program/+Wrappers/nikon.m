classdef nikon
    
    properties (Constant)
        task_string = dictionary( ...
            'convert_annotations', {'Converting annotations'}, ...
            'recommend_frames', {'Calculating recommended frames'}, ...
            'track_neurons', {'Running tracking algorithm'}, ...
            'extract_activity', {'Extracting activity traces'});
    end
    
    methods (Static, Access = public)
        function config = config(new_config)
            persistent current_nikon_config

            if nargin > 0
                current_nikon_config = new_config;
            elseif isempty(current_nikon_config)
                current_nikon_config = struct();
            end

            config = current_nikon_config;
        end

        function config_path = request_config(args)
            app = Program.app;
            config = Program.Wrappers.nikon.config();
            mcheck = {};

            for a=1:length(args)
                arg = args{a};
                if ~isfield(config, arg) || isempty(config.(arg))
                    switch arg
                        case 'channel'
                            config.channel = 1;

                        case {'dataset', 'source_path'}
                            if isfield(app.video_info, 'file')
                                config.(arg) = app.video_info.file;
                            elseif isfield(app.video_info, 'path')
                                config.(arg) = app.video_info.path;
                            end

                        case 'target_path'
                            if isfield(app.video_info, 'file')
                                config.target_path = strrep( ...
                                    app.video_info.file, '.nd2', '.mat');
                            elseif isfield(app.video_info, 'path')
                                config.target_path = strrep( ...
                                    app.video_info.path, '.nd2', '.mat');
                            end

                        case 'is_lazy'
                            config.is_lazy = 1;
                            
                        case {'nx', 'ny', 'nz', 'nc', 'nt', 'dims', 'dimensions'}
                            if ~any(ismember(mcheck, 'dims'))
                                config.nx = app.video_info.nx;
                                config.ny = app.video_info.ny;
                                config.nz = app.video_info.nz;
                                config.nc = app.video_info.nc;
                                config.nt = app.video_info.nt;
                                mcheck{end+1} = 'dims';
                            end

                        case 'cache'
                            config.cache = Program.Routines.Videos.cache.get().path;

                        case {'dim_index', 'dimensional_index'}
                            config.dim_index = Program.Routines.Videos.annotations.dimensional_index;

                    end
                end
            end

            Program.Wrappers.nikon.config(config);
            [path, name, ~] = fileparts(config.dataset);
            config_path = fullfile(path, [name, '.mat']);
            save(config_path, '-struct', 'config', '-v7.3');
        end

        function import()
            config = Program.Wrappers.nikon.request_config({'source_path'});
            Program.Wrappers.core.run('import', config);
        end

        function convert()
            args = {'source_path', 'target_path', 'is_lazy'};
            config = Program.Wrappers.nikon.request_config(args);
            Program.Wrappers.core.run('convert', config);
        end

        function framedata()
            args = {'source_path', 'target_frames'};
            config = Program.Wrappers.nikon.request_config(args);
            Program.Wrappers.core.run('framedata', config);
        end

        function aftercare(func)
            switch func
                case 'import'
                case 'convert'
                case 'framedata'
            end
        end
    end
end

