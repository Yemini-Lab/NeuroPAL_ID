classdef loading
    %LOADING Summary of this class goes here
    %   Detailed explanation goes here
    
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

            else
                try
                    current_loading_label.Text = msg;
                end
            end
        end

        function done()
            app = Program.app;
            current_loading_label = Program.Handlers.loading.current();

            t = timer('TimerFcn', @(myTimerObj, thisEvent) Program.Handlers.loading.fade_label(myTimerObj, current_loading_label), ...
                      'Period', 0.005, ...
                      'ExecutionMode', 'fixedRate', ...
                      'TasksToExecute', 50);
            app.load_graphic.Visible = 'off';
            start(t);
        end
    end

    methods (Static, Access = private)
        function fade_label(t, hLabel)
            if ~isempty(hLabel)
                currentColor = hLabel.FontColor;
                newColor = min(currentColor + [0.02 0.02 0.02], [0.9 0.9 0.9]);
                hLabel.FontColor = newColor;
            
                if all(newColor == [0.9 0.9 0.9])
                    delete(hLabel);
                    stop(t);
                    delete(t);
                    Program.Handlers.loading.current([]);
                end
            end
        end
    end
end

