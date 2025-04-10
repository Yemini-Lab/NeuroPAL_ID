classdef image_editing_gui
    %IMAGE_MANIPULATION Class responsible for managing the image
    %   manipulation interface within the processing tab, as well as any
    %   helper functions that its child components rely upon.
    
    properties
        grid = [];      % Parent grid layout containing this panel.
        panels = [];    % Struct containing relevant child panels.
        buttons = [];   % Struct containing relevant child buttons.

        cache = [];     % Cache of original, unmanipulated image.
    end
    
    methods
        function obj = image_editing_gui()
            %IMAGE_MANIPULATION Constructs a persistent instance
            %   of the image manipulation panel.
            persistent panel_instance

            % If uninitiated...
            if isempty(panel_instance) || ~isgraphics(panel_instance.grid)
                % Get running app instance.
                app = Program.ProgramInfo.app;

                % Populate the persistent variable.
                panel_instance = obj;

                % Assign parent grid layout's GUI handle to
                % grid property.
                panel_instance.grid = app.ProcSideGrid;

                % Assign child panel GUI handles to panels
                % property.
                panel_instance.panels = struct( ...
                    'downsample', {app.proc_ds_panel}, ...
                    'rotate', {app.proc_rot_panel}, ...
                    'crop', {app.proc_crop_panel});

                % Assign child button GUI handles to buttons
                % property.
                panel_instance.buttons = struct( ...
                    'downsample', {app.DownsampleButton}, ...
                    'crop', {app.ProcCropImageButton}, ...
                    'rotate', {app.RotateButton});
            end

            % Return persistent instance.
            obj = panel_instance;
        end
        
        function obj = set_display_configuration(obj, mode)
            %SET_DISPLAY_CONFIGURATION Edits relevant grid layout
            %   to ensure layout serves the functionality the user
            %   is currently engaging with. For example, if we are working
            %   with a video, we display frame trimming components.
            %
            %   Inputs:
            %   - obj = image_editing_gui instance.
            %   - mode = string or char that is one of 'crop', 'rotate',
            %       or 'downsample', each representing one of the possible
            %       image editing operations.
            %
            %   Outputs:
            %   - obj = image_editing_gui instance.

            % If obj wasn't passed for some reason, grab the 
            % persistent instance.
            if ~exist('obj', 'var')
                obj = Program.GUI.Panels.image_manipulation();
            end

            % Render all child panels invisible.
            structfun(@(x)(set(x, 'Visible', 'off')), obj.panels);
            
            if strcmpi(mode, 'reset')
                % If we're resetting the display configuration, make
                % the crop, rotate, and downsample buttons visible.
                structfun(@(x)(set(x, 'Enable', 'on')), obj.buttons);

                % Set the main panel height back to its default.
                obj.set_panel_height(72);

            else
                % If we're switching to a particular interface,
                % disable the crop, rotate, and downsample buttons.
                structfun(@(x)(set(x, 'Enable', 'off')), obj.buttons);

                % Change the main panel height & child panel visibility
                % according to the mode requested.
                switch mode
                    case 'crop'
                        obj.set_panel_height(108);
                        obj.panels.crop.Visible = 'on';
    
                    case 'rotate'
                        obj.set_panel_height(200);
                        obj.panels.rotate.Visible = 'on';
    
                    case 'downsample'
                        if Program.ProgramInfo.is_video
                            obj.set_panel_height(192);
                        else
                            obj.set_panel_height(147);
                        end
    
                        obj.panels.downsample.Visible = 'on';
                end
            end
        end

        function obj = set_video_configuration(obj)
            %SET_VIDEO_CONFIGURATION Configure the GUI and its components
            %   properties such that users are able to edit videos.
            %
            %   Inputs:
            %   - obj: image_manipulation instance.
            %
            %   Outputs:
            %   - obj: image_manipulation instance.

            app = Program.ProgramInfo.app;

            row_height = app.ProcDownsamplingGrid.RowHeight;
            row_height{3} = 20;
            row_height{4} = 20;
            app.ProcDownsamplingGrid.RowHeight = row_height;

            sidebar = Program.GUI.Panels.preprocessing_sidebar();
            sidebar.toggle_spectral_unmixing(0);

            % Add a row to the parent grid to accommodate the time slider.
            obj.grid.RowHeight{end+1} = 'fit';

            % Move the timeline component into the new row.
            obj.video_only_components.timeline.Parent = obj.grid;
            obj.video_only_components.timeline.Layout.Row = length(obj.grid.RowHeight);
            obj.video_only_components.timeline.timeline.Layout.Column = length(obj.grid.ColumnWidth);

            % Render the timeline component visible.
            obj.video_only_components.timeline.timeline.Visible = 'on';

            % For every component whose callback edits video content...
            for n=1:length(obj.video_only_components)
                % Get the component.
                component = obj.video_only_components{n};
                
                % If the component can be enabled, enable it.
                if isprop(component, 'Enable')
                    component.Enable = 'on';
                end
                
                % If the component can be made visible, make it visible.
                if isprop(component, 'Visible')
                    component.Visible = 'on';
                end
            end

            % Get the persistent instance of the image manipulation panel.
            image_manipulation_panel = Program.GUI.Panels.image_manipulation();

            % Priompt the instance to switch to its video configuration.
            image_manipulation_panel.set_video_configuration();
        end

        function obj = save_array_to_cache(obj, array)
            %SAVE_ARRAY_TO_CACHE Saves a given array to the class cache
            %   property. This allows us to avoid reloading the current
            %   image from file should the user require consecutive 
            %   processing previews.
            %
            %   Input
            %   - obj: image_manipulation class instance
            %   - array: numerical array representing an image.
            %
            %   Output
            %   - obj: image_manipulation class instance

            obj.cache = array;
        end
    end

    methods (Access = private)
        function obj = set_panel_height(obj, height_in_pixels)
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
            row_height{3} = height_in_pixels;
            obj.grid.RowHeight = row_height;
        end

        function obj = delete(obj)
            clear persistent;
            clear java;
        end
    end
end

