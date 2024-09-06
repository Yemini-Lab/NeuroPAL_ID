classdef RenderEngine
    % Functions responsible for rendering volumes.

    %% Public variables.
    properties (Constant, Access = public)
    end

    methods (Static)

        function restore_pointer(app)
            % Restore the mouse pointer.
            js_code = ['var elementToChange = document.getElementsByTagName("body")[0];' ...
                'elementToChange.style.cursor = "url(''cursor:default''), auto";'];
            hWin = mlapptools.getWebWindow(app.CELL_ID);
            hWin.executeJS(js_code);
        end

        function send_focus(ui_element)
            % Send focus to a UI element.
            focus(ui_element);
        end
    end
end