classdef crop_rotate_gui
    %CROP_ROTATE_GUI Manipulation overlay for crop/rotate preprocessing.
    %   This class owns the in-axes crop/rotate controls used by the
    %   processing tab.
    %
    %   Note that it relies on the rotation stack property of the
    %   visualize_light app instance, which keeps track of relevant
    %   handles as well as caching of values between volumes.
    %
    %   This class is very outdated and needs to be reworked once time
    %   permits.

    properties (Constant)
        % The symbols featured in the crop/rotate overlay.
        symbols = struct( ...
            'in_gui', {{'↺', '⦝', '⦬', 'OK', 'X'}}, ...     % Symbols to be drawn in the background box at the top right of the rotation roi.
            'out_gui', {{'↔', '↕'}});                        %  Symbols to be drawn outside of the background box at the top right of the rotation roi.

        % Default settings for drawing the crop/rotate overlay.
        settings = struct( ...
            'font_size', {20}, ...                           % Font size.
            'stroke_size', {12}, ...                         % Size of the stroke around each symbol.
            'vertical_offset', {20}, ...                     % Optional vertical offset for each symbol.
            'box_padding', {[0 0]});                         % Padding around the background box containing the symbols.
    end
    
    methods (Static)

        function draw(app, roi)
            %DRAW Creates the in-axes crop/rotate overlay.
            %
            %   Inputs:
            %   - app: Running app instance.
            %   - roi: An freehand ROI object.

            % We first call the close function to avoid double drawing.
            Program.crop_rotate_gui.close(app);

            % Prompt the image manipulation panel to load its cropping
            % configuration (i.e. resizing the panel & toggling component
            % visibilities).
            gui_sidebar = Program.GUI.preprocessing_gui().sidebar;
            parent_panel = gui_sidebar.panel_instances.image_manipulation;
            parent_panel.set_display_configuration('crop');
            
            if ~isa(roi, 'images.roi.Freehand') || strcmp(roi.Tag, 'redraw') 
                % If the passed roi is not a freehand ROI or has been tagged
                % for redrawing, convert the input into a freehand ROI.
                app.rotation_stack.roi = Program.GUIHandling.rect_to_freehand(roi);
                
                % Then initialize the rotation cache for this volume type.
                app.rotation_stack.cache.(app.VolumeDropDown.Value) = ...
                    struct('angle', {0});
            else
                app.rotation_stack.roi = roi;
            end

            Program.crop_rotate_gui.configure_roi_constraints(app);
            
            % Get the axes to which the roi was drawn.
            axes = app.rotation_stack.roi.Parent;

            % Get the symbols we'll be using to draw the overlay.
            symbols = Program.crop_rotate_gui.symbols.in_gui;

            % Get the number of symbols.
            sym_count = sum(cellfun(@length, symbols));

            % Get the default settings for the overlay.
            font_size = Program.crop_rotate_gui.settings.font_size;                % Font size of the symbols drawn. 
            stroke_size = Program.crop_rotate_gui.settings.stroke_size;            % The size of the stroke drawn around each symbol.
            vertical_offset = Program.crop_rotate_gui.settings.vertical_offset;    % An optional vertical offset.
            box_padding = Program.crop_rotate_gui.settings.box_padding;            % The size of the padding around the background box on which the symbols will be drawn.

            % Get the corners of the roi.
            corners = Program.crop_rotate_gui.get_edges(app, ...
                app.rotation_stack.roi.Position);

            % From these, get the top right corner (which is where we'll be
            % be drawing the crop/rotate overlay.
            top_right_corner = corners(3:-1:2);
            
            % Calculate the dimensions of the background box on which the
            % symbols will be drawn.
            bg_width = font_size*sym_count + stroke_size*length(symbols) + box_padding(1)/2;
            bg_height = font_size + stroke_size + box_padding(2);
            bg_xmin = top_right_corner(1) - bg_width;
            bg_ymin = min(app.rotation_stack.roi.Position(:, 2)) - font_size - vertical_offset;

            bg_pos = [
                [bg_xmin+bg_width, bg_ymin];
                [bg_xmin, bg_ymin];
                [bg_xmin, bg_ymin+bg_height];
                [bg_xmin+bg_width, bg_ymin+bg_height]];

            % Draw the background box as a freehand roi.
            app.rotation_stack.gui{end+1} = images.roi.Freehand( ...
                app.rotation_stack.roi.Parent, 'Position', bg_pos, ...
                'Color', [0.1 0.1 0.1], 'FaceAlpha', 0.7, ...
                'InteractionsAllowed', 'none', 'MarkerSize', 1e-99, ...
                'LineWidth', 1e-99);

            % Initialize a variable that will help us account for
            % multi-character symbols.
            multi_string = 0;

            % For each symbol in the top right box...
            for n = 1:length(symbols)
                % Get the symbol string.
                symbol = symbols{n};

                % Calculate the symbol's x position.
                symbol_x = bg_xmin + (((font_size)*(n-1))/n + stroke_size)*n + ...
                    box_padding(1) / 2 + multi_string/2;

                % Calculate the symbol's y position.
                symbol_y = bg_ymin + bg_height/2;

                % Calculate any addition horizontal padding that may be
                % required due to the number of characters contained within
                % the symbol.
                multi_string = multi_string + font_size * (length(symbol)-1);

                % Define the symbol's color based on which symbol we're
                % dealing with.
                switch symbol
                    case 'OK'
                        color = 'green';
                    case 'X'
                        color = 'red';
                    otherwise
                        color = 'white';
                end

                % Draw the symbol and add it to the rotation stack.
                app.rotation_stack.gui{end+1} = text(axes, ...
                    symbol_x, symbol_y, symbol, ...
                    'Color', color, ...
                    'FontName', 'MonoSpace', 'FontSize', font_size, ...
                    'FontWeight', 'bold', ...
                    'ButtonDownFcn', @(src, event) Program.crop_rotate_gui.trigger(app, event), ...
                    'Tag', 'rot_symbol');
            end

            % For each scaling symbol...
            for n = 1:length(Program.crop_rotate_gui.symbols.out_gui)
                % Get the symbol string.
                scale = Program.crop_rotate_gui.symbols.out_gui{n};

                % Get the edges of the roi.
                pos = Program.crop_rotate_gui.get_edges(app);
                
                % Check which type of scaling symbol we're dealing with and
                % calculate its coordinates. Note that we calculate two
                % sets of coordinates because each scaling symbol is drawn
                % twice, once on each end of its appropriate edge.
                if strcmp(scale, '↔')
                    x1 = pos(1) - font_size;
                    y1 = (pos(2) + pos(4)) / 2;
                    
                    x2 = pos(3) - font_size;
                    y2 = (pos(2) + pos(4)) / 2;
                    
                elseif strcmp(scale, '↕')
                    x1 = (pos(1) + pos(3)) / 2 - font_size;
                    y1 = pos(2);
                    
                    x2 = (pos(1) + pos(3)) / 2 - font_size;
                    y2 = pos(4);
                end
                
                % Draw the scaling symbols and add them to the rotation
                % stack.
                app.rotation_stack.gui{end+1} = text(axes, x1, y1, scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.crop_rotate_gui.trigger(app, event), ...
                    'Tag', num2str(n));
            
                app.rotation_stack.gui{end+1} = text(axes, x2, y2, scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.crop_rotate_gui.trigger(app, event), ...
                    'Tag', num2str(n+2));
            end

            % Assign the update() function to the roi's MovingROI listener. 
            app.rotation_stack.listeners{end+1} = addlistener( ...
                app.rotation_stack.roi, 'MovingROI', @(src, event) ...
                Program.crop_rotate_gui.update(app, event, 'move'));

            % Assign the mouse_poll() function to mouse press & release
            % listeners in order to track click & drag actions.
            app.rotation_stack.listeners{end+1} = addlistener( ...
                app.CELL_ID, 'WindowMousePress', @(~,~) ...
                Program.GUIHandling.mouse_poll(app, 1));

            app.rotation_stack.listeners{end+1} = addlistener( ...
                app.CELL_ID, 'WindowMouseRelease', @(~,~) ...
                Program.GUIHandling.mouse_poll(app, 0));

            set(app.CELL_ID, 'WindowButtonMotionFcn', @(~,~) ...
                Program.GUIHandling.mouse_poll(app));

            Program.crop_rotate_gui.layout_controls(app);
        end

        function update(app, event, mode)
            %UPDATE Handles manipulation of the crop/rotate overlay. Note that
            % this needs to be refactored into three separate functions
            % (move, scale, and rotate) once time allows.
            %
            %   Inputs:
            %   - app: Running app instance.
            %   - event: An event struct retrieved from an overlay
            %       callback.
            %   - mode: One of 'move', 'scale', or 'rotate'.

            % Check which manipulation was requested...
            switch mode
                case 'move'
                    Program.crop_rotate_gui.constrain_to_viewport(app);
                    Program.crop_rotate_gui.layout_controls(app);

                case 'scale'
                    % If we're changing the scale of the crop ROI...
                    t_dim = find(strcmp(event.Source.String, ...
                        Program.crop_rotate_gui.symbols.out_gui));
                    target_edge = str2double(event.Source.Tag);
                    theta = app.rotation_stack.cache.(app.VolumeDropDown.Value).angle;

                    switch target_edge
                        case 1
                            target_corners = 2:3;
                        case 2
                            target_corners = 1:2;
                        case 3
                            target_corners = [1 4];
                        case 4
                            target_corners = 3:4;                          
                    end

                    roi_center = mean(app.rotation_stack.roi.Position, 1);
                    roi_rot = Program.GUIHandling.flat_rotate(app.rotation_stack.roi.Position, -theta, roi_center);
                    roi_rot(target_corners, t_dim) = roi_rot(target_corners, t_dim) + event.variable * (1 - 2 * (t_dim==2));
                    roi_rot = Program.GUIHandling.flat_rotate(roi_rot, theta, roi_center);
                    app.rotation_stack.roi.Position = roi_rot;
                    Program.crop_rotate_gui.constrain_to_viewport(app);
                    Program.crop_rotate_gui.layout_controls(app);


                case 'rotate'
                    % If we're rotating the overlay, get the current volume
                    % type.
                    volume_type = app.VolumeDropDown.Value;
                    
                    % Update this volume type's cached angle with this new
                    % theta.
                    app.rotation_stack.cache.(volume_type).angle = ...
                        app.rotation_stack.cache.(volume_type).angle + ...
                        event.variable;

                    % Assemble a rotation matrix.
                    R = [cosd(event.variable), -sind(event.variable); ...
                        sind(event.variable), cosd(event.variable)];

                    % Calculate the center of the ROI.
                    roi_center = mean(app.rotation_stack.roi.Position, 1);

                    % Use the rotation matrix to rotate the ROI.
                    app.rotation_stack.roi.Position = ( ...
                        (app.rotation_stack.roi.Position - roi_center) * R') ...
                        + roi_center;

                    Program.crop_rotate_gui.constrain_to_viewport(app);
                    Program.crop_rotate_gui.layout_controls(app);
            end
        end

        function configure_roi_constraints(app)
            if isempty(app.rotation_stack.roi) || ~isvalid(app.rotation_stack.roi)
                return
            end

            drawing_area = Program.crop_rotate_gui.get_drawing_area(app);
            app.rotation_stack.roi.DrawingArea = drawing_area;
            app.rotation_stack.roi.Position = ...
                Program.crop_rotate_gui.constrain_position_to_viewport( ...
                    app, app.rotation_stack.roi.Position, drawing_area);
        end

        function drawing_area = get_drawing_area(app)
            target_axes = app.proc_xyAxes;
            if isfield(app.rotation_stack, 'roi') && ...
                    ~isempty(app.rotation_stack.roi) && isvalid(app.rotation_stack.roi)
                target_axes = app.rotation_stack.roi.Parent;
            end

            x_limits = sort(double(target_axes.XLim));
            y_limits = sort(double(target_axes.YLim));
            drawing_area = [x_limits(1), y_limits(1), diff(x_limits), diff(y_limits)];
        end

        function position = constrain_position_to_viewport(app, position, drawing_area)
            if nargin < 3 || isempty(drawing_area)
                drawing_area = Program.crop_rotate_gui.get_drawing_area(app);
            end

            if isempty(position)
                return
            end

            xmin = drawing_area(1);
            xmax = drawing_area(1) + drawing_area(3);
            ymin = drawing_area(2);
            ymax = drawing_area(2) + drawing_area(4);

            original_center = mean(position, 1);
            clamped_center = [ ...
                min(max(original_center(1), xmin), xmax), ...
                min(max(original_center(2), ymin), ymax)];

            relative = position - original_center;
            span_x = max(abs(relative(:, 1)));
            span_y = max(abs(relative(:, 2)));
            allowed_x = min(clamped_center(1) - xmin, xmax - clamped_center(1));
            allowed_y = min(clamped_center(2) - ymin, ymax - clamped_center(2));

            scale = 1;
            if span_x > 0
                scale = min(scale, max(allowed_x, 0) / span_x);
            end
            if span_y > 0
                scale = min(scale, max(allowed_y, 0) / span_y);
            end
            scale = min(max(scale, 0), 1);

            position = clamped_center + relative * scale;
            position(:, 1) = min(max(position(:, 1), xmin), xmax);
            position(:, 2) = min(max(position(:, 2), ymin), ymax);
        end

        function constrain_to_viewport(app)
            if isempty(app.rotation_stack.roi) || ~isvalid(app.rotation_stack.roi)
                return
            end

            drawing_area = Program.crop_rotate_gui.get_drawing_area(app);
            old_position = app.rotation_stack.roi.Position;
            new_position = Program.crop_rotate_gui.constrain_position_to_viewport( ...
                app, old_position, drawing_area);

            if isempty(new_position) || max(abs(new_position - old_position), [], 'all') < 1e-6
                return
            end

            app.rotation_stack.roi.Position = new_position;
            app.rotation_stack.roi.DrawingArea = drawing_area;
        end

        function layout_controls(app)
            if isempty(app.rotation_stack.roi) || ~isvalid(app.rotation_stack.roi) || ...
                    isempty(app.rotation_stack.gui)
                return
            end

            font_size = Program.crop_rotate_gui.settings.font_size;
            stroke_size = Program.crop_rotate_gui.settings.stroke_size;
            vertical_offset = Program.crop_rotate_gui.settings.vertical_offset;
            box_padding = Program.crop_rotate_gui.settings.box_padding;
            symbols = Program.crop_rotate_gui.symbols.in_gui;
            sym_count = sum(cellfun(@length, symbols));

            top_right_corner = Program.crop_rotate_gui.get_edges(app);
            top_right_corner = top_right_corner(3:-1:2);
            bg_width = font_size*sym_count + stroke_size*length(symbols) + box_padding(1)/2;
            bg_height = font_size + stroke_size + box_padding(2);
            bg_xmin = top_right_corner(1) - bg_width;
            bg_ymin = min(app.rotation_stack.roi.Position(:, 2)) - font_size - vertical_offset;

            bg_pos = [
                [bg_xmin+bg_width, bg_ymin];
                [bg_xmin, bg_ymin];
                [bg_xmin, bg_ymin+bg_height];
                [bg_xmin+bg_width, bg_ymin+bg_height]];

            for n = 1:length(app.rotation_stack.gui)
                item = app.rotation_stack.gui{n};
                if isa(item, 'images.roi.Freehand') && isvalid(item)
                    item.Position = bg_pos;
                end
            end

            multi_string = 0;
            for n = 1:length(symbols)
                symbol = symbols{n};
                symbol_x = bg_xmin + (((font_size)*(n-1))/n + stroke_size)*n + ...
                    box_padding(1) / 2 + multi_string/2;
                symbol_y = bg_ymin + bg_height/2;
                multi_string = multi_string + font_size * (length(symbol)-1);

                Program.crop_rotate_gui.set_text_control_position(app, symbol, 'rot_symbol', [symbol_x, symbol_y]);
            end

            pos = Program.crop_rotate_gui.get_edges(app);
            scale_tags = {'1', '2', '3', '4'};
            scale_positions = { ...
                [pos(1) - font_size, (pos(2) + pos(4)) / 2], ...
                [(pos(1) + pos(3)) / 2 - font_size, pos(2)], ...
                [(pos(1) + pos(3)) / 2 - font_size, pos(4)], ...
                [pos(3) - font_size, (pos(2) + pos(4)) / 2]};

            for n = 1:numel(scale_tags)
                Program.crop_rotate_gui.set_text_control_position( ...
                    app, '', scale_tags{n}, scale_positions{n});
            end
        end

        function set_text_control_position(app, symbol, tag, position)
            for n = 1:length(app.rotation_stack.gui)
                item = app.rotation_stack.gui{n};
                if isempty(item) || ~isvalid(item) || isa(item, 'images.roi.Freehand')
                    continue
                end

                if ~isempty(symbol) && ~strcmp(item.String, symbol)
                    continue
                end

                if ~strcmp(string(item.Tag), string(tag))
                    continue
                end

                item.Position(1:2) = position;
                if isprop(item, 'Rotation')
                    item.Rotation = 0;
                end
                break
            end
        end

        function trigger(app, event)
            %TRIGGER This function handles callbacks for each symbol.
            %
            %   Inputs:
            %   - app: Running app instance.
            %   - event: Event info generated by callback.

            % From the passed event info, get a struct that we can edit.
            event = Program.GUIHandling.event2struct(event);

            % Change the color of the symbol that triggered the callback to
            % indicate that the user's click was registered.
            event.Source.Color = [0 1 1];

            % Check which symbol was interacted with...
            switch event.Source.String
                case '⦝'
                    % If the right angle symbol, specify an angle of 90 and
                    % add it to the event struct.
                    event.variable = 90;

                    % Call update().
                    Program.crop_rotate_gui.update(app, event, 'rotate')
    
                case '⦬'
                    % If the acute angle symbol, specify an angle of 45 and
                    % add it to the event struct.
                    event.variable = 45;

                    % Call update().
                    Program.crop_rotate_gui.update(app, event, 'rotate')
    
                case 'OK'
                    % If the user clicked OK, call preview their result.
                    Program.crop_rotate_gui.preview_output(app);
                    return
    
                case 'X'
                    % If the user clicked X, close the crop/rotate overlay.
                    Program.crop_rotate_gui.close(app);
                    return

                otherwise
                    % If the user clicked a symbol that relies on
                    % click & drag functionality, check which symbol that
                    % is.
                    switch event.Source.String
                        case '↺'
                            % If it's the rotation symbol, set the click &
                            % drag direction to 1 (representing right of
                            % click location).
                            drag_direction = 1;

                            % Define a rotation factor of 1/3.5 -- this
                            % ensures that gui isn't rotating significantly
                            % faster than the user intends.
                            factor = 1/3.5;

                            % Set the mode to "rotate".
                            mode = 'rotate';

                        case Program.crop_rotate_gui.symbols.out_gui
                            % If it's one of the scaling symbols, set the
                            % click & drag direction according to which
                            % symbol we're dealing with.
                            drag_direction = find(ismember( ...
                                Program.crop_rotate_gui.symbols.out_gui, ...
                                event.Source.String));

                            % Define a rotation factor of 1.5.
                            factor = 1.5;

                            % Set the mode to "scale".
                            mode = 'scale';
                        otherwise
                            return
                    end

                    % Initiate a variable which is 1 while the mouse
                    % button remains clicked.
                    cct = 1;

                    % Initiate another variable which keeps track of the
                    % total distance that the cursor has been dragged.
                    d_sync = 0;
                    %set(app.CELL_ID, 'Pointer', 'custom', 'PointerShapeCData', NaN(16,16))

                    % While the mouse button remains clicked...
                    while cct
                        % If the mouse has been moved since we last
                        % checked...
                        if any(app.mouse.drag.delta ~= 0) && ...
                                any(d_sync ~= app.mouse.drag.debt)

                            % Rotate the GUI accordingly.
                            event.variable = app.mouse.drag.delta(drag_direction)*factor;
                            Program.crop_rotate_gui.update(app, event, mode)
                        end

                        % Update the total distance that the cursor has
                        % been dragged.
                        d_sync = app.mouse.drag.debt;

                        % Call a short, explicit pause. This allows us to
                        % bypass a known MATLAB bug.
                        pause(0.03)

                        % If the mouse is no longer in a clicked state,
                        % exit this loop.
                        if ~app.mouse.state
                            cct = 0;
                        end
                    end
                    
                    %set(app.CELL_ID, 'Pointer', 'arrow')
            end

            % Reset the symbol's color.
            event.Source.Color = 'white';
        end

        function edges = get_edges(app, pos_array)
            % Retrieve edges based on input position array or ROI position
            if nargin > 1 && ~isempty(pos_array)
                edges = [min(pos_array), max(pos_array)];
            else
                edges = [min(app.rotation_stack.roi.Position), max(app.rotation_stack.roi.Position)];
            end
        end

        function corners = get_corners(app, pos_array)
            if nargin > 1 && ~isempty(pos_array)
                corners = struct( ...
                    'tr', pos_array(1, :), ... 
                    'tl', pos_array(2, :), ...
                    'bl', pos_array(3, :), ...
                    'br', pos_array(4, :));
                
            else
                corners = struct( ...
                    'tr', app.rotation_stack.roi.Position(1, :), ... 
                    'tl', app.rotation_stack.roi.Position(2, :), ...
                    'bl', app.rotation_stack.roi.Position(3, :), ...
                    'br', app.rotation_stack.roi.Position(4, :));
            end
        end
        
        function processed_img = apply_mask(app, img)
            mask = app.rotation_stack.cache.(app.VolumeDropDown.Value).mask;

            rotated_mask = imrotate(mask, -app.rotation_stack.cache.(app.VolumeDropDown.Value).angle);
            nonzero_rows = squeeze(any(any(rotated_mask, 2), 3));
            nonzero_columns = squeeze(any(any(rotated_mask, 1), 3));
            
            top_edge = find(nonzero_rows, 1, 'first');
            bottom_edge = find(nonzero_rows, 1, 'last');
            left_edge = find(nonzero_columns, 1, 'first');
            right_edge = find(nonzero_columns, 1, 'last');

            rotated_img = imrotate(img, -app.rotation_stack.cache.(app.VolumeDropDown.Value).angle);
            processed_img = rotated_img(top_edge:bottom_edge, left_edge:right_edge, :);
        end
        
        function preview_output(app)
            target_axes = app.rotation_stack.roi.Parent;
            app.rotation_stack.cache.(app.VolumeDropDown.Value).mask = createMask(app.rotation_stack.roi);
            preview_img = Program.crop_rotate_gui.apply_mask(app, getimage(target_axes));
            
            image(target_axes, preview_img);
            target_axes.XLim = [1, size(preview_img, 2)];
            target_axes.YLim = [1, size(preview_img, 1)];
            
            user_choice = uiconfirm(app.CELL_ID, "Apply this crop?", "NeuroPAL_ID", "Options", ...
                                    ["Yes", "Return to cropping", "Cancel cropping"]);

            Program.crop_rotate_gui.close(app);
            switch user_choice
                case "Yes"
                    Program.GUIHandling.proc_save_prompt(app, 'crop');
                    
                case "Return to cropping"
                    Program.GUIHandling.crop_routine(app);
                    return;
                    
                case "Cancel cropping"
                    Program.Routines.Processing.reset();
                    return;
            end
        end

        function close(app)
            %CLOSE Closes the crop/rotate overlay and clears any related
            % properties.
            %
            %   Inputs:
            %   - app: Running app instance.

            % Delete the roi.
            delete(app.rotation_stack.roi);

            % Call delete() on every element of the crop/rotate overlay.
            cellfun(@delete, app.rotation_stack.gui);

            % Clear the gui field of the rotation stack struct.
            app.rotation_stack.gui = {};

            % Call delete() on every listener of the crop/rotate overlay.
            cellfun(@delete, app.rotation_stack.listeners);

            % Clear the listeners field of the rotation stack struct.
            app.rotation_stack.listeners = {};

            % Promp the preprocessing sidebar to reset its display
            % configuration and close the cropping interface.
            gui_sidebar = Program.GUI.preprocessing_gui().sidebar;
            parent_panel = gui_sidebar.panel_instances.image_manipulation;
            parent_panel.set_display_configuration('reset');
        end

    end
end
