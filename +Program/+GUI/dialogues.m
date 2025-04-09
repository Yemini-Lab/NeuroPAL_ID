classdef dialogues
    %DIALOGUES This class is in charge of coordinating progress dialogues
    % within NeuroPAL_ID and across wrapped python scripts.
    %
    %   Glossary:
    %   - Task: This describes an active operation as represented in the
    %       progress dialogue. Use this for any task that features several
    %       steps. The dialogues class supports multiple nested tasks. If
    %       you add a task while there is no active progress dialogue, one
    %       will be created.
    %   - Step: This describes a step within a tasks and are best used
    %       within iterative loops. Adding any task or step will clear the
    %       last step, and if you add a step while no progress dialogue is
    %       active, we do not create one.
    %   - Level filler: The progress dialogue system implemented through
    %       the dialogues class supports nesting, meaning that child tasks
    %       and steps are displayed as nested underneath their parent
    %       tasks. Throughout this class, we use "level filler" to describe
    %       the string that represents this nesting visually in the
    %       progress dialogue. Basically, if, while performing Task A, you
    %       start Task B, the progress dialogue would display as such:
    %       
    %       Task A
    %       └🢒 Task B
    %
    %       If you then add Another Task C underneath Task B, and then add
    %       a step D, it will display as such:
    %       
    %       Task A
    %       ├🢒 Task B
    %       ├─🢒 Task C
    %       └──🢒 { Step D }
    %
    %       Here, Task B has no level filler, while Task C's level filler
    %       is ─ and Step D's level filler is ──.
    
    properties (Constant)        
        % Text patterns used for sprintf() calls. The first %s describes
        % the nesting level of the given task/step, and the second %s
        % describes the task/step itself.
        patterns = struct( ...
            'task', {"└%s🢒 %s"}, ...
            'step', {"└%s{ %s }"});
        
        identifiers = struct( ...
            'task', {"🢒 "}, ...
            'step', {"{ "});
    end
    
    methods (Static, Access = public)
        function obj = active(input)
            %ACTIVE This function returns of the active dialogue if one
            % exists.
            %
            %   Inputs:
            %   - input: A handle referencing a uiprogressdlg instance.
            %
            %   Outputs:
            %   - obj: An active uiprogressdlg object. Empty if no progress
            %       dialogue is active.

            % Initialize a persistent variable.
            persistent handle

            % If a dialogue handle was passed...
            if nargin > 0
                % Assign it to the persistent variable.
                handle = input;
            end

            % If the persistent variable does not reference a uiprogressdlg
            % object or is not a valid graphical object, clear the
            % persistent variable. This is to ensure that references to
            % deleted graphics objects are detected and cleared.
            if (isa(handle, "handle") && any(~isvalid(handle)))
                handle = [];
            end

            % Return the persistent variable.
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
            %ADD_TASK This function adds a new task to the progress
            % dialogue.
            %
            %   Inputs:
            %   - label: String/char representing text describing the task.
            %       This is what will appear in the progress dialogue.
            %
            %   Outputs:
            %   - handle: A handle referencing the active progress
            %       dialogue.

            % Pass the label and task argument to update_message().
            handle = Program.GUI.dialogues.update_message(label, 'task');
        end

        function handle = step(label)
            %STEP This function adds a new step to the progress
            % dialogue.
            %
            %   Inputs:
            %   - label: String/char representing text describing the step.
            %       This is what will appear in the progress dialogue.
            %
            %   Outputs:
            %   - handle: A handle referencing the active progress
            %       dialogue.

            % Pass the label and step argument to update_message().
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
            %UPDATE_MESSAGE This function updates the active progress
            %   dialogue with a passed task or step. If no progress
            %   dialogue is active, this function calls the create()
            %   function instead.
            %
            %   Inputs:
            %   - addl: String/char to be added to the progress dialogue.
            %   - template: String/char specifying whether this is a task
            %       or a step.
            %
            %   Outputs:
            %   - handle: Reference to the active progress dialogue.

            % Get the active progress dialogue.
            handle = Program.GUI.dialogues.active();

            % Check whether an active progress dialogue was returned...
            if ~isempty(handle)

                % If so, split its current text into individual lines.
                arr_task = splitlines(handle.Message);

                % Calculate the current number of lines.
                n_tasks = length(arr_task);
        
                % If there is more than one line, update previous lines.
                if n_tasks > 1
                    % Get the last line in the progress dialogue message.
                    lline = arr_task{end};
        
                    if Program.GUI.dialogues.is_task(lline)
                        % If the last line was a task, update its string
                        % identifier to indicate that a nested operation is
                        % in progress.

                        % Split the last line at its identifier.
                        to_preserve = split(lline, "🢒");

                        % Calculate its level filler (i.e. one hyphen per
                        % nested task).
                        level_filler = repmat('─', 1, n_tasks-2);

                        % Construct the updated string.
                        arr_task{end} = sprintf("├%s🢒%s", ...
                            level_filler, to_preserve{2});

                    elseif Program.GUI.dialogues.is_step(lline)
                        % If the last line was a step, delete it.
                        arr_task(end) = [];

                        % Update the number of lines in the progress
                        % dialogue message accordingly.
                        n_tasks = n_tasks - 1;
                    end
                end
        
                % Construct the level filler.
                level_filler = repmat('─', 1, n_tasks-1);

                % Get the appropriate text pattern for this template.
                pattern = Program.GUI.dialogues.patterns.(template);

                % Construct the new line and append it to the existing
                % message.
                arr_task{end+1} = sprintf(pattern, level_filler, addl);
        
                % Update the progress dialogue's message property.
                handle.Message = sprintf(join(string(arr_task), '\n'));

            elseif strcmpi(template, 'task')
                % If no progress dialogue exists, create a new one and
                % initialize it with the passed task.
                handle = Program.GUI.dialogues.create('progress', ...
                    'Message', addl);
            end
        end

        function set_value(new_value)
            %SET_VALUE This function updates the value of the active
            % progress dialogue.
            %
            %   Inputs:
            %   - new_value: Non-negative numerical value to which the
            %       progress dialogue's "Value" property will be updated.

            % Get the active progress dialogue.
            handle = Program.GUI.dialogues.active();

            % Check whether an active progress dialogue was found...
            if ~isempty(handle)
                if strcmp(handle.Indeterminate, 'on')
                    % If a progress dialogue was found but it is currently
                    % set to indeterminate mode, change that.
                    handle.Indeterminate = 'off';

                elseif new_value == 1
                    % If a progress dialogue was found but the passed value
                    % is equal to 1 (suggesting a completed loop), switch
                    % it to indeterminate mode.
                    handle.Indeterminate = 'on';

                else
                    % If a progress dialogue was found and it is not
                    % indeterminate, update its "Value" property with our
                    % new value.
                    handle.Value = new_value;
                end
            end
        end

        function resolve()
            %RESOLVE This function completes the last task/step passed to
            % the progress dialogue.

            % Get the active progress dialogue.
            handle = Program.GUI.dialogues.active();

            % Check to ensure that this is a valid progress dialogue.
            if isa(handle, "matlab.ui.dialog.ProgressDialog")
                % If it is, split its message into a cell array.
                task_arr = splitlines( ...
                    Program.GUI.dialogues.clear_nlines(handle.Message));
    
                if length(task_arr) < 2
                    % If the line to be deleted is the only one left in the
                    % message, delete the progress dialogue.
                    delete(handle)

                elseif Program.GUI.dialogues.is_step(task_arr{end})
                    % If the last line was a step, delete it and then call
                    % resolve() again.

                    task_arr(end) = [];
                    handle.Message = sprintf(join(string(task_arr), '\n'));
                    Program.GUI.dialogues.resolve();
                    return
                
                else
                    % If the last line was a step, delete it and update the
                    % the level filler of any parent tasks.
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
            %CREATE This function creates a new dialogue with the passed
            % parameters.
            %
            %   Inputs:
            %   - mode: String/char describing the type of dialogue to be
            %       created. We currently only support "progress".
            %   - varargin: A variable-size cell array representing
            %       key/value input arguments to be parsed by an 
            %       inputParser object.

            % Create an inputParser.
            p = inputParser;

            % Define various optional arguments.
            addOptional(p, 'Message', '');                                  % This is the message our new dialogue will display. Empty by default.
            addOptional(p, 'Title', Program.ProgramInfo.window().Name);     % This is the title our new dialogue will use. Active window name by default.
            addOptional(p, 'Indeterminate', 'on');                          % This is a switch describing whether the new dialogue will have indeterminate progress ("on") or discrete progress ("off"). On by default.
            addOptional(p, 'Options', ["OK", "Cancel"])                     % The options to be passed to a hypothetical choice dialogue to be created.
            addOptional(p, 'Cancelable', 'off');                            % Whether the created dialogue can be canceled.
            
            % Parse the described optional arguments using our inputParser.
            parse(p, varargin{:});

            % Check which kind of dialogue should be created. We've only
            % implemented support for progress dialogues thus far.
            switch mode
                case 'instruction'
                    handle = Program.GUI.dialogues.create_instruction(p.Results);

                case 'progress'
                    % Call create_progress() and pass the parsed arguments.
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

            % Set the newly created dialogue to be the active dialogue.
            Program.GUI.dialogues.active(handle);
        end
    end

    methods (Static, Access = private)
        function bool = is_task(str)
            %IS_TASK This function checks whether a passed text matches
            % the pattern we use for tasks.
            %
            %   Inputs:
            %   - str: String/char.
            %
            %   Outputs:
            %   - bool: Boolean describing whether the input text describes
            %       a task or not. True if yes, false if no.

            % Get the identifiers property.
            identifiers = Program.GUI.dialogues.identifiers;

            % Check whether the passed text matches what we expect to find
            % in a task string.
            bool = contains(str, identifiers.task);
        end

        function bool = is_step(str)
            %IS_TASK This function checks whether a passed text matches
            % the pattern we use for steps.
            %
            %   Inputs:
            %   - str: String/char.
            %
            %   Outputs:
            %   - bool: Boolean describing whether the input text describes
            %       a step or not. True if yes, false if no.

            % Get the identifiers property.
            identifiers = Program.GUI.dialogues.identifiers;

            % Check whether the passed text matches what we expect to find
            % in a step string.
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
            %CLEAR_NLINES This function replaces all empty lines from a
            % passed text and replaces it with a newline character ("\n").
            % Having this function avoids repeating this boilerplate code
            % in various places, mostly because the "Message" property of
            % certain dialogue objects includes empty lines.
            %
            %   Inputs:
            %   - input: String/char to be filtered.
            %
            %   Outputs:
            %   - cleared_string: The filtered input string.

            % Split the input text into a cell array of individual lines.
            cleared_string = splitlines(input);

            % Remove all elements of the resulting cell array that are
            % empty.
            cleared_string = cleared_string(~cellfun('isempty', cleared_string));

            % Join the remaining elements with the newline character ("\n")
            % as delimiter.
            cleared_string = join(cleared_string, '\n');

            % Call sprintf on the joined text to parse these new lines.
            cleared_string = sprintf(cleared_string{1});
        end
    end
end
