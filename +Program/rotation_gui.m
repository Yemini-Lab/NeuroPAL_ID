classdef rotation_gui
    %ROTATION_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        symbols = struct( ...
            'in_gui', {{'↺', '⦝', '⦬', 'OK', 'X'}}, ...
            'out_gui', {{'↔', '↕'}});

        settings = struct( ...
            'font_size', {20}, ...
            'stroke_size', {12}, ...
            'vertical_offset', {20}, ...
            'box_padding', {[0 0]});
    end
    
    methods (Static)

        function draw(app, roi)
            % Close any existing rotation GUI elements
            Program.rotation_gui.close(app);
            
            % Ensure ROI is a freehand ROI
            if ~isa(roi, 'images.roi.Freehand') || strcmp(roi.Tag, 'redraw') 
                app.rotation_stack.roi = Program.GUIHandling.rect_to_freehand(roi);
                app.rotation_stack.cache.(app.VolumeDropDown.Value) = struct('angle', 0);
            end
        
            top_right_corner = Program.Helpers.get_corner(app.rotation_stack.roi.Position).top_right;
            Program.rotation_gui.draw_symbols(top_right_corner, app.rotation_stack.roi.Parent);

            % Set up listeners for mouse click & drag.
            app.rotation_stack.listeners{end+1} = addlistener(app.CELL_ID, 'WindowMousePress', @(~,~) Program.GUIHandling.mouse_poll(app, 1));
            app.rotation_stack.listeners{end+1} = addlistener(app.CELL_ID, 'WindowMouseRelease', @(~,~) Program.GUIHandling.mouse_poll(app, 0));
            set(app.CELL_ID, 'WindowButtonMotionFcn', @(~,~) Program.GUIHandling.mouse_poll(app));
        
            % Set up listeners for ROI movement.
            app.rotation_stack.listeners{end+1} = addlistener(app.rotation_stack.roi, 'MovingROI', ...
                @(src, event) Program.rotation_gui.update(app, event, 'move'));
        end

        function update(app, event, mode)
            switch mode
                case 'move'
                    [~, tr_idx] = max(event.PreviousPosition(:,1) + event.PreviousPosition(:,2) * 1e-6);
                    old_tr = event.PreviousPosition(tr_idx, :);
        
                    [~, tr_idx] = max(event.CurrentPosition(:,1) + event.CurrentPosition(:,2) * 1e-6);
                    new_tr = event.CurrentPosition(tr_idx, :);
        
                    xy_diff = old_tr - new_tr;
        
                    for n = 1:length(app.rotation_stack.gui)
                        if isa(app.rotation_stack.gui{n}, 'images.roi.Freehand')
                            app.rotation_stack.gui{n}.Position = app.rotation_stack.gui{n}.Position - (event.PreviousPosition-event.CurrentPosition);
                        else
                            app.rotation_stack.gui{n}.Position(1:2) = app.rotation_stack.gui{n}.Position(1:2) - xy_diff;
                        end
                    end

                case 'scale'
                    t_dim = find(strcmp(event.Source.String, Program.rotation_gui.symbols.out_gui));
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
                    app.rotation_stack.cache.(app.VolumeDropDown.Value).angle = app.rotation_stack.cache.(app.VolumeDropDown.Value).angle + event.variable;
                    R = [cosd(event.variable), -sind(event.variable); sind(event.variable), cosd(event.variable)];

                    roi_center = mean(app.rotation_stack.roi.Position, 1);
                    app.rotation_stack.roi.Position = ((app.rotation_stack.roi.Position - roi_center) * R') + roi_center;

                    for n = 1:length(app.rotation_stack.gui)
                        if ~isa(app.rotation_stack.gui{n}, 'images.roi.Freehand')
                            app.rotation_stack.gui{n}.Position(1:2) = ((app.rotation_stack.gui{n}.Position(1:2) - roi_center) * R') + roi_center;
                            set(app.rotation_stack.gui{n}, 'Rotation', app.rotation_stack.gui{n}.Rotation - event.variable);
                        else
                            app.rotation_stack.gui{n}.Position = ((app.rotation_stack.gui{n}.Position - roi_center) * R') + roi_center;
                        end
                    end
            end
        end

        function trigger(app, event)
            event = Program.GUIHandling.event2struct(event);
            event.Source.Color = [0 1 1];

            switch event.Source.String
                case '⦝'
                    event.variable = 90;
                    Program.rotation_gui.update(app, event, 'rotate')
    
                case '⦬'
                    event.variable = 45;
                    Program.rotation_gui.update(app, event, 'rotate')
    
                case 'OK'
                    Program.rotation_gui.preview_output(app);
                    return
    
                case 'X'
                    Program.rotation_gui.close(app);
                    return

                otherwise

                    switch event.Source.String
                        case '↺'
                            drag_direction = 1;
                            factor = 1/3.5;
                            mode = 'rotate';
                        case Program.rotation_gui.symbols.out_gui
                            drag_direction = find(ismember(Program.rotation_gui.symbols.out_gui, event.Source.String));
                            factor = 1.5;
                            mode = 'scale';
                        otherwise
                            return
                    end

                    cct = 1;
                    d_sync = 0;
                    %set(app.CELL_ID, 'Pointer', 'custom', 'PointerShapeCData', NaN(16,16))

                    while cct
                        if any(app.mouse.drag.delta ~= 0) && any(d_sync ~= app.mouse.drag.debt)
                            event.variable = app.mouse.drag.delta(drag_direction)*factor;
                            Program.rotation_gui.update(app, event, mode)
                        end

                        d_sync = app.mouse.drag.debt;
                        pause(0.03)

                        if ~app.mouse.state
                            cct = 0;
                        end
                    end
                    
                    %set(app.CELL_ID, 'Pointer', 'arrow')
            end

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
        end

        function settings = calc_graphics()
            font_size = Program.rotation_gui.settings.font_size;
            stroke_size = Program.rotation_gui.settings.stroke_size;
            vertical_offset = Program.rotation_gui.settings.vertical_offset;
            box_padding = Program.rotation_gui.settings.box_padding;

            settings = struct( ...
                'font_size', {font_size}, ...
                'stroke_size', {stroke_size}, ...
                'vertical_offset', {vertical_offset}, ...
                'box_padding', {box_padding});
        end

        function draw_symbols(corner, axesHandle)
            app = Program.GUIHandling.app;

            xLimits = axesHandle.XLim;
            yLimits = axesHandle.YLim;
        
            % Define symbols and their callbacks
            symbols = Program.rotation_gui.symbols.in_gui;
            numSymbols = length(symbols);
            callbacks = {
                @(src, event) Program.rotation_gui.trigger(app, event), ... % ↺
                @(src, event) Program.rotation_gui.trigger(app, event), ... % ⦝
                @(src, event) Program.rotation_gui.trigger(app, event), ... % ⦬
                @(src, event) Program.rotation_gui.trigger(app, event), ... % OK
                @(src, event) Program.rotation_gui.trigger(app, event)      % X
            };

            % Define the offsets for positioning
            xOffset = 0.02 * diff(xLimits); % Adjust as needed
            yOffset = 0.02 * diff(yLimits); % Adjust as needed

            % Calculate positions for each symbol
            for n = 1:numSymbols
                symbol = symbols{numSymbols-(n-1)};

                switch symbol
                    case "OK"
                        color = 'green';
                    case "X"
                        color = 'red';
                    otherwise
                        color = 'white';
                end

                % Position relative to the top-right corner of the ROI
                xPosData = corner(1) - xOffset - (n/1.5 - 1) * 0.05 * diff(xLimits);
                yPosData = corner(2) - yOffset;
        
                % Create the text object within the axes
                txtHandle = text(axesHandle, xPosData, yPosData, symbol, ...
                    'Units', 'data', 'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', 'Color', color, ...
                    'FontSize', 16, 'FontWeight', 'bold', ...
                    'ButtonDownFcn', callbacks{n}, 'Tag', 'rot_symbol');
        
                % Store the handle for later reference
                app.rotation_stack.gui{end+1} = txtHandle;
            end
        end

    end
end

