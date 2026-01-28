classdef loading
    
    properties
    end
    
    methods (Static, Access = public)
        function obj = current(new_loading_label)
            persistent current_loading_label

            if nargin > 0
                current_loading_label = new_loading_label;
            end

            obj = current_loading_label;
        end

        function hLabel = start(msg)
            if nargin < 1
                msg = 'Loading...';
            end

            current_loading_label = Program.Handlers.loading.current();

            if isempty(current_loading_label)
                app = Program.app;
                tr_corner = app.CELL_ID.Position(3);
                label_position = [tr_corner-525, app.TabGroup.Position(4)-23, 500, 23];
    
                hLabel = uilabel('Parent', app.CELL_ID, ...
                    'Text', msg, ...
                    'Position', label_position, ...
                    'FontColor', [0 0 0], 'HorizontalAlignment', 'right');

                app.load_graphic.Position(1) = tr_corner - 20;
                app.load_graphic.Position(2) = label_position(2) + 3;
                app.load_graphic.Visible = 'on';
    
                Program.Handlers.loading.current(hLabel);
                drawnow;

            elseif isprop(current_loading_label, 'Text')
                current_loading_label.Text = msg;
            end
        end

        function done()
            app = Program.app;
            current_loading_label = Program.Handlers.loading.current();

            t = timer('TimerFcn', @(time_obj, this_event) Program.Handlers.loading.fade_label(time_obj, current_loading_label), ...
                      'Period', 0.005, ...
                      'TasksToExecute', 50, ...
                      'ExecutionMode', 'fixedRate');

            app.load_graphic.Visible = 'off';
            start(t);
        end
    end

    methods (Static, Access = private)
        function fade_label(t, hLabel)
            if isempty(hLabel) || ~isvalid(hLabel)
                if isvalid(t)
                    stop(t);
                    delete(t);
                end
                Program.Handlers.loading.current([]);
                return
            end

            currentColor = hLabel.FontColor;
            newColor = min(currentColor + [0.02 0.02 0.02], [0.9 0.9 0.9]);
        
            if all(newColor == [0.9 0.9 0.9])
                if isvalid(t)
                    stop(t);
                    delete(t);
                end
                delete(hLabel);
                Program.Handlers.loading.current([]);

            else
                hLabel.FontColor = newColor;
            end
        end
    end
end
