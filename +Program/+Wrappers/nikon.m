classdef nikon
    
    properties (Constant)
        task_string = dictionary( ...
            'import', {'Importing Nikon volume'}, ...
            'convert', {'Converting Nikon file'}, ...
            'framedata', {'Retrieving frame-wise event data'});
    end

    methods (Static, Access = public)
        function import(varargin)
            Program.Handlers.dialogue.add_task('Importing Nikon package...');
            config = Program.Wrappers.nikon.request_config(varargin{:});
            Program.Wrappers.core.run('import', config);
            Program.Handlers.dialogue.resolve();
        end

        function convert(nd2_file_path, target_file_path, use_lazy_mode)
            Program.Handlers.dialogue.add_task('Converting Nikon file...');
            if nargin < 3
                use_lazy_mode = false;
            end

            config = Program.Wrappers.nikon.request_config( ...
                'dataset', nd2_file_path, ...
                'target_path', target_file_path, ...
                'is_lazy', use_lazy_mode);

            Program.Wrappers.core.run('convert', config);
            Program.Handlers.dialogue.resolve();
        end

        function framedata(nd2_file_path)
            Program.Handlers.dialogue.add_task('Retrieving frame-wise event data...');
            config = Program.Wrappers.nikon.request_config( ...
                'dataset', nd2_file_path);

            Program.Wrappers.core.run('framedata', config);
            Program.Handlers.dialogue.resolve();
        end
    end
    
    methods (Static, Access = private)
        function config = config(new_config)
            persistent current_nikon_config

            if nargin > 0
                current_nikon_config = new_config;
            elseif isempty(current_nikon_config)
                current_nikon_config = struct();
            end

            config = current_nikon_config;
        end

        function config_path = request_config(varargin)
            p = inputParser;

            for v=1:2:nargin
                addOptional(p, varargin{v}, []);
            end

            parse(p, varargin{:});
            config = Program.Wrappers.nikon.config(p.Results);

            Program.Wrappers.nikon.config(config);
            [path, name, ~] = fileparts(config.dataset);
            config_path = fullfile(path, [name, '.mat']);
            save(config_path, '-struct', 'config', '-v7.3');
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

