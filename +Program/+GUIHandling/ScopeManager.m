classdef ScopeManager
    % Functions responsible for managing transfers between scopes.

    %% Public variables.
    properties (Constant, Access = public)
    end

    methods (Static)

        function app = get_parent_app(component)
            % Get the application a given component belongs to.

            if ~isempty(component)
                if any(ismember(properties(component), 'RunningAppInstance'))
                    app = component.RunningAppInstance;
                else
                    app = Program.GUIHandling.get_parent_app(component.Parent);
                end
            else
                app = [];
            end
        end

        function output = get_child_properties(component, property)
            % Get the value of the given property for all children of a component.
            output = struct();

            for comp=1:length(component.Children)
                child = component.Children(comp);

                if any(ismember(properties(child), char(property)))
                    output.(child.Tag) = child.(property);
                end
            end
        end

        function package = global_grab(window, var)
            % Fulfills requests for local variables across AppDesigner apps.

            global_figures = findall(groot, 'Type','figure');
            scope = Program.GUIHandling.get_parent_app(global_figures(strcmp({global_figures.Name}, window)));

            if ~isempty(scope)
                package = scope.(var);
            else
                package = [];
            end
        end

        function sync_component_handles(app)
            % Ensures AppDesigner GUI handles are synced across local scripts.

            if ~isdeployed
                % TBD
            else
                handles = Program.GUIHandling.cache('load', 'component_handles');
            end
        end
    end
end