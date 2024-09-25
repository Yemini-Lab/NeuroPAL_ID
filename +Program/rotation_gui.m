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
        function edges = get_edges(app, pos_array)
            if exist('pos_array', 'var')
                edges = [min(pos_array) max(pos_array)];
            else
                edges = [min(app.rotation_stack.roi.Position) max(app.rotation_stack.roi.Position)];
            end
        end

        function draw(app, roi)
            if ~isa(roi, 'images.roi.Freehand')
                app.rotation_stack.roi = Program.GUIHandling.rect_to_freehand(roi);
            end

            axes = app.rotation_stack.roi.Parent;
            symbols = Program.rotation_gui.symbols.in_gui;
            sym_count = sum(cellfun(@length, symbols));

            font_size = Program.rotation_gui.settings.font_size;
            stroke_size = Program.rotation_gui.settings.stroke_size;
            vertical_offset = Program.rotation_gui.settings.vertical_offset;
            box_padding = Program.rotation_gui.settings.box_padding;

            corners = Program.rotation_gui.get_edges(app, app.rotation_stack.roi.Position);
            top_right_corner = corners(3:-1:2);
            
            bg_width = font_size*sym_count + stroke_size*length(symbols) + box_padding(1)/2;
            bg_height = font_size + stroke_size + box_padding(2);
            bg_xmin = top_right_corner(1) - bg_width;
            bg_ymin = min(app.rotation_stack.roi.Position(:, 2)) - font_size - vertical_offset;

            bg_pos = [
                [bg_xmin+bg_width, bg_ymin];
                [bg_xmin, bg_ymin];
                [bg_xmin, bg_ymin+bg_height];
                [bg_xmin+bg_width, bg_ymin+bg_height]];

            app.rotation_stack.gui{end+1} = images.roi.Freehand(app.rotation_stack.roi.Parent, 'Position', bg_pos, 'Color', [0.1 0.1 0.1], 'FaceAlpha', 0.7, ...
                'InteractionsAllowed', 'none', 'MarkerSize', 1e-99, 'LineWidth', 1e-99);

            % Construct rotation symbols
            multi_string = 0;
            for n = 1:length(symbols)
                symbol = symbols{n};
                symbol_x = bg_xmin + (((font_size)*(n-1))/n + stroke_size)*n + box_padding(1) / 2 + multi_string/2;
                symbol_y = bg_ymin + bg_height/2;
                multi_string = multi_string + font_size * (length(symbol)-1);

                switch symbol
                    case 'OK'
                        color = 'green';
                    case 'X'
                        color = 'red';
                    otherwise
                        color = 'white';
                end

                app.rotation_stack.gui{end+1} = text(axes, symbol_x, symbol_y, symbol, ...
                    'Color', color, ...
                    'FontName', 'MonoSpace', 'FontSize', font_size, 'FontWeight', 'bold', ...
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event));
            end

            % Construct scaling symbols
            for n = 1:length(Program.rotation_gui.symbols.out_gui)
                scale = Program.rotation_gui.symbols.out_gui{n};
                pos = Program.rotation_gui.get_edges(app);
                
                if strcmp(scale, '↔')
                    x1 = pos(1) - Program.rotation_gui.settings.font_size;
                    y1 = (pos(2) + pos(4)) / 2;
                    
                    x2 = pos(3) - Program.rotation_gui.settings.font_size;
                    y2 = (pos(2) + pos(4)) / 2;
                    
                elseif strcmp(scale, '↕')
                    x1 = (pos(1) + pos(3)) / 2 - Program.rotation_gui.settings.font_size;
                    y1 = pos(2);
                    
                    x2 = (pos(1) + pos(3)) / 2 - Program.rotation_gui.settings.font_size;
                    y2 = pos(4);
                end
                
                app.rotation_stack.gui{end+1} = text(axes, x1, y1, scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', Program.rotation_gui.settings.font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event));
            
                app.rotation_stack.gui{end+1} = text(axes, x2, y2, scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', Program.rotation_gui.settings.font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event));
            end

            app.rotation_stack.listeners{end+1} = addlistener(app.rotation_stack.roi, 'MovingROI', @(src, event) Program.rotation_gui.update(app, event, 'move'));
            app.rotation_stack.listeners{end+1} = addlistener(app.CELL_ID, 'WindowMousePress', @(~,~) Program.GUIHandling.mouse_poll(app, 1));
            app.rotation_stack.listeners{end+1} = addlistener(app.CELL_ID, 'WindowMouseRelease', @(~,~) Program.GUIHandling.mouse_poll(app, 0));
            set(app.CELL_ID, 'WindowButtonMotionFcn', @(~,~) Program.GUIHandling.mouse_poll(app));
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
                    roi_edges = Program.rotation_gui.get_edges(app);
                    nogui_edges = [roi_edges(2) roi_edges(4)];
                        
                    app.rotation_stack.roi.Position(:, t_dim) = app.rotation_stack.roi.Position(:, t_dim) + event.delta;
                    if ~ismember(event.Source.Position(t_dim), nogui_edges)
                        for n = 1:length(app.rotation_stack.gui)
                            t_arr = app.rotation_stack.gui{n}.Position(:, t_dim);
                            t_val = max(t_arr) + event.delta;
                            app.rotation_stack.gui{n}.Position(t_arr == max(t_arr), t_dim) = t_val;
                        end
                    end

                case 'rotate'
                    R = [cosd(event.theta), -sind(event.theta); sind(event.theta), cosd(event.theta)];

                    roi_center = mean(app.rotation_stack.roi.Position, 1);
                    app.rotation_stack.roi.Position = ((app.rotation_stack.roi.Position - roi_center) * R') + roi_center;

                    for n = 1:length(app.rotation_stack.gui)
                        if ~isa(app.rotation_stack.gui{n}, 'images.roi.Freehand')
                            app.rotation_stack.gui{n}.Position(1:2) = ((app.rotation_stack.gui{n}.Position(1:2) - roi_center) * R') + roi_center;
                            set(app.rotation_stack.gui{n}, 'Rotation', app.rotation_stack.gui{n}.Rotation - event.theta);
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
                    event.theta = 90;
                    Program.rotation_gui.update(app, event, 'rotate')
    
                case '⦬'
                    event.theta = 45;
                    Program.rotation_gui.update(app, event, 'rotate')
    
                case 'OK'
                    Program.rotation_gui.preview_output(app, app.rotation_stack.roi, app.rotation_stack.roi.Parent);
    
                case 'X'
                    Program.rotation_gui.close(app);

                otherwise

                    switch event.Source.String
                        case '↺'
                            variable = 'theta';
                            factor = 1/3.5;
                            mode = 'rotate';
                        case Program.rotation_gui.symbols.out_gui
                            variable = 'delta';
                            factor = 1;
                            mode = 'scale';
                        otherwise
                            return
                    end

                    cct = 1;
                    d_sync = 0;
                    set(app.CELL_ID, 'Pointer', 'custom', 'PointerShapeCData', NaN(16,16))

                    while cct
                        if any(app.mouse.drag.delta ~= 0) && any(d_sync ~= app.mouse.drag.debt)
                            event.(variable) = app.mouse.drag.delta(1)*factor;
                            Program.rotation_gui.update(app, event, mode)
                        end

                        d_sync = app.mouse.drag.debt;
                        pause(0.03)

                        if ~app.mouse.state
                            cct = 0;
                        end
                    end
                    set(app.CELL_ID, 'Pointer', 'arrow')
            end

            event.Source.Color = 'white';
        end

        function preview_output(app, roi, ax)
            % Get the current image from the axes
            imgHandle = findobj(ax, 'Type', 'image');
            img = imgHandle.CData;
            imgXData = imgHandle.XData;
            imgYData = imgHandle.YData;
        
            % Get the ROI corners (top-right, top-left, bottom-right, bottom-left)
            corners = roi.Position;
        
            % Calculate the angle of the top and bottom lines to detect rotation
            topLine = corners(1, :) - corners(2, :);
            bottomLine = corners(3, :) - corners(4, :);
        
            % Average of the angles of both lines (we assume ROI should be axis-aligned)
            angleTop = atan2(topLine(2), topLine(1));
            angleBottom = atan2(bottomLine(2), bottomLine(1));
            avgAngle = (angleTop + angleBottom) / 2;
        
            % Compute the center of the ROI for rotation reference
            centerX = mean(corners(:, 1));
            centerY = mean(corners(:, 2));
            rotationAngle = -avgAngle * 180 / pi; % Convert radians to degrees for imrotate
        
            % Rotate the image around the center of the ROI
            rotatedImg = imrotate(img, rotationAngle, 'bilinear', 'crop');
        
            % Rotate the ROI corners
            rotMatrix = [cos(avgAngle), -sin(avgAngle); sin(avgAngle), cos(avgAngle)];
            rotatedCorners = (corners - [centerX, centerY]) * rotMatrix' + [centerX, centerY];
        
            % Define the bounding box for the rotated ROI (axis-aligned)
            xMin = max(min(rotatedCorners(:, 1)), imgXData(1));
            xMax = min(max(rotatedCorners(:, 1)), imgXData(2));
            yMin = max(min(rotatedCorners(:, 2)), imgYData(1));
            yMax = min(max(rotatedCorners(:, 2)), imgYData(2));
        
            % Crop the rotated image to the bounding box
            croppedImg = rotatedImg(round(yMin:yMax), round(xMin:xMax), :);
        
            % Update the image data on the axes
            set(imgHandle, 'CData', croppedImg);
            set(imgHandle, 'XData', [xMin, xMax]);
            set(imgHandle, 'YData', [yMin, yMax]);
        
            % Adjust the axes limits to zoom into the cropped image
            xlim(ax, [xMin, xMax]);
            ylim(ax, [yMin, yMax]);
            set(ax, 'DataAspectRatio', [1, 1, 1]);

            for n = 1:length(app.proc_rotation_gui.rotation_stack)
                delete(app.proc_rotation_gui.rotation_stack{n});
            end
        end

        function close(app)
            stacks = fieldnames(app.rotation_stack);

            for s=1:length(stacks)
                stack_name = stacks{s};
                stack = app.rotation_stack.(stack_name);

                if length(stack) > 1
                    for n=1:length(stack)
                        delete(stack{n})
                    end
                else
                    delete(stack)
                end
            end
        end

    end
end

