classdef preprocessing_sidebar
    %PREPROCESSING_SIDEBAR Class responsible for managing the side bar
    %   within the processing tab.
    
    properties
        grid = [];                                                          % Parent grid layout containing this panel.
        panels = [];                                                        % Struct whose every field represents one child panel.
        panel_instances = [];                                               % Struct whose fields correspond to each panel's persistent instance.
    end
    
    methods (Access = public)
        function obj = preprocessing_sidebar()
            %preprocessing_sidebar Constructs a persistent instance
            %   of the preprocessing sidebar.
            persistent sidebar_instance

            % If uninitialized...
            if isempty(sidebar_instance)
                % Get running app instance.
                app = Program.ProgramInfo.app;

                % Populate the persistent variable.
                sidebar_instance = obj;

                % Assign parent grid layout's GUI handle to
                % grid property.
                sidebar_instance.grid = app.ProcSideGrid;

                % Assign every child panel component to its appropriate 
                % field in the panels property.
                sidebar_instance.panels = struct( ...
                    'toggle_volume', {app.ProcToggleVolumePanel}, ...       % The panel featuring the volume type (ie. image or video) selection.
                    'volume_channels', {app.ProcToggleChannelsPanel}, ...       % The panel featuring image or video channels.
                    'image_manipulation', {app.ImageManipulationPanel}, ... % The panel featuring image manipulation options (e.g. crop, rotate, downsample).
                    'spectral_unmixing', {app.SpectralUnmixingPanel}, ...   % The panel featuring the spectral unmixing interface.
                    'save_or_reset', {app.ProcSavePanel});                  % The panel featuring the save and reset buttons.

                % Instantiate the persistent instance of every relevant
                % panel class.
                sidebar_instance.panel_instances = struct( ...
                    'image_manipulation', {Program.GUI.Panels.image_editing_gui()});
            end

            % Return persistent instance.
            obj = sidebar_instance;
        end

        function obj = set_gui_configuration(obj, type)
            %SET_GUI_CONFIGURATION Configures all child GUI components to
            %   ensure that only those relevant to the selected volume type
            %   (i.e. image or video) are accessible.

            % Ensure the relevant components have been initialized.
            obj.ensure_components_have_been_initialized(type);

            % Check whether we are dealing with an image, and if so, enable
            % the spectral unmixing interface.
            allow_spectral_unmixing = strcmpi(type, 'image');
            obj.toggle_spectral_unmixing(allow_spectral_unmixing);

            % Propagate the configuration call throughout all child
            % instances. We delegate updating their child components to
            % them to ensure modularity.
            obj.panel_instances.image_manipulation.set_gui_configuration(type);
        end
    end

    methods (Static, Access = public)
        function toggle_spectral_unmixing(obj, desired_visibility)
            %TOGGLE_SPECTRAL_UNMIXING Renders the spectral unmixing panel
            %   either visible or invisible. If no desired visibility is
            %   passed, then we determine & invert the current visibility
            %   setting.
            %
            %   Inputs:
            %   - obj: preprocessing_sidebar instance.
            %   - desired_visibility: boolean representing whether the
            %       panel should be visible (true) or invisible (false).

            % If no input arguments were passed...
            if nargin == 0
                % Get persistent sidebar instance.
                obj = Program.GUI.Panels.preprocessing_sidebar();

                % Check whether the spectral unmixing panel is visible.
                current_visibility = strcmpi( ...
                    obj.panels.spectral_unmixing.Visible, 'on');

                % Set the desired visibility to the inverse of the current 
                % visibility setting.
                desired_visibility = ~current_visibility;
            end

            % Get the current row of the spectral unmixing panel in its
            % parent grid layout.
            row_index = obj.panels.spectral_unmixing.Layout.Row;

            % Set the new row height in accordance with whether we will
            % display the panel or not.
            if desired_visibility
                obj.set_row_height(row_index, 212);
            else
                obj.set_row_height(row_index, 0);
            end

            % Update the GUI component's visibility property.
            obj.panels.spectral_unmixing.Visible = desired_visibility;
        end
    end

    methods (Access = private)
        function obj = set_row_height(obj, index, height_in_pixels)
            %SET_PANEL_HEIGHT Configures the row height of the
            %   row featuring the image manipulation panel in
            %   its parent grid layout.
            %
            %   Input
            %   - obj: image_manipulation class instance
            %   - height_in_pixels: integer to which the panel height is
            %       to be set.
            %
            %   Output
            %   - obj: image_manipulation class instance

            % Note that we can't assign the updated height directly matlab
            % will fail to save our change under certain conditions.
            % Mathworks has been notified of this issue.
            row_height = obj.grid.RowHeight;
            row_height{index} = height_in_pixels;
            obj.grid.RowHeight = row_height;
        end

        function obj = ensure_components_have_been_initialized(obj, mode)
            %ENSURE_MODE_IS_SUPPORTED Check to make sure that this
            %   particular type of volume (i.e. image or video) has 
            %   previously been loaded and its relevant components
            %   properly initialized.

            % Grab running app instance.
            app = Program.ProgramInfo.app;

            % Depending on whether we are dealing with an image or a video,
            % we'll be checking for a different dropdown item.
            switch mode
                case 'image'
                    % For images, the item is "Colorstack".
                    dropdown_item = 'Colorstack';
                case 'video'
                    % For videos, the item is "Video".
                    dropdown_item = 'Video';
                otherwise
                    % We don't expect any others.
                    error("Unknown volume type: %s", mode);
            end
                
            % If the appropriate dropdown item is not present in the
            % volume dropdown, add it. This also lets us know that
            % relevant components have not been initialized.
            if ~ismember(app.VolumeDropDown.Items, dropdown_item)
                app.VolumeDropDown.Items{end+1} = dropdown_items;
            end
        end
    end
end

