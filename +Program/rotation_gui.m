classdef rotation_gui
    %ROTATION_GUI This class is responsible for handling all functionality
    % related to the crop/rotate GUI triggered by the preprocessing tab.
    %
    %   Note that it relies on the rotation stack property of the
    %   visualize_light app instance, which keeps track of relevant
    %   handles as well as caching of values between volumes.
    %
    %   This class is very outdated and needs to be reworked once time
    %   permits.

    properties (Constant)
        % The symbols featured in the rotation GUI.
        symbols = struct( ...
            'in_gui', {{'↺', '⦝', '⦬', 'OK', 'X'}}, ...     % Symbols to be drawn in the background box at the top right of the rotation roi.
            'out_gui', {{'↔', '↕'}});                        %  Symbols to be drawn outside of the background box at the top right of the rotation roi.

        % Default settings for drawing the rotation gui.
        settings = struct( ...
            'font_size', {20}, ...                           % Font size.
            'stroke_size', {12}, ...                         % Size of the stroke around each symbol.
            'vertical_offset', {20}, ...                     % Optional vertical offset for each symbol.
            'box_padding', {[0 0]});                         % Padding around the background box containing the symbols.
    end
    
    methods (Static)

        function draw(app, roi)
            %DRAW Creates the in-axes rotation gui.
            %
            %   Inputs:
            %   - app: Running app instance.
            %   - roi: An freehand ROI object.

            % We first call the close function to avoid double drawing.
            Program.rotation_gui.close(app);

            % Prompt the image manipulation panel to load its cropping
            % configuration (i.e. resizing the panel & toggling component
            % visibilities).
            gui_sidebar = Program.GUI.preprocessing_gui().sidebar;
            parent_panel = gui_sidebar.panel_instances.image_manipulation();
            parent_panel.set_display_configuration('crop');
            
            if ~isa(roi, 'images.roi.Freehand') || strcmp(roi.Tag, 'redraw') 
                % If the passed roi is not a freehand ROI or has been tagged
                % for redrawing, convert the input into a freehand ROI.
                app.rotation_stack.roi = Program.GUIHandling.rect_to_freehand(roi);
                
                % Then initialize the rotation cache for this volume type.
                app.rotation_stack.cache.(app.VolumeDropDown.Value) = ...
                    struct('angle', {0});
            end
            
            % Get the axes to which the roi was drawn.
            axes = app.rotation_stack.roi.Parent;

            % Get the symbols we'll be using to draw our rotation gui.
            symbols = Program.rotation_gui.symbols.in_gui;

            % Get the number of symbols.
            sym_count = sum(cellfun(@length, symbols));

            % Get the default settings for our rotation gui.
            font_size = Program.rotation_gui.settings.font_size;                % Font size of the symbols drawn. 
            stroke_size = Program.rotation_gui.settings.stroke_size;            % The size of the stroke drawn around each symbol.
            vertical_offset = Program.rotation_gui.settings.vertical_offset;    % An optional vertical offset.
            box_padding = Program.rotation_gui.settings.box_padding;            % The size of the padding around the background box on which the symbols will be drawn.

            % Get the corners of the roi.
            corners = Program.rotation_gui.get_edges(app, ...
                app.rotation_stack.roi.Position);

            % From these, get the top right corner (which is where we'll be
            % be drawing the rotation gui.
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
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event), ...
                    'Tag', 'rot_symbol');
            end

            % For each scaling symbol...
            for n = 1:length(Program.rotation_gui.symbols.out_gui)
                % Get the symbol string.
                scale = Program.rotation_gui.symbols.out_gui{n};

                % Get the edges of the roi.
                pos = Program.rotation_gui.get_edges(app);
                
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
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event), ...
                    'Tag', num2str(n));
            
                app.rotation_stack.gui{end+1} = text(axes, x2, y2, scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event), ...
                    'Tag', num2str(n+2));
            end

            % Assign the update() function to the roi's MovingROI listener. 
            app.rotation_stack.listeners{end+1} = addlistener( ...
                app.rotation_stack.roi, 'MovingROI', @(src, event) ...
                Program.rotation_gui.update(app, event, 'move'));

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
        end

        function update(app, event, mode)
            %UPDATE Handles manipulation of the rotation gui. Note that
            % this needs to be refactored into three separate functions
            % (move, scale, and rotate) once time allows.
            %
            %   Inputs:
            %   - app: Running app instance.
            %   - event: An event struct retrieved from a rotation gui
            %       callback.
            %   - mode: One of 'move', 'scale', or 'rotate'.

            % Check which manipulation was requested...
            switch mode
                case 'move'
                    % If we're moving the rotation gui, calculate the
                    % difference between (x, y) difference between the
                    % previous top right corner and the new top right
                    % corner.
                    [~, tr_idx] = max(event.PreviousPosition(:,1) + ...
                        event.PreviousPosition(:,2) * 1e-6);
                    old_tr = event.PreviousPosition(tr_idx, :);
        
                    [~, tr_idx] = max(event.CurrentPosition(:,1) + ...
                        event.CurrentPosition(:,2) * 1e-6);
                    new_tr = event.CurrentPosition(tr_idx, :);
        
                    xy_diff = old_tr - new_tr;
        
                    % Update the position of each item in the rotation 
                    % stack gui accordingly.
                    for n = 1:length(app.rotation_stack.gui)
                        if isa(app.rotation_stack.gui{n}, 'images.roi.Freehand')
                            app.rotation_stack.gui{n}.Position = ...
                                app.rotation_stack.gui{n}.Position - ...
                                (event.PreviousPosition-event.CurrentPosition);
                        else
                            app.rotation_stack.gui{n}.Position(1:2) = ...
                                app.rotation_stack.gui{n}.Position(1:2) ...
                                - xy_diff;
                        end
                    end

                case 'scale'
                    % If we're changing the scale of the rotation roi...
                    t_dim = find(strcmp(event.Source.String, ...
                        Program.rotation_gui.symbols.out_gui));
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
                    roi_diff = roi_rot - app.rotation_stack.roi.Position;

                    app.rotation_stack.roi.Position = app.rotation_stack.roi.Position + roi_diff;

                    scale_delta = roi_diff(target_corners(t_dim), :);
                    for n = 1:length(app.rotation_stack.gui)
                        if isscalar(app.rotation_stack.gui{n}.Tag)
                            if strcmp(app.rotation_stack.gui{n}.String, event.Source.String)
                                app.rotation_stack.gui{n}.Position(:, 1:2) = app.rotation_stack.gui{n}.Position(:, 1:2) + scale_delta * (str2double(app.rotation_stack.gui{n}.Tag)==target_edge);
                            else
                                app.rotation_stack.gui{n}.Position(:, 1:2) = app.rotation_stack.gui{n}.Position(:, 1:2) + scale_delta/2;
                            end
                            continue
                        elseif any(ismember(target_edge, [2, 3]))
                            app.rotation_stack.gui{n}.Position(:, 1:2) = app.rotation_stack.gui{n}.Position(:, 1:2) + roi_diff(1, :);
                        end
                    end


                case 'rotate'
                    % If we're rotating the gui, get the current volume
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

                    % Iterate over each rotationg ui element and rotate it
                    % appropriately based on the rotation matrix.
                    for n = 1:length(app.rotation_stack.gui)
                        if ~isa(app.rotation_stack.gui{n}, 'images.roi.Freehand')
                            app.rotation_stack.gui{n}.Position(1:2) = ( ...
                                (app.rotation_stack.gui{n}.Position(1:2) ...
                                - roi_center) * R') + roi_center;

                            set(app.rotation_stack.gui{n}, 'Rotation', ...
                                app.rotation_stack.gui{n}.Rotation ...
                                - event.variable);

                        else
                            app.rotation_stack.gui{n}.Position = ( ...
                                (app.rotation_stack.gui{n}.Position ...
                                - roi_center) * R') + roi_center;
                        end
                    end
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
                    Program.rotation_gui.update(app, event, 'rotate')
    
                case '⦬'
                    % If the acute angle symbol, specify an angle of 45 and
                    % add it to the event struct.
                    event.variable = 45;

                    % Call update().
                    Program.rotation_gui.update(app, event, 'rotate')
    
                case 'OK'
                    % If the user clicked OK, call preview their result.
                    Program.rotation_gui.preview_output(app);
                    return
    
                case 'X'
                    % If the user clicked X, call close the rotation gui.
                    Program.rotation_gui.close(app);
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

                        case Program.rotation_gui.symbols.out_gui
                            % If it's one of the scaling symbols, set the
                            % click & drag direction according to which
                            % symbol we're dealing with.
                            drag_direction = find(ismember( ...
                                Program.rotation_gui.symbols.out_gui, ...
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
                            Program.rotation_gui.update(app, event, mode)
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

            rotated_mask = imrotate(mask, app.rotation_stack.cache.(app.VolumeDropDown.Value).angle);
            nonzero_rows = squeeze(any(any(rotated_mask, 2), 3));
            nonzero_columns = squeeze(any(any(rotated_mask, 1), 3));
            
            top_edge = find(nonzero_rows, 1, 'first');
            bottom_edge = find(nonzero_rows, 1, 'last');
            left_edge = find(nonzero_columns, 1, 'first');
            right_edge = find(nonzero_columns, 1, 'last');

            rotated_img = imrotate(img, app.rotation_stack.cache.(app.VolumeDropDown.Value).angle);
            processed_img = rotated_img(top_edge:bottom_edge, left_edge:right_edge, :);
        end
        
        function preview_output(app)
            target_axes = app.rotation_stack.roi.Parent;
            app.rotation_stack.cache.(app.VolumeDropDown.Value).mask = createMask(app.rotation_stack.roi);
            preview_img = Program.rotation_gui.apply_mask(app, getimage(target_axes));
            
            image(target_axes, preview_img);
            target_axes.XLim = [1, size(preview_img, 2)];
            target_axes.YLim = [1, size(preview_img, 1)];
            
            user_choice = uiconfirm(app.CELL_ID, "Apply this crop?", "NeuroPAL_ID", "Options", ...
                                    ["Yes", "Return to cropping", "Cancel cropping"]);

            Program.rotation_gui.close(app);
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
            delete(app.rotation_stack.roi);

            cellfun(@delete, app.rotation_stack.gui);
            app.rotation_stack.gui = {};

            cellfun(@delete, app.rotation_stack.listeners);
            app.rotation_stack.listeners = {};

            gui_sidebar = Program.GUI.preprocessing_gui().sidebar;
            parent_panel = gui_sidebar.panel_instances.image_manipulation;
            parent_panel.set_display_configuration('reset');
        end

    end
end

