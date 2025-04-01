classdef preprocessing_sidebar
    %PREPROCESSING_SIDE_PANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        grid = [];                                                          % Parent grid layout containing this panel.
        panels = [];                                                        % Struct whose every field represents one child panel.                
    end
    
    methods (Access = public)
        function obj = preprocessing_sidebar()
            %preprocessing_sidebar Constructs a persistent instance
            %   of the preprocessing sidebar.
            persistent sidebar_instance

            % If uninitiated...
            if isempty(sidebar_instance)
                % Get running app instance.
                app = Program.app;

                % Populate the persistent variable.
                sidebar_instance = obj;

                % Assign parent grid layout's GUI handle to
                % grid property.
                sidebar_instance.grid = app.ProcSideGrid;

                % Assign every child panel component to its appropriate 
                % field in the panels property.
                sidebar_instance.panels = struct( ...
                    'toggle_volume', {app.ProcToggleVolumePanel}, ...       % The panel featuring the volume type (ie. image or video) selection.
                    'volume_channels', {app.VolumeChannelsPanel}, ...       % The panel featuring image or video channels.
                    'image_manipulation', {app.ImageManipulationPanel}, ... % The panel featuring image manipulation options (e.g. crop, rotate, downsample).
                    'spectral_unmixing', {app.SpectralUnmixingPanel}, ...   % The panel featuring the spectral unmixing interface.
                    'save_or_reset', {app.ProcSavePanel});                  % The panel featuring the save and reset buttons.
            end

            % Return persistent instance.
            obj = sidebar_instance;
        end
    end

    methods (Static, Access = public)        
        function toggle_spectral_unmixing(obj)
            if nargin == 0
                obj = Program.GUI.Panels.preprocessing_sidebar();
            end

            row_index = obj.panels.spectral_unmixing.Layout.Row;

            is_currently_visible = strcmpi( ...
                obj.panels.spectral_unmixing.Visible, 'on');

            if is_currently_visible
                row_height = 0;
                obj.panels.spectral_unmixing.Visible = 'off';
            else
                row_height = 212;
                obj.panels.spectral_unmixing.Visible = 'on';
            end

            obj.set_row_height(row_index, row_height);
        end
    end

    methods (Access = private)
        function set_row_height(obj, index, height_in_pixels)
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

            row_height = obj.grid.RowHeight;
            row_height{index} = height_in_pixels;
            obj.grid.RowHeight = row_height;
        end
    end
end

