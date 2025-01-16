classdef tracks
    %TRACKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        dimensional_index = struct( ...
            't', {1}, ...
            'x', {2}, ...
            'y', {3}, ...
            'z', {4}, ...
            'worldline_id', {5}, ...
            'provenance_id', {6}, ...
            'annotation_id', {7});
    end
    
    methods (Static, Access = public)
        %% Cache
        function cache_file = cache(new_cache)
            persistent current_cache

            if nargin == 1
                current_cache = matfile(new_cache, 'Writable', true);
                current_cache.path = new_cache;
                Program.Routines.Videos.tracks.save_cache(current_cache);
            elseif isempty(current_cache)
                current_cache = Program.Routines.Videos.tracks.create_default_cache();
            end

            cache_file = current_cache;
        end

        function save_cache(cache)
            if nargin == 0
                cache = Program.Routines.Videos.tracks.cache();
            end

            if isa(cache, "matlab.io.MatFile")
                cache = struct( ...
                    'frames', {double(cache.frames)}, ...
                    'path', {cache.path}, ...
                    'provenances', {cache.provenances}, ...
                    'wl_record', {cache.wl_record}, ...
                    'worldlines', {cache.worldlines});
            end

            save(cache.path, "-struct", "cache", '-v7.3');
        end

        function set_wl_record(worldlines)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            cache.wl_record = worldlines;
            cache.Writable = false;
        end

        %% General
        function load(filepath)
            [path, ~, ~] = fileparts(filepath);
            cache_path = fullfile(path, "track_cache.mat");
            neurons = Program.Routines.Videos.tracks.create_default_cache();
            save(cache_path, "-struct", "neurons", '-v7.3');
            Program.Routines.Videos.tracks.cache(cache_path);

            if endsWith(filepath, '.xml')
                [positions, labels] = DataHandling.readTrackmate(filepath);
                Program.app.import_annotations(positions, labels);
                %Program.Routines.Videos.tracks.import(positions, labels);

            elseif endsWith(filepath, '.h5')
                DataHandling.Helpers.h5.load_tracks(filepath);

            elseif endsWith(filepath, '.nwb')
                DataHandling.Helpers.nwb.load_tracks(filepath);

            end

            cache = Program.Routines.Videos.tracks.cache(cache_path);
            if isempty(cache.worldlines)
                d = uiprogressdlg(Program.window, "Title", "NeuroPAL_ID", "Message", "Importing worldlines...", "Indeterminate", "off");
                for entry=1:length(cache.wl_record)
                    d.Value = entry/length(cache.wl_record);
                    worldline_name = cache.wl_record(entry, :);
                    d.Message = sprintf("Importing %s...", worldline_name{:});
                    [node, color, style] = Program.Routines.Videos.tracks.add_node(worldline_name{:});
                    Program.Routines.Videos.tracks.add_worldline(node, worldline_name, color, style);
                end
                close(d);
            end
            
            Program.Routines.Videos.tracks.draw();
        end
        
        function import(positions, labels)
            app = Program.app;
            cache = Program.Routines.Videos.tracks.cache;

            positions = Program.Validation.coordinate_conversion_check(positions);
            positions(:, 1) = round(positions(:, 1));

            for n=1:length(labels)
                coords = positions(n, :);

                worldline_name = labels{n};
                t = coords(1);
                x = coords(2);
                y = coords(3);
                z = coords(4);

                worldline_exists, worldline_id = ismember(worldline_name, cache.wl_record);
                if ~worldline_exists
                    cache.wl_record{end+1} = worldline_name;
                    [node, color, style] = Program.Routines.Videos.tracks.add_node(worldline_name);
                    Program.Routines.Videos.tracks.add_worldline(node, worldline_name, color, style);
                end

                Program.Routines.Videos.tracks.add_roi(t, x, y, z, worldline_id);
            end

            Program.Routines.Videos.render();
            app.data_flags.('Tracking_ROIs') = 1;
        end

        function draw(cursor)
            app = Program.app;
            dimensional_index = Program.Routines.Videos.tracks.dimensional_index;

            if nargin == 0
                cursor = Program.Routines.Videos.cursor;
            end
            
            if app.ShowallneuronsCheckBox.Value
                threshold = 9999;
            else
                threshold = 3;
            end

            target_roi = Program.Routines.Videos.tracks.find_roi( ...
                cursor.t, ...
                'z', [cursor.z - threshold, cursor.z + threshold]);
            
            for n=1:length(target_roi)
                annotation = target_roi(n, :);
                roi_x = annotation(dimensional_index.x);
                roi_y = annotation(dimensional_index.y);
                worldline_id = annotation(dimensional_index.worldline_id);
                worldline = Program.Routines.Videos.tracks.find_worldline(worldline_id);
                annotation_id = annotation(dimensional_index.annotation_id);

                this_roi = drawpoint(app.xyAxes, ...
                    'Position', [roi_x, roi_y], ...
                    'MarkerSize', cursor.marker_size, ...
                    'Color', worldline.color);

                addlistener(this_roi, ...
                    'ROIClicked', @(source, event) Program.Routines.Videos.track.select_worldline(worldline_id, annotation));

                addlistener(this_roi, ...
                    'ROIMoved', @(source_axes, event) Program.Routines.Videos.track.roi_moved(source_axes, annotation_id, event));
            end
        end

        %% ROIs
        function add_roi(t, x, y, z, worldline_id, provenance_id)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            
            if worldline_id > size(cache, 'worldline')
                [node, color, style, worldline_id] = Program.Routines.Videos.tracks.add_node('Unknown');
                Program.Routines.Videos.tracks.add_worldline(node, 'Unknown', color, style, worldline_id);
            end
            cache.frames = [cache.frames; t x y z worldline_id provenance_id size(cache.frames, 1)+1];

            cache.Writable = false;
            Program.Routines.Videos.tracks.save_cache(cache);
        end

        function target_roi = find_roi(varargin)
            p = inputParser;

            addRequired(p, 't');
            addOptional(p, 'x', []);
            addOptional(p, 'y', []);
            addOptional(p, 'z', []);
            addOptional(p, 'worldline_id', []);
            addOptional(p, 'provenance_id', []);
            addOptional(p, 'annotation_id', []);

            parse(p, varargin{:});
            
            cache = Program.Routines.Videos.tracks.cache;
            dimensional_index = Program.Routines.Videos.tracks.dimensional_index;

            target_roi = cache.frames;
            dimensions = fieldnames(dimensional_index);

            for d=1:length(dimensions)
                dimension = dimensions{d};
                requirement = p.Results.(dimension);

                if ~isempty(requirement)
                    if isscalar(requirement)
                        target_roi = target_roi(target_roi(:, dimensional_index.(dimension)) == requirement, :);

                    else
                        target_roi = target_roi(target_roi(:, dimensional_index.(dimension)) >= requirement(1), :);
                        target_roi = target_roi(target_roi(:, dimensional_index.(dimension)) <= requirement(2), :);
                    end
                end
            end
        end

        function move_roi(source_axes, annotation_id, event)
            app = Program.app;
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            roi_idx = find(cache.frames(:, dimensional_index.annotation_id) == annotation_id);
            
            switch source_axes
                case app.xyAxes
                    cache.frames(roi_idx, 2) = event.CurrentPosition(1);
                    cache.frames(roi_idx, 3) = event.CurrentPosition(2);
                case app.xzAxes
                    cache.frames(roi_idx, 2) = event.CurrentPosition(1);
                    cache.frames(roi_idx, 4) = event.CurrentPosition(2);
                case app.yzAxes
                    cache.frames(roi_idx, 3) = event.CurrentPosition(2);
                    cache.frames(roi_idx, 4) = event.CurrentPosition(1);
            end

            cache.Writable = false;
            Program.Routines.Videos.tracks.save_cache(cache);
        end

        %% Worldlines
        function add_worldline(node, name, color, style)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;

            wl_record = cache.wl_record;
            worldlines = cache.worldlines;

            wl_record{end+1} = name;
            worldlines{end+1} = struct( ...
                'node', {node}, ...
                'name', {name}, ...
                'color', {color}, ...
                'style', {style}, ...
                'id', {length(cache.worldlines)+1});


            cache.wl_record = wl_record;
            cache.worldlines = worldlines;
            cache.Writable = false;
            Program.Routines.Videos.tracks.save_cache(cache);
        end

        function worldline = find_worldline(worldline_id)
            cache = Program.Routines.Videos.tracks.cache;
            worldline = cache.worldlines(worldline_id);
        end

        function select_worldline(worldline_id, annotation)
            app = Program.app;
            worldline = cache.worldlines{worldline_id};

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

        %% Provenance
        function add_provenance(name)
            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            provenances = cache.provenances;
            provenances{end+1} = name;
            cache.provenances = provenances;
            cache.Writable = false;
            Program.Routines.Videos.tracks.save_cache(cache);
        end

        function provenance = find_provenance(provenance_id)
            cache = Program.Routines.Videos.tracks.cache;
            provenance = cache.provenances(provenance_id);
        end
    end

    methods (Static, Access = private)
        function track_cache = create_default_cache()
            track_cache = struct( ...
                'wl_record', {{}}, ...
                'worldlines', {{}}, ...
                'provenances', {{}}, ...
                'frames', {double([0 0 0 0 0 0 0])});
        end

        function [node, color, style] = add_node(worldline_name)
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

            node.NodeData = length(app.IDdNode.Children) + ...
                length(app.UnIDdNode.Children);
        end
    end
end

