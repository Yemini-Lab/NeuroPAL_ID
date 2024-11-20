classdef rotation
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
        function obj = stack(new_stack)
            persistent current_stack

            if isempty(current_stack)
                current_stack = struct( ...
                    'roi', {[]}, ...
                    'gui', {{}}, ...
                    'listeners', {{}}, ...
                    'cache', {0});

            elseif nargin > 0
                current_stack = new_stack;
                
            end

            obj = current_stack;
        end

        function draw(roi)
            app = Program.GUIHandling.app;
            Program.Handlers.rotation.close(app);

            stack = Program.Handlers.rotation.stack();
            
            if ~isa(roi, 'images.roi.Freehand') || strcmp(roi.Tag, 'redraw') 
                stack.roi = Program.Helpers.roi_to_freehand(roi);
                stack.cache.(app.VolumeDropDown.Value) = struct('angle', {0});
            end

            bg = Program.Handlers.rotation.build_background();
            stack.gui{end+1} = images.roi.Freehand( ...
                stack.roi.Parent, ...
                'Position', bg.pos, ...
                'Color', [0.1 0.1 0.1], ...
                'FaceAlpha', 0.7, ...
                'InteractionsAllowed', 'none', ...
                'MarkerSize', 1e-99, ...
                'LineWidth', 1e-99);

            % Construct rotation symbols
            stack = Program.Handlers.rotation.build_rotation(bg, stack);

            % Construct scaling symbols
            stack = Program.Handlers.rotation.build_scaling(stack);

            % Update stack);
            Program.Handlers.rotation.stack(stack);
        end

        function update(event, mode)
            stack = Program.Handlers.rotation.stack;

            switch mode
                case 'move'
                    [~, tr_idx] = max(event.PreviousPosition(:,1) + event.PreviousPosition(:,2) * 1e-6);
                    old_tr = event.PreviousPosition(tr_idx, :);
        
                    [~, tr_idx] = max(event.CurrentPosition(:,1) + event.CurrentPosition(:,2) * 1e-6);
                    new_tr = event.CurrentPosition(tr_idx, :);
        
                    xy_diff = old_tr - new_tr;
        
                    for n = 1:length(stack.gui)
                        if isa(stack.gui{n}, 'images.roi.Freehand')
                            stack.gui{n}.Position = stack.gui{n}.Position - (event.PreviousPosition-event.CurrentPosition);
                        else
                            stack.gui{n}.Position(1:2) = stack.gui{n}.Position(1:2) - xy_diff;
                        end
                    end

                case 'scale'
                    app = Program.GUIHandling.app;
                    theta = stack.cache.(app.VolumeDropDown.Value).angle;
                    dimension = find(strcmp(event.Source.String, Program.Handlers.rotation.symbols.out_gui));
                    edge = str2double(event.Source.Tag);
                    Program.Handlers.rotation.scale(dimension, edge, theta);

                case 'rotate'
                    app = Program.GUIHandling.app;
                    stack.cache.(app.VolumeDropDown.Value).angle = stack.cache.(app.VolumeDropDown.Value).angle + event.variable;
                    R = [cosd(event.variable), -sind(event.variable); sind(event.variable), cosd(event.variable)];

                    roi_center = mean(stack.roi.Position, 1);
                    stack.roi.Position = ((stack.roi.Position - roi_center) * R') + roi_center;

                    for n = 1:length(stack.gui)
                        if ~isa(stack.gui{n}, 'images.roi.Freehand')
                            stack.gui{n}.Position(1:2) = ((stack.gui{n}.Position(1:2) - roi_center) * R') + roi_center;
                            set(stack.gui{n}, 'Rotation', stack.gui{n}.Rotation - event.variable);
                        else
                            stack.gui{n}.Position = ((stack.gui{n}.Position - roi_center) * R') + roi_center;
                        end
                    end
            end

            Program.Handlers.rotation.stack(stack);
        end

        function trigger(event)
            app = Program.GUIHandling.app;
            event = Program.Helpers.event_to_struct(event);
            event.Source.Color = [0 1 1];

            switch event.Source.String
                case '⦝'
                    event.variable = 90;
                    Program.Handlers.rotation.update(event, 'rotate')
    
                case '⦬'
                    event.variable = 45;
                    Program.Handlers.rotation.update(event, 'rotate')
    
                case 'OK'
                    Program.Handlers.rotation.preview_output();
                    return
    
                case 'X'
                    Program.Handlers.rotation.close(app);
                    return

                otherwise

                    switch event.Source.String
                        case '↺'
                            drag_direction = 1;
                            factor = 1/3.5;
                            mode = 'rotate';
                        case Program.Handlers.rotation.symbols.out_gui
                            drag_direction = find(ismember(Program.Handlers.rotation.symbols.out_gui, event.Source.String));
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
                            Program.Handlers.rotation.update(app, event, mode)
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

        function edges = get_edges(pos_array)
            % Retrieve edges based on input position array or ROI position

            if nargin > 1 && ~isempty(pos_array)
                edges = [min(pos_array), max(pos_array)];

            else
                roi_pos = Program.Handlers.rotation.stack().roi.Position;
                edges = [min(roi_pos), max(roi_pos)];

            end
        end

        function corners = get_corners(pos_array)
            if nargin == 0 || isempty(pos_array)
                pos_array = Program.Handlers.rotation.stack().roi.Position;
            end

            corners = struct( ...
                'tr', pos_array(1, :), ... 
                'tl', pos_array(2, :), ...
                'bl', pos_array(3, :), ...
                'br', pos_array(4, :));
        end
        
        function processed_img = apply_mask(img)
            app = Program.GUIHandling.app;
            cache = Program.Handlers.rotation.stack().cache;
            mask = cache.(app.VolumeDropDown.Value).mask;

            rotated_mask = imrotate(mask, cache.(app.VolumeDropDown.Value).angle);
            nonzero_rows = squeeze(any(any(rotated_mask, 2), 3));
            nonzero_columns = squeeze(any(any(rotated_mask, 1), 3));
            
            top_edge = find(nonzero_rows, 1, 'first');
            bottom_edge = find(nonzero_rows, 1, 'last');
            left_edge = find(nonzero_columns, 1, 'first');
            right_edge = find(nonzero_columns, 1, 'last');

            rotated_img = imrotate(img, cache.(app.VolumeDropDown.Value).angle);
            processed_img = rotated_img(top_edge:bottom_edge, left_edge:right_edge, :);
        end
        
        function preview_output()
            app = Program.GUIHandling.app;
            stack = Program.Handlers.rotation.stack;

            target_axes = stack.roi.Parent;
            stack.cache.(app.VolumeDropDown.Value).mask = createMask(stack.roi);
            preview_img = Program.Handlers.rotation.apply_mask(app, getimage(target_axes));
            
            image(target_axes, preview_img);
            target_axes.XLim = [1, size(preview_img, 2)];
            target_axes.YLim = [1, size(preview_img, 1)];
            
            user_choice = uiconfirm(app.CELL_ID, "Apply this crop?", "NeuroPAL_ID", "Options", ...
                                    ["Yes", "Return to cropping", "Cancel cropping"]);

            Program.Handlers.rotation.close(app);
            switch user_choice
                case "Yes"
                    Program.GUIHandling.proc_save_prompt(app, 'crop');
                    
                case "Return to cropping"
                    Program.Routines.crop();
                    return;
                    
                case "Cancel cropping"
                    return;
            end
        end

        function close()
            stack = Program.Handlers.rotation.stack;
            delete(stack.roi);

            cellfun(@delete, stack.gui);
            stack.gui = {};

            cellfun(@delete, stack.listeners);
            stack.listeners = {};

            Program.Handlers.rotation.stack(stack);
        end

    end

    methods (Static, Access = private)

        function bg_struct = build_background()
            s = Program.Handlers.rotation.settings;
            symbols = Program.Handlers.rotation.symbols.in_gui;
            roi_position = Program.Handlers.rotation.stack.roi.Position;

            width = s.font_size * s.sym_count + s.stroke_size * length(symbols) + s.box_padding(1)/2;
            height = s.font_size + s.stroke_size + s.box_padding(2);
            xmin = top_right_corner(1) - width;
            ymin = min(roi_position(:, 2)) - s.font_size - s.vertical_offset;

            top_right = [xmin + width, ymin];
            top_left = [xmin, ymin];
            bottom_left = [xmin, ymin+height];
            bottom_right = [xmin+width, ymin+height];

            bg_struct = struct( ...
                'width', {width}, ...
                'height', {height}, ...
                'xmin', {xmin}, ...
                'ymin', {ymin});

            bg_struct.pos = [ ...
                    top_right; ...
                    top_left; ... 
                    bottom_left; ... 
                    bottom_right];
        end

        function stack = build_rotation(bg, stack)
            s = Program.Handlers.rotation.settings;
            symbols = Program.Handlers.rotation.symbols.in_gui;

            multi_string = 0;
            for n = 1:length(symbols)
                symbol = symbols{n};
                symbol_x = bg.xmin + (((s.font_size)*(n-1))/n + s.stroke_size)*n + s.box_padding(1) / 2 + multi_string/2;
                symbol_y = bg.ymin + bg.height/2;
                multi_string = multi_string + s.font_size * (length(symbol)-1);

                switch symbol
                    case 'OK'
                        color = 'green';
                    case 'X'
                        color = 'red';
                    otherwise
                        color = 'white';
                end

                stack.gui{end+1} = text(stack.roi.Parent, ...
                    symbol_x, symbol_y, ...
                    symbol, ...
                    'Color', color, ...
                    'FontName', 'MonoSpace', 'FontSize', s.font_size, 'FontWeight', 'bold', ...
                    'ButtonDownFcn', @(src, event) Program.Handlers.rotation.trigger(event), ...
                    'Tag', 'rot_symbol');
            end
        end

        function stack = build_scaling(stack)
            app = Program.GUIHandling.app;
            s = Program.Handlers.rotation.settings;

            for n = 1:length(Program.Handlers.rotation.symbols.out_gui)
                scale = Program.Handlers.rotation.symbols.out_gui{n};
                pos = Program.Handlers.rotation.get_edges();
                
                if strcmp(scale, '↔')
                    x1 = pos(1) - s.font_size;
                    y1 = (pos(2) + pos(4)) / 2;
                    
                    x2 = pos(3) - s.font_size;
                    y2 = (pos(2) + pos(4)) / 2;
                    
                elseif strcmp(scale, '↕')
                    x1 = (pos(1) + pos(3)) / 2 - s.font_size;
                    y1 = pos(2);
                    
                    x2 = (pos(1) + pos(3)) / 2 - s.font_size;
                    y2 = pos(4);
                end
                
                stack.gui{end+1} = text(stack.roi.Parent, ...
                    x1, y1, ...
                    scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', s.font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.Handlers.rotation.trigger(event), ...
                    'Tag', num2str(n));
            
                stack.gui{end+1} = text(stack.roi.Parent, ...
                    x2, y2, ...
                    scale, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', s.font_size*2, ...
                    'ButtonDownFcn', @(src, event) Program.Handlers.rotation.trigger(event), ...
                    'Tag', num2str(n+2));
            end

            stack.listeners{end+1} = addlistener(stack.roi, 'MovingROI', @(src, event) Program.Handlers.rotation.update(event, 'move'));
            stack.listeners{end+1} = addlistener(app.CELL_ID, 'WindowMousePress', @(~,~) Program.GUIHandling.mouse_poll(app, 1));
            stack.listeners{end+1} = addlistener(app.CELL_ID, 'WindowMouseRelease', @(~,~) Program.GUIHandling.mouse_poll(app, 0));
            set(app.CELL_ID, 'WindowButtonMotionFcn', @(~,~) Program.GUIHandling.mouse_poll(app));
        end

        function scale(t_dim, target_edge, theta)
            stack = Program.Handlers.rotation.stack;
    
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
    
            roi_center = mean(stack.roi.Position, 1);
            roi_rot = Program.Handlers.rotation.flat_rotate(stack.roi.Position, -theta, roi_center);
            roi_rot(target_corners, t_dim) = roi_rot(target_corners, t_dim) + event.variable * (1 - 2 * (t_dim==2));
            roi_rot = Program.Handlers.rotation.flat_rotate(roi_rot, theta, roi_center);
            roi_diff = roi_rot - stack.roi.Position;
    
            stack.roi.Position = stack.roi.Position + roi_diff;
    
            scale_delta = roi_diff(target_corners(t_dim), :);
            for n = 1:length(stack.gui)
                if isscalar(stack.gui{n}.Tag)
                    if strcmp(stack.gui{n}.String, event.Source.String)
                        stack.gui{n}.Position(:, 1:2) = stack.gui{n}.Position(:, 1:2) + scale_delta * (str2double(stack.gui{n}.Tag)==target_edge);
                    else
                        stack.gui{n}.Position(:, 1:2) = stack.gui{n}.Position(:, 1:2) + scale_delta/2;
                    end
                    continue
                elseif any(ismember(target_edge, [2, 3]))
                    stack.gui{n}.Position(:, 1:2) = stack.gui{n}.Position(:, 1:2) + roi_diff(1, :);
                end
            end
        end

        function rot_pos = flat_rotate(pos, theta, offset)
            if ~exist('offset', 'var') || max(offset, [], 'all') == 0
                offset = zeros(size(pos));
            end

            R = [cosd(theta), -sind(theta); sind(theta), cosd(theta)];

            if iscell(pos)
                rot_pos = cellfun(@(x) Program.Handlers.rotation.flat_rotate(x, theta, offset), pos, 'UniformOutput', false);
            else
                c_spec_dim = size(offset, 2);
                if size(pos, 2) > c_spec_dim
                    pos(1:2) = ((pos(1:2) - offset) * R') + offset;
                    rot_pos = pos;
                else
                    rot_pos = ((pos - offset) * R') + offset;
                end
            end
        end
    end
end

