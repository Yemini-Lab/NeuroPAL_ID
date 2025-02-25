classdef states < dynamicprops
    
    properties
        active_tasks = {};
        active_dlg = [];
        interface = [];

        loaded_volumes = {};
        active_volume = [];

        mip = 0;

        has_neurons = 0;
        has_activity = 0;

        reload_on_swap = 0;
        is_loading_file = 0;

        debug_mode = 0;
    end
    
    methods (Access = public)        
        function obj = states(overwrite)
            persistent state_obj

            if nargin ~= 0
                state_obj = overwrite;
            elseif isempty(state_obj)
                obj.initialize();
                state_obj = obj;
            end

            obj = state_obj;
        end
    end

    methods (Access = private)
        function obj = initialize(obj)
            app = Program.app;
            if ~isempty(app) && isgraphics(app)
                obj.interface = app.TabGroup.SelectedTab;
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
            have_open_dlg = ~isempty(obj.active_dlg) && isgraphics(obj.active_dlg);
            
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
            end

            obj.set('current_task', msg);
        end

        function progress(varargin)
            obj = Program.states;
            switch nargin
                case 0
                    obj.active_tasks{end}.now = obj.active_tasks{end}.now + ...
                        obj.active_tasks{end}.steps;

                case 1
                    if varargin{1} == obj.active_tasks{end}.max
                        obj.active_tasks{end} = [];
                    else
                        obj.active_tasks{end}.now = varargin{1};
                    end

                case 2
                    if strcmp(varargin{1}, 'start')
                        if isempty(obj.active_tasks)
                            max = varargin{2};
                            steps = 1;
                        else
                            max = 1;
                            steps = obj.active_tasks{end}.steps/varargin{2};
                        end

                        obj.active_tasks{end+1} = struct( ...
                            'label', {sprintf('%s...', obj.current_task)}, ...
                            'max', {max}, ...
                            'steps', {steps}, ...
                            'now', {0});
                    end
            end

            obj.draw_progress();
        end
    end
end

