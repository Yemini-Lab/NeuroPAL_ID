classdef dialogues
    
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
            handle = Program.GUI.dialogues.update_message(label, 'task');
        end

        function handle = step(label)
            handle = Program.GUI.dialogues.update_message(label, 'step');
        end

        function handle = choice(message, choices)
            handle = Program.GUI.dialogues.active();
            if ~isempty(handle)
                options = struct( ...
                    'Message', {message}, ...
                    'Options', {choices});
                Program.GUI.dialogues.switch_to('choice', options);

            else
                handle = Program.GUI.dialogues.create('choice', 'Message', message, 'Options', choices);

            end
        end

        function switch_to(mode, options)
            handle = Program.GUI.dialogues.active();
            cache_props = properties(handle);

            for p=1:length(cache_props)
                prop = cache_props{p};
                if exist('cache', 'var')
                    cache.(prop) = handle.(cache_props{p});

                else
                    cache = struct(prop, {handle.(cache_props{p})});

                end
            end

            Program.GUI.dialogues.cache(cache);
            delete(handle);
            Program.GUI.dialogues.create(mode, options);
        end

        function handle = update_message(addl, template)
            handle = Program.GUI.dialogues.active();

            if ~isempty(handle)
                arr_task = splitlines(handle.Message);
                n_tasks = length(arr_task);
        
                if n_tasks > 1
                    lline = arr_task{end};
        
                    if Program.GUI.dialogues.is_task(lline)
                        to_preserve = split(lline, "🢒");
                        level_filler = repmat('─', 1, n_tasks-2);
                        arr_task{end} = sprintf("├%s🢒%s", ...
                            level_filler, to_preserve{2});

                    elseif Program.GUI.dialogues.is_step(lline)
                        arr_task(end) = [];
                        n_tasks = n_tasks - 1;
                    end
                end
        
                level_filler = repmat('─', 1, n_tasks-1);
                pattern = Program.GUI.dialogues.patterns.(template);
                arr_task{end+1} = sprintf(pattern, level_filler, addl);
        
                handle.Message = sprintf(join(string(arr_task), '\n'));

            elseif strcmpi(template, 'task')
                handle = Program.GUI.dialogues.create('progress', ...
                    'Message', addl);
            end
        end

        function set_value(new_value)
            handle = Program.GUI.dialogues.active();
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
            handle = Program.GUI.dialogues.active();

            if isa(handle, "matlab.ui.dialog.ProgressDialog")
                task_arr = splitlines(Program.GUI.dialogues.clear_nlines(handle.Message));
    
                if length(task_arr) < 2
                    delete(handle)

                elseif Program.GUI.dialogues.is_step(task_arr{end})
                    task_arr(end) = [];
                    handle.Message = sprintf(join(string(task_arr), '\n'));
                    Program.GUI.dialogues.resolve();
                    return
                
                else
                    task_arr{end-1} = strrep(task_arr{end-1}, '├', '└');
                    new_message = join(task_arr(1:end-1), '\n');
                    handle.Message = sprintf(new_message{1});
                end

            else
                cache = Program.GUI.dialogues.cache;

                if ~isempty(cache)
                   delete(handle)
                   Program.GUI.dialogues.create('progress', cache);
                end
            end
        end
        
        function handle = create(mode, varargin)            
            p = inputParser;
            addOptional(p, 'Message', '');
            addOptional(p, 'Title', Program.ProgramInfo.window().Name);
            addOptional(p, 'Indeterminate', 'on');
            addOptional(p, 'Options', ["OK", "Cancel"])
            addOptional(p, 'Cancelable', 'off');
            parse(p, varargin{:});

            switch mode
                case 'instruction'
                    handle = Program.GUI.dialogues.create_instruction(p.Results);

                case 'progress'
                    handle = Program.GUI.dialogues.create_progress(p.Results);

                case 'choice'
                    handle = Program.GUI.dialogues.create_choice(p.Results);

                case 'warning'
                    handle = Program.GUI.dialogues.create_warning(p.Results);

                case 'error'
                    handle = Program.GUI.dialogues.create_error(p.Results);

                otherwise
                    handle = [];
                    return
            end

            Program.GUI.dialogues.active(handle);
        end
    end

    methods (Static, Access = private)
        function bool = is_task(str)
            identifiers = Program.GUI.dialogues.identifiers;
            bool = contains(str, identifiers.task);
        end

        function bool = is_step(str)
            identifiers = Program.GUI.dialogues.identifiers;
            bool = contains(str, identifiers.step);
        end

        function handle = create_progress(options)
            window = Program.ProgramInfo.window;
            handle = uiprogressdlg(window, ...
                "Message", options.Message, ...
                "Title", options.Title, ...
                "Indeterminate", options.Indeterminate, ...
                "Cancelable", options.Cancelable);
        end

        function handle = create_choice(options)
            window = Program.ProgramInfo.window;
            handle = uiconfirm(window, ...
                options.Message, ...
                options.Title, ...
                "Options", options.Options);
        end

        function cleared_string = clear_nlines(input)
            cleared_string = splitlines(input);
            cleared_string = cleared_string(~cellfun('isempty', cleared_string));
            cleared_string = join(cleared_string, '\n');
            cleared_string = sprintf(cleared_string{1});
        end
    end
end
