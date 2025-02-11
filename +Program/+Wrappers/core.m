classdef core
    
    properties (Constant)
    end
    
    methods (Static, Access = public)
        function current_progress = progress(new_progress)
            persistent last_progress

            if nargin > 0
                last_progress = new_progress;
            end

            current_progress = last_progress;
        end

        function p_task = task(parent)
            persistent current_task

            if nargin > 0
                current_task = parent;
            end

            p_task = current_task;
        end

        function add_task(task)
            p_task = Program.Wrappers.core.task;
            n_task = sprintf("%s\n├🢒 %s...", p_task, task);
            Program.Wrappers.core.task(n_task);
        end

        function remove_task()
            p_task = Program.Wrappers.core.task;
            p_task = p_task.splitlines();
            subtask_indices = find(contains(p_task, '├🢒'));
            if ~isempty(subtask_indices)
                n_task = p_task(1:subtask_indices-1);
                Program.Wrappers.core.task(n_task);
            end
        end

        function current_state = state(new_state, new_progress)
            persistent last_state

            d = Program.Wrappers.core.progress();
            can_update = ~isempty(d);

            if exist('new_state', 'var') && ~isempty(new_state)
                last_state = new_state;

                if can_update
                    d.Message = sprintf("%s\n└🢒 %s...", ...
                        Program.Wrappers.core.task, last_state);
                end
            end

            if can_update
                if exist('new_progress', 'var') && new_progres ~= 0
                    if strcmp(d.Indeterminate, "off")
                        d.Indeterminate = "on";
                    end

                    d.Value = new_progress;
                else
                    d.Indeterminate = "on";
                end
            end

            current_state = last_state;
        end

        function run(operation, config)
            app = Program.app;

            d = uiprogressdlg(Program.window, ...
                "Message", "Sharing engine...", "Title", "NeuroPAL_ID", ...
                "Indeterminate", "on");
            Program.Wrappers.core.progress(d);

            if ~matlab.engine.isEngineShared
                matlab.engine.shareEngine('NeuroPAL');
            end

            stack = dbstack;
            last_func = string(stack(2).name).split('.');
            origin_wrapper = last_func(1);
            task_string = Program.Wrappers.(origin_wrapper).task_string{last_func(2)};
            Program.Wrappers.core.task(task_string);
            
            Program.Wrappers.core.state('Formulating command');
            arguments = sprintf(' --operation=%s_%s --config="%s"', ...
                origin_wrapper, operation, config);
            executable = fullfile(app.script_dir, sprintf('npal%s', app.script_ext));

            if ~isdeployed
                executable = sprintf('python %s', executable);
            end

            Program.Wrappers.core.state('Running command');
            disp([executable, arguments])
            [status, output] = system([executable, arguments]);
        end

        function signal(trigger)
            if exist(trigger, 'var')
                fprintf("Received data: %s", trigger)

            else
                if startsWith(trigger, "end_")
                    stack = trigger.split('_');
                    module = stack(2); func = stack(3:end);
                    Program.Wrappers.(module).aftercare(func);
                    Program.Wrappers.core.clean_up();

                else
                    fprintf("Received unknown signal: %s", trigger)
                end
            end
        end

        function clean_up()
            d = Program.Wrappers.core.progress;
            Program.Wrappers.core.progress([]);
            Program.Wrappers.core.state([]);
            Program.Wrappers.core.task([]);
            delete(d);
        end
    end
end

