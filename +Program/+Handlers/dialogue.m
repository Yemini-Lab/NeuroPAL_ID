classdef dialogue
    
    properties
    end
    
    methods (Static, Access = public)
        function obj = active(input)
            persistent handle

            if nargin > 0
                handle = input;
            end

            if (isa(handle, "handle") && any(~isvalid(handle)))
                handle = [];
            end

            obj = handle;
        end

        function cache_struct = cache(input)
            persistent cache

            if nargin > 0
                cache = input;
            end

            cache_struct = cache;
        end

        function handle = choice(message, choices)
            handle = Program.Handlers.dialogue.active();
            if ~isempty(handle)
                options = struct( ...
                    'Message', {message}, ...
                    'Options', {choices});
                Program.Handlers.dialogue.switch_to('choice', options);

            else
                handle = Program.Handlers.dialogue.create('choice', 'Message', message, 'Options', choices);

            end
        end

        function switch_to(mode, options)
            handle = Program.Handlers.dialogue.active();
            cache_props = properties(handle);

            for p=1:length(cache_props)
                prop = cache_props{p};
                if exist('cache', 'var')
                    cache.(prop) = handle.(cache_props{p});

                else
                    cache = struct(prop, {handle.(cache_props{p})});

                end
            end

            Program.Handlers.dialogue.cache(cache);
            delete(handle);
            Program.Handlers.dialogue.create(mode, options);
        end

        function handle = add_task(task)
            handle = Program.Handlers.dialogue.active();
            if ~isempty(handle)
                handle.Message = sprintf("%s\n-> %s", handle.Message, task);

            else
                handle = Program.Handlers.dialogue.create('progress', 'Message', task);

            end
        end

        function resolve()
            handle = Program.Handlers.dialogue.active();

            if isa(handle, "matlab.ui.dialog.ProgressDialog")
                task_arr = splitlines(handle.Message);
    
                if length(task_arr) < 2 || (length(task_arr) == 2 && isempty(task_arr{end}))
                    delete(handle)
                
                else
                    if isempty(task_arr{end})
                        task_arr = task_arr(1:end-1);
                    end

                    handle.Message = sprintf("%s\n", task_arr{1:end-1});
    
                end

            else
                cache = Program.Handlers.dialogue.cache;

                if ~isempty(cache)
                   delete(handle)
                   Program.Handlers.dialogue.create('progress', cache);
                end
            end
        end
        
        function handle = create(mode, varargin)            
            p = inputParser;
            addOptional(p, 'Message', '');
            addOptional(p, 'Title', '');
            addOptional(p, 'Indeterminate', 'on');
            addOptional(p, 'Options', ["OK", "Cancel"])
            addOptional(p, 'Cancelable', 'off');
            parse(p, varargin{:});

            switch mode
                case 'instruction'
                    handle = Program.Handlers.dialogue.create_instruction(p.Results);

                case 'progress'
                    handle = Program.Handlers.dialogue.create_progress(p.Results);

                case 'choice'
                    handle = Program.Handlers.dialogue.create_choice(p.Results);

                case 'warning'
                    handle = Program.Handlers.dialogue.create_warning(p.Results);

                case 'error'
                    handle = Program.Handlers.dialogue.create_error(p.Results);

                otherwise
                    handle = [];
                    return
            end

            Program.Handlers.dialogue.active(handle);
        end
    end

    methods (Static, Access = private)
        function handle = create_instruction(options)
            window = Program.window;
        end

        function handle = create_progress(options)
            window = Program.window;
            handle = uiprogressdlg(window, ...
                "Message", options.Message, ...
                "Title", options.Title, ...
                "Indeterminate", options.Indeterminate, ...
                "Cancelable", options.Cancelable);
        end

        function handle = create_choice(options)
            window = Program.window;
            handle = uiconfirm(window, ...
                options.Message, ...
                options.Title, ...
                "Options", options.Options);
        end

        function handle = create_warning(options)
            window = Program.window;
        end

        function handle = create_error(options)
            window = Program.window;
        end
    end
end

