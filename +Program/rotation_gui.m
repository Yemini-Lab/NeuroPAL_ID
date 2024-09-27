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
            Program.rotation_gui.close(app);
            
            if ~isa(roi, 'images.roi.Freehand') || strcmp(roi.Tag, 'redraw') 
                app.rotation_stack.roi = Program.GUIHandling.rect_to_freehand(roi);
                app.rotation_stack.cache.(app.VolumeDropDown.Value) = struct('angle', {0});
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
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event), ...
                    'Tag', 'rot_symbol');
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
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event), ...
                    'Tag', num2str(n));
            
                app.rotation_stack.gui{end+1} = text(axes, x2, y2, scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', Program.rotation_gui.settings.font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.rotation_gui.trigger(app, event), ...
                    'Tag', num2str(n+2));
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
                    set(app.CELL_ID, 'Pointer', 'custom', 'PointerShapeCData', NaN(16,16))

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
                    
                    set(app.CELL_ID, 'Pointer', 'arrow')
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

    end
end

