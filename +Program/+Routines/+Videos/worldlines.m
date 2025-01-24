classdef worldlines
    %WORLDLINES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static, Access = public)
        function worldlines = get(new_wl)
            persistent current_wl

            if nargin > 0
                current_wl = new_wl;
            elseif isempty(current_wl)
                current_wl = Program.Routines.Videos.cache.get().worldlines;
            end

            worldlines = current_wl;
        end

        function wl_record = get_wl_record(new_wl)
            persistent current_wl_record

            if nargin > 0
                current_wl_record = new_wl;
            elseif isempty(current_wl_record)
                current_wl_record = Program.Routines.Videos.cache.get().wl_record;
            end

            wl_record = current_wl_record;
        end

        function build_from_cache(dlg)            
            cache = Program.Routines.Videos.cache.get();
            wl_record = cache.wl_record;
            n_wls = length(wl_record);
            worldlines = {};

            wl_msg = sprintf("%s\n├🢒 Registering worldlines...", dlg.Message);
            dlg.Message = wl_msg; dlg.Value = 3/5;
            
            for wl_id=1:n_wls
                dlg.Value = min(1, 3 + (wl_id/n_wls)) / 5;

                wl_name = cache.wl_record(wl_id, :);
                wl_name = wl_name{:};

                dlg.Message = sprintf("%s\n└─{ %s }...", wl_msg, wl_name);

                [node, color, style] = Program.Routines.Videos.worldlines.add_node(wl_name, wl_id);
                worldlines{end+1} = Program.Routines.Videos.worldlines.create(node, wl_name, color, style, wl_id);
            end

            cache.worldlines = worldlines;
            Program.Routines.Videos.cache.save(cache);
        end
        
        function add(node, name, color, style)  
            worldlines = Program.Routines.Videos.worldlines.get();
            
            wl_id = length(worldlines) + 1;
            worldlines(:, wl_id) = {struct( ...
                'node', {node}, ...
                'name', {name}, ...
                'color', {color}, ...
                'style', {style}, ...
                'id', {wl_id})};

            Program.Routines.Videos.worldlines.get(worldlines);
        end

        function worldline = create(node, name, color, style, wl_id)
            worldline = struct( ...
                'id', {wl_id}, ...
                'node', {node}, ...
                'name', {name}, ...
                'color', {color}, ...
                'style', {style}, ...
                'provenance', {'NPAL'});
        end

        function worldline = find(worldline_id)            
            worldlines = Program.Routines.Videos.worldlines.get();
            worldline = worldlines(:, worldline_id);
            worldline = worldline{:};
        end

        function edit(worldline_id, property, value)
            app = Program.app;
            worldlines = Program.Routines.Videos.worldlines.get();

            switch property
                case 'name'
                    worldlines{:, worldline_id}.(property) = value;

                case 'color'
                    worldlines{:, worldline_id}.(property) = value;
                    style = uistyle("FontColor", value);
                    Program.Helpers.style_node(app.WorldlineTree, worldlines{:, worldline_id}.node, style);

                case 'provenance'
                    worldlines{:, worldline_id}.(property) = value;
            end

            Program.Routines.Videos.worldlines.get(worldlines);
        end

        function select(worldline_id, annotation, roi)
            if isempty(worldline_id)
                return
            end

            app = Program.app;
            dim_index = Program.Routines.Videos.annotations.dimensional_index;

            worldlines = Program.Routines.Videos.worldlines.get();
            provenances = Program.Routines.Videos.provenances.get();

            worldline = worldlines{worldline_id};
            app.NameEditField.Value = worldline.name;
            app.WorldlineIDEditField.Value = worldline_id;
            app.ColorButton.BackgroundColor = worldline.color;

            if ~exist('annotation', 'var')
                annotation = Program.Routines.Videos.annotations.find( ...
                    Program.Routines.Videos.cursor().t, ...
                    'worldline_id', worldline_id);
            end

            if ~isempty(annotation)
                t = annotation(dim_index.t);
                x = round(annotation(dim_index.x));
                y = round(annotation(dim_index.y));
                z = round(annotation(dim_index.z));
                annotation_id = annotation(dim_index.annotation_id);
                provenance = provenances{annotation(dim_index.provenance_id)};

                app.tEditField.Value = t;
                app.XCoordinateEditField.Value = x;
                app.YCoordinateEditField.Value = y;
                app.ZCoordinateEditField.Value = z;
                app.ProvenanceEditField.Value = provenance;
                app.AnnotationIDEditField.Value = annotation_id;

                app.tSlider.Value = app.tEditField.Value;
                app.xSlider.Value = app.XCoordinateEditField.Value;
                app.ySlider.Value = app.video_info.ny - app.YCoordinateEditField.Value;
                app.hor_zSlider.Value = app.ZCoordinateEditField.Value;

                Program.Routines.Videos.render()
                roi = Program.Routines.Videos.rois.find(annotation_id);
                Program.Routines.GUI.Toggles.local_roi_panel('on');
            else
                Program.Routines.GUI.Toggles.local_roi_panel('off');
            end

            if ~exist('roi', 'var')
                Program.Routines.Videos.annotations.currently_selected(roi);
                roi.Selected = 1;
            end
        end

        function assign_random_colors()
            d = uiprogressdlg(Program.window, 'Title', 'Updating colors...', 'Indeterminate', 'off');
            n_worldlines = length(Program.Routines.Videos.worldlines.get());
            generated_colors = zeros([n_worldlines 3]);
            
            wl_id = 1;
            while wl_id <= n_worldlines
                d.Value = wl_id/n_worldlines;
                randomly_generated_color = rand(1, 3);
                
                if ~ismember(randomly_generated_color, generated_colors, 'rows')
                    Program.Routines.Videos.worldlines.edit(wl_id, 'color', randomly_generated_color)
                    generated_colors(wl_id, :) = randomly_generated_color;
                    wl_id = wl_id + 1;
                end
            end

            Program.Routines.Videos.render();
            drawnow;
            close(d)
        end
    end

    methods (Static, Access = private)
        function set_record(worldlines)
            cache = Program.Routines.Videos.cache.get();
            cache.Writable = true;
            cache.wl_record = worldlines;
            cache.Writable = false;
        end

        function [node, color, style] = add_node(worldline_name, worldline_id)            
            app = Program.app;

            if Neurons.Hermaphrodite.isCell(worldline_name)
                node = uitreenode(app.IDdNode, ...
                    "Text", worldline_name);

            else
                node = uitreenode(app.UnIDdNode, ...
                    "Text", worldline_name);
            end

            color = [0.8, 0.8, 0.8];
            style = uistyle("FontColor", color);
            addStyle(app.WorldlineTree, style, "node", node);

            node.NodeData = worldline_id;
        end

        function node = find_nodes(node_data)
            app = Program.app;
            node = findobj(app.WorldlineTree, 'NodeData', node_data);
        end

        function wl_name = get_name(wl_id)
            worldlines = Program.Routines.Videos.worldlines.get();
            wl_name = worldlines{:, wl_id}.name;
        end
    end
end

