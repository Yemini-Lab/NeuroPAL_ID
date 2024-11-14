classdef mouse < dynamicprops
    %MOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pos;
        state;
    end
    
    methods (Static)
        function initialize()
            % Initialize the mouse click states (a hack to detect double clicks).
            % Note: initialization is performed by startupFcn due construction issues.

            app = Program.GUI.app;
            app.mouse_clicked.double_click_delay = 0.3;
            app.mouse_clicked.click = false;
        end
        
        function restore_cursor()
            %% Restore the mouse pointer.
            % Hack: Matlab App Designer!!!
            js_code = ['var elementToChange = document.getElementsByTagName("body")[0];' ...
                'elementToChange.style.cursor = "url(''cursor:default''), auto";'];
            hWin = mlapptools.getWebWindow(Program.GUI.window);
            hWin.executeJS(js_code);
        end

        function mouse_poll(click_state)
            app = Program.GUI.app;
            window = Program.GUI.window;
            
            app.mouse.pos = get(window, 'CurrentPoint');
            clicked = exist('click_state', 'var');

            if clicked
                app.mouse.state = click_state;
                app.mouse.drag = struct( ...
                    'origin', {app.mouse.pos}, ...
                    'delta', {[0 0]}, ...
                    'debt', {[0 0]});

            elseif app.mouse.state
                app.mouse.drag.delta = app.mouse.pos - app.mouse.drag.origin + app.mouse.drag.debt;
                app.mouse.drag.debt = app.mouse.drag.debt - app.mouse.drag.delta;

            elseif ~isempty(app.mouse.drag)
                app.mouse.drag.debt = [0 0];
            end
        end
    end
end

