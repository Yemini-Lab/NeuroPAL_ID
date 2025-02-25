classdef build < handle
    %BUILD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        custom_button = dictionary();
        custom_colorpicker = dictionary();
        custom_dropdown = dictionary();
        custom_editfield = dictionary();
        custom_checkbox = dictionary();
    end

    methods (Static, Access = public)
        function obj = button(varargin)
            tcomp = 'button';
            recipe = Program.GUI.build.get_recipe(tcomp, varargin);
            obj = uibutton(recipe{:});
            Program.GUI.build.register_dynamic_component(obj);
        end

        function obj = colorpicker(varargin)
            tcomp = 'colorpicker';
            recipe = Program.GUI.build.get_recipe(tcomp, varargin);
            obj = uicolorpicker(recipe{:});
            Program.GUI.build.register_dynamic_component(obj);
        end

        function obj = dropdown(varargin)
            tcomp = 'dropdown';
            recipe = Program.GUI.build.get_recipe(tcomp, varargin);
            obj = uidropdown(recipe{:});
            Program.GUI.build.register_dynamic_component(obj);
        end

        function obj = editfield(varargin)
            tcomp = 'editfield';
            recipe = Program.GUI.build.get_recipe(tcomp, varargin);
            obj = uieditfield(recipe{:});
            Program.GUI.build.register_dynamic_component(obj);
        end

        function obj = checkbox(varargin)
            tcomp = 'checkbox';
            recipe = Program.GUI.build.get_recipe(tcomp, varargin);
            obj = uicheckbox(recipe{:});
            Program.GUI.build.register_dynamic_component(obj);
        end
    end

    methods (Static, Access = private)
        function handles = dynamic_components(new)
            persistent known_dynamic_components

            if nargin ~= 0
                known_dynamic_components = new;
            end

            handles = known_dynamic_components;
        end

        function register_dynamic_component(obj)
            registry = Program.GUI.build.dynamic_components;
            registry{end+1} = obj;
            Program.GUI.build.dynamic_components(registry);
        end

        function recipe = get_recipe(tcomp, varargin)
            constructor = Program.GUI.build;
            if isConfigured(constructor.(sprintf('custom_%s', tcomp)))
                p = constructor.parse_defaults(tcomp);
                parse(p, parent, varargin{:});
                recipe = p.Results;
            else
                recipe = varargin;
            end

            recipe = recipe{:};
        end

        function p = parse_defaults(tclass)
            p = inputParser();
            custom_defaults = Program.GUI.build.(sprintf('custom_%s', tclass));

            switch tclass
                case 'button'
                    c_meta = ?matlab.ui.control.Button;
                case 'colorpicker'
                    c_meta = ?matlab.ui.control.ColorPicker;
                case 'dropdown'
                    c_meta = ?matlab.ui.control.DropDown;
                case 'checkbox'
                    c_meta = ?matlab.ui.control.CheckBox;
            end

            c_proplist = c_meta.PropertyList;
            for cp=1:length(c_proplist)
                c_prop = c_proplist(cp);
                if ismember(c_prop.Name, keys(custom_defaults))
                    addParameter(p, c_prop.Name, custom_defaults{c_prop.Name});
                elseif c_prop.HasDefault
                    addParameter(p, c_prop.Name, c_prop.DefaultValue)
                end
            end
        end
    end

    methods (Access = private)
        function delete_dynamic_component(varargin)
            p = inputParser();
            addParameter(p, 'Name', '');
            addParameter(p, 'class', [])
            addParameter(p, 'Value', []);
            addParameter(p, 'Parent', []);
            addParameter(p, 'Tag', '');
            parse(p, cmd, varargin{:});

            fun = @(s) all(structfun(@isempty, s));
            idx = arrayfun(fun, Charge);
            query = p.Results(~idx);
            filters = fieldnames(query);

            registry = Program.GUI.build.dynamic_components;
            for n=length(registry):-1:1
                should_delete = 0;
                component = registry{n};

                if ~isempty(query.class)
                    if ~isa(component, query.class)
                        continue
                    else
                        should_delete = isscalar(filters);
                    end
                end

                for p=1:length(filters)
                    this_filter = filters{p};

                    if isprop(component, this_filter)
                        this_value = component.(this_filter);
                        if isnumeric(this_value)
                            should_delete = this_value ~= query.(this_filter);
                        else
                            should_delete = strcmp(this_value, query.(this_filter));
                        end
                    end

                    if should_delete
                        delete(component);
                        registry = registry(~ismember(registry, component));
                    end
                end
            end
        end
    end
end

