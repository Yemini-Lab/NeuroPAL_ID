classdef states < dynamicprops
    
    properties
        active_tasks = {};
        active_dlg = [];
        
        projection = 'z';
        interface = [];

        loaded_volumes = {};
        active_volume = [];

        mip = 0;

        has_neurons = 0;
        has_activity = 0;

        reload_on_swap = 0;
        is_loading_file = 0;

        debug_mode = 0;
        child_symbols = {'└🢒', '├🢒', '└─{'};
    end
    
    methods (Access = public)        
        function obj = states(overwrite)
            persistent state_obj

            if nargin ~= 0
                state_obj = overwrite;
            elseif isempty(state_obj)
                obj.initialize();
                state_obj = obj;
            elseif isempty(state_obj.interface)
                state_obj.interface = Program.GUI.Parse.interface();
            end

            obj = state_obj;
        end
    end 

    methods (Access = private)
        function obj = initialize(obj)
            app = Program.app;
            if ~isempty(app) && isgraphics(app)
                obj.mip = 0;
                obj.interface = Program.GUI.Parse.interface();
            end
        end

        function obj = set_prop(obj, keyword, value)
            if ~isprop(obj, keyword)
                addprop(obj, keyword);
            end

            obj.(keyword) = value;
        end

        function value = get_prop(obj, keyword)
            if isprop(obj, keyword)
                value = obj.(keyword);
            else
                value = 0;
            end
        end

        function obj = clear_prop(obj, keyword)
            deleteproperty(obj, keyword);
        end    

        function obj = draw_progress(obj)
            have_active_tasks = ~isempty(obj.active_tasks);
            have_open_dlg = ~isempty(obj.active_dlg);
            
            if have_active_tasks
                active_task = obj.active_tasks{end};

                if ~have_open_dlg
                    obj.active_dlg = uiprogressdlg(Program.window, ...
                        "Message", active_task.label, ...
                        "Title", "NeuroPAL_ID", ...
                        "Indeterminate", "off");
                end

                obj.active_dlg.Message = active_task.label;
                obj.active_dlg.Value = min(1, ...
                    active_task.now/active_task.max);

            else
                if have_open_dlg
                    delete(obj.active_dlg);
                    obj.active_dlg = [];
                end
            end
        end
    end

    methods (Static, Access = public)
        function toggle(keyword)
            obj = Program.states;
            value = obj.(keyword);
            if islogical(value)
                obj.(keyword) = ~value;
            end
        end

        function set(keyword, value)
            obj = Program.states;
            obj.set_prop(keyword, value);
        end

        function value = get(keyword)
            obj = Program.states;
            value = obj.get_prop(keyword);
        end

        function clear(keyword)
            obj = Program.states;
            deleteproperty(obj, keyword);
        end    

        function now(msg, varargin)
            if ~isempty(varargin)
                msg = sprintf(msg, varargin{:});
            end

            obj = Program.states;
            if obj.debug_mode
                disp(msg);
                Program.Handlers.loading.start(msg);
            end

            obj.set('current_task', msg);
        end

        function done()
            obj = Program.states;
            delete(obj.active_dlg);
            obj.active_dlg = [];
        end

        function progress(varargin)
            obj = Program.states;
            
            if nargin == 0
                obj.active_tasks{end}.now = obj.active_tasks{end}.now + ...
                    obj.active_tasks{end}.steps;

            elseif nargin == 1
                if varargin{1} == obj.active_tasks{end}.max
                    obj.active_tasks{end} = [];
                else
                    obj.active_tasks{end}.now = varargin{1};
                end

            else                
                if isempty(obj.active_tasks)
                    label = sprintf('%s...', obj.current_task);
                    cap = varargin{2};
                    steps = 1;
                    now = 0;
                else
                    previous_task = obj.active_tasks{end};
                    label = sprintf('%s\n%s %s...', ...
                        previous_task.label, ...
                        obj.child_symbols{ ...
                        min(3, length(obj.active_tasks))}, ...
                        obj.current_task);
                    cap = previous_task.now + previous_task.steps;
                    steps = previous_task.steps/varargin{2};
                    now = previous_task.now;
                end

                obj.active_tasks{end+1} = struct( ...
                    'label', {label}, ...
                    'max', {cap}, ...
                    'steps', {steps}, ...
                    'now', {now});
            end

            obj.draw_progress();
        end
    end
end

