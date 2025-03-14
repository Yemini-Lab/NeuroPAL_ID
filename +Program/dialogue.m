classdef dialogue
    
    properties (Constant)
        identifiers = struct( ...
            'task', {"🢒 "}, ...
            'step', {"{ "});
        
        patterns = struct( ...
            'task', {"└%s🢒 %s"}, ...
            'step', {"└%s{ %s }"});
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

        function handle = add_task(label)
            handle = Program.Handlers.dialogue.update_message(label, 'task');
        end

        function handle = step(label)
            handle = Program.Handlers.dialogue.update_message(label, 'step');
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

        function handle = update_message(addl, template)
            handle = Program.Handlers.dialogue.active();

            if ~isempty(handle)
                arr_task = splitlines(handle.Message);
                n_tasks = length(arr_task);
        
                if n_tasks > 1
                    lline = arr_task{end};
        
                    if Program.Handlers.dialogue.is_task(lline)
                        to_preserve = split(lline, "🢒");
                        level_filler = repmat('─', 1, n_tasks-2);
                        arr_task{end} = sprintf("├%s🢒%s", ...
                            level_filler, to_preserve{2});

                    elseif Program.Handlers.dialogue.is_step(lline)
                        arr_task(end) = [];
                        n_tasks = n_tasks - 1;
                    end
                end
        
                level_filler = repmat('─', 1, n_tasks-1);
                pattern = Program.Handlers.dialogue.patterns.(template);
                arr_task{end+1} = sprintf(pattern, level_filler, addl);
        
                handle.Message = sprintf(join(string(arr_task), '\n'));

            elseif strcmpi(template, 'task')
                handle = Program.Handlers.dialogue.create('progress', ...
                    'Message', addl);
            end
        end

        function set_value(new_value)
            handle = Program.Handlers.dialogue.active();
            if ~isempty(handle)
                if strcmp(handle.Indeterminate, 'on')
                    handle.Indeterminate = 'off';
                elseif new_value == 1
                    handle.Indeterminate = 'on';
                else
                    handle.Value = new_value;
                end
            end
        end

        function resolve()
            handle = Program.Handlers.dialogue.active();

            if isa(handle, "matlab.ui.dialog.ProgressDialog")
                task_arr = splitlines(Program.Validation.clear_nlines(handle.Message));
    
                if length(task_arr) < 2
                    delete(handle)

                elseif Program.Handlers.dialogue.is_step(task_arr{end})
                    task_arr(end) = [];
                    handle.Message = sprintf(join(string(task_arr), '\n'));
                    Program.Handlers.dialogue.resolve();
                    return
                
                else
                    task_arr{end-1} = strrep(task_arr{end-1}, '├', '└');
                    new_message = join(task_arr(1:end-1), '\n');
                    handle.Message = sprintf(new_message{1});
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
            addOptional(p, 'Title', Program.window().Name);
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
        function bool = is_task(str)
            identifiers = Program.Handlers.dialogue.identifiers;
            bool = contains(str, identifiers.task);
        end

        function bool = is_step(str)
            identifiers = Program.Handlers.dialogue.identifiers;
            bool = contains(str, identifiers.step);
        end

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

