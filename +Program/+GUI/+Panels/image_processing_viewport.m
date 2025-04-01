classdef image_processing_viewport
    %IMAGE_PROCESSING_AXES Class responsible for managing the viewport
    %   within the processing tab.
    %
    %   Glossary:
    %   - viewport = The group of GUI components, such as axes and sliders,
    %       which together facilitate the viewing & perusing of a loaded
    %       image or video.
    %   - projection = The set of dimensions along which we are viewing a
    %       loaded image or video. By default, we are looking at individual
    %       slices along the z dimensions, so the default projection is z.
    %       The projection may also be switched to xyz.
    
    properties
        grid = [];                                                          % Parent grid layout containing this panel.
        axes = [];                                                          % Struct of axes components (one field/projection).
        sliders = [];                                                       % Struct of slider components (one field/dimension).

        image_only_components = [];                                         % Struct featuring components exclusive to images.
        video_only_components = [];                                         % Struct featuring components exclusive to videos.

        projection = 'z';                                                   % Dimensions currently projected within axes.
    end
    
    methods
        function obj = image_processing_viewport()
            %IMAGE_MANIPULATION Constructs a persistent instance
            %   of the image manipulation panel.
            persistent viewport_instance

            % If uninitiated...
            if isempty(viewport_instance)
                % Get running app instance.
                app = Program.app;

                % Populate the persistent variable.
                viewport_instance = obj;

                % Assign parent grid layout's GUI handle to grid property.
                viewport_instance.grid = app.ProcAxGrid;

                % Initiate cell array featuring all video components whose
                % callbacks edit video-specific aspects of the current
                % volume
                video_editables = { ...
                        app.StartFrameEditField, ...
                        app.EndFrameEditField, ...
                        app.TrimButton};

                % Initiate a struct whose fields reference video-exclusive
                % components.
                viewport_instance.video_exclusive_components = struct( ...
                    'timeline', {app.PlaceholderProcTimeline}, ...
                    'editables', {video_editables});

                % Initiate a struct whose fields reference our axes.
                % Though we largely only use the xyAxes, we also have xz
                % and yz axes so that users are able to account for neuron
                % visibility in these projections when preprocessing
                % videos.
                viewport_instance.axes = struct( ...
                    'xy', {app.proc_xyAxes}, ...
                    'xz', {app.proc_xzAxes}, ...
                    'yz', {app.proc_yzAxes});

                % Initiate a struct whose fields reference our z-sliders.
                % Note that we have multiple to ensure that users are able
                % to explore xz & yz appropriately when projecting along
                % multiple dimensions.
                z_sliders = struct( ...
                    'default', {app.proc_zSlider}, ...                      % This is the default z slider we use when projecting solely in the z dimension.
                    'horizontal', {app.proc_hor_zSlider}, ...               % This is the horizontal z slider we use when the xz view is enabled.
                    'vertical', {app.proc_vert_zSlider});                   % This is the vertical z slider we use when the yz view is enabled.

                % Assign slider GUI components to sliders property.
                viewport_instance.sliders = struct( ...
                    'x', {app.proc_xSlider}, ...
                    'y', {app.proc_ySlider}, ...
                    'z', {z_sliders}, ...
                    't', {app.proc_tSlider});
            end

            % Return persistent instance.
            obj = viewport_instance;
        end

        function obj = set_projection(obj, projection)
            %SET_PROJECTION Updates GUI configuration in accordance with a
            %   given projection.
            %
            %   Input:
            %   - obj: image_processing_viewport instance.
            %   - projection: char describing dimensions to project, e.g.
            %       "xyzt", "xyz", "z", etc.

            % Define all allowed dimensions (x, y, z, t).
            allowed_projections = "xyzt";

            % Check whether the given projection features any invalid
            % dimensions.
            is_valid_projection = any( ...
                ~ismember(projection, allowed_projections));

            if is_valid_projection
                % If valid, update projection.
                obj.projection = projection;

            else
                % If invalid, raise an error.
                error("Projection %s contains unknown dimension.", ...
                    projection);
            end

            % Prompt class to update its display configuration to match
            % the new projection.
            obj.set_display_configuration();
        end
        
        function obj = set_display_configuration(obj, projection)
            %SET_DISPLAY_CONFIGURATION Edits relevant grid layout
            %   to ensure layout serves the functionality the user
            %   is currently engaging with.

            % If obj wasn't passed for some reason, grab the 
            % persistent instance.
            if ~exist('obj', 'var')
                obj = Program.GUI.Panels.image_processing_axes();
            end

            % If a projection was passed, set this to be the new active
            % projection.
            if exist('projection', 'var')
                obj.set_projection(projection);
            else 
                projection = obj.projection;
            end

            % If we are working with a video...
            if obj.is_working_with_video
                % Update the GUI configuration to ensure that only
                % components relevant to videos are accessible.
                obj.set_video_configuration();

                % Remove t from the projection argument.
                projection = strrep(projection, 't', '');
            end

            switch projection
                case 'xyz'
                case 'z'
                    new_row_height = obj.grid.RowHeight;
                    new_row_height{2} = 150;                                % This row features the xyAxes and the y slider.
                    new_row_height{3} = 30;                                 % This row features the 
                    new_row_height{4} = 0;
            end

            obj.set_row_height(new_row_height);
            obj.set_column_width(new_column_width);
            
            if strcmpi(projection, 'reset')
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
                switch projection
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
    end

    methods (Static, Access = public)
        function bool = is_working_with_video()
            %IS_WORKING_WITH_VIDEO Helper function that returns true if
            %   the viewpoer is currently displaying a video and false if
            %   it is currently displaying an image.

            % Get persistent viewport instance.
            obj = Program.GUI.Panels.image_processing_viewport();

            % Check whether current projections features a time dimension.
            bool = contains(obj.projection, 't');
        end
    end

    methods (Access = private)
        function obj = set_video_configuration(obj)
            %SET_VIDEO_CONFIGURATION Configure the GUI and its components
            %   properties such that users are able to edit videos.
            %
            %   Inputs:
            %   - obj: image_processing_viewport instance.
            %
            %   Outputs:
            %   - obj: image_processing_viewport instance.

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
    end
end

