classdef tracking_gui
    %TRACKING_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = tracking_gui(path)
            %TRACKING_GUI Constructs a persistent instance of the tracking
            % gui.
            %
            %   Inputs:
            %   - path (Optional): string/char representing the path of
            %       a file to be loaded into the gui.
            %
            %   Outputs:
            %   - obj: tracking_gui instance.

            % Initialize a persistent variable which will reference our
            % sole instance of this object.
            persistent gui_instance

            % If uninitialized...
            if isempty(gui_instance)
                % Update persistent instance with constructed object.
                gui_instance = obj;

                % Create an instance of the neuron_gui class and assign
                % it to the neuron_gui property.
                gui_instance.neuron_gui = Program.GUI.neuron_gui( ...
                    gui_instance);
            end

            % If a path was passed...
            if nargin ~= 0
                gui_instance.open_file(path);
            end

            % Return the persistent instance.
            obj = gui_instance;
        end
    end

    methods (Static, Access = public)
        function enable_gui()
            %ENABLE_GUI Renders tracking tab visible and enables its
            % various gui components.
            %
            %   Inputs:
            %   - obj: tracking_gui instance.

            % Get the running app instance.
            app = Program.ProgramInfo.app;

            % Disable the load video button.
            app.TrackingButton.Enable = 'off';
            app.TrackingButton.Visible = 'off';

            % Ensure the video grid layout is visible.
            set(app.VideoGridLayout, 'Visible', 'on');

            % Switch to the video tab.
            app.TabGroup.SelectedTab = app.VideoTrackingTab;
        end
    end
end

