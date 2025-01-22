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
            cache = Program.Routines.Videos.cache.get;
            cache.Writable = true;

            wl_id = length(cache.worldlines)+1;
            cache.wl_record(:, wl_id) = name;
            cache.worldlines(:, wl_id) = {struct( ...
                'node', {node}, ...
                'name', {name}, ...
                'color', {color}, ...
                'style', {style}, ...
                'id', {wl_id})};

            cache.Writable = false;
            Program.Routines.Videos.cache.save(cache);
        end

        function worldline = create(node, name, color, style, wl_id)
            if nargin < 5
                cache = Program.Routines.Videos.cache.get();
                wl_id = length(cache.worldlines) + 1;
            end

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
                    worldlines(:, worldline_id).(property) = value;

                case 'color'
                    worldlines(:, worldline_id).(property) = value;
                    worldlines(:, worldline_id).style = uistyle("FontColor", value);
                    addStyle(app.WorldlineTree, worldlines(:, worldline_id).style, worldlines(:, worldline_id).node);

                case 'provenance'
                    worldlines(:, worldline_id).(property) = value;
            end
        end

        function select(worldline_id, annotation, roi)            
            app = Program.app;
            worldline = cache.worldlines{worldline_id};

            if nargin == 3
                Program.Routines.Videos.annotations.currently_selected(roi);
            end

            app.NameEditField.Value = worldline.name;
            app.WorldlineIDEditField.Value = worldline_id;
            app.ColorButton.BackgroundColor = worldline.color;

            app.XCoordinateEditField.Value = annotation(2);
            app.YCoordinateEditField.Value = annotation(3);
            app.ZCoordinateEditField.Value = annotation(4);
            app.ProvenanceEditField.Value = cache.provenances{annotation(5)};

            app.xSlider.Value = app.XCoordinateEditField.Value;
            app.ySlider.Value = app.video_info.ny - app.YCoordinateEditField.Value;
            app.hor_zSlider.Value = app.ZCoordinateEditField.Value;
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
    end
end

