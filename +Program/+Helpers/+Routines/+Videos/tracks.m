classdef tracks
    %TRACKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static, Access = public)
        function cache_file = cache(new_cache)
            persistent current_cache

            if nargin == 1
                current_cache = matfile(new_cache);
            end

            cache_file = current_cache;
        end

        function load(filepath)
            [path, ~, ~] = fileparts(filepath);
            Program.Routines.Videos.tracks.cache(fullfile(path, "track_cache.mat"));
            neurons = Program.Routines.Videos.tracks.create_default_cache();
            save(Program.Routines.Videos.tracks.cache, "-struct", "neurons");

            if endsWith(filepath, '.xml')
                [positions, labels] = DataHandling.readTrackmate(filepath);

            elseif endsWith(filepath, '.h5')
                [positions, labels] = DataHandling.Helpers.h5.load_tracks(filepath);

            elseif endsWith(filepath, '.nwb')
                [positions, labels] = DataHandling.Helpers.nwb.load_tracks(filepath);

            end
            
            Program.Routines.Videos.tracks.import(positions, labels);
        end
        
        function import(positions, labels)
            app = Program.app;
            cache = Program.Routines.Videos.tracks.cache;

            d = uiprogressdlg(Program.window, ...
                "Title", "NeuroPAL ID", ...
                "Message", "Importing tracks...", ...
                "Indeterminate", "off");

            positions = Program.Validation.cooordinate_conversion_check(positions);
            positions(:, 1) = round(positions(:, 1));

            for n=1:length(labels)
                d.Value = n/size(positions, 1);
                coords = positions(n, :);

                worldline_name = labels{n};
                t = coords(1);
                x = coords(2);
                y = coords(3);
                z = coords(4);

                worldline_exists, worldline_id = ismember(worldline_name, cache.wl_record);
                if ~worldline_exists
                    cache.wl_record{end+1} = worldline_name;
                    [node, color, style, worldline_id] = Program.Routines.Videos.tracks.add_node(worldline_name);
                    Program.Routines.Videos.tracks.add_worldline(node, worldline_name, color, style, worldline_id);
                end

                Program.Routines.Videos.tracks.add_roi(t, x, y, z, worldline_id);
            end

            app.visual_composer();
            close(d)

            app.data_flags.('Tracking_ROIs') = 1;
        end

        function add_roi(x, y, z, worldline_id, provenance_id)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            cache.frames.(frame) = [cache.frames.(frame) x y z worldline_id provenance_id];
            cache.Writable = false;
        end

        function add_worldline(node, name, color, style, id)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            cache.wl_record{end+1} = name;
            cache.worldlines{end+1} = struct( ...
                'node', {node}, ...
                'name', {name}, ...
                'color', {color}, ...
                'style', {style}, ...
                'id', {id});
            cache.Writable = false;
        end

        function add_provenance(name)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            cache.provenance{end+1} = name;
            cache.Writable = false;
        end

        function [node, color, style] = add_node(worldline_name)
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

            node.NodeData = length(app.IDdNode.Children) + ...
                length(app.UnIDdNode.Children);
        end
    end

    methods (Static, Access = private)
        function track_cache = create_default_cache()
            track_cache = struct( ...
                'wl_record', {{}}, ...
                'worldlines', {{}}, ...
                'provenances', {{}}, ...
                'frames', {[]});
        end
    end
end

