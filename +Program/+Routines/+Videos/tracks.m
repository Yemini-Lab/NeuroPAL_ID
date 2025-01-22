classdef tracks
    %TRACKS A class for managing neuronal track data, including caching, importing,
    %and rendering of Regions of Interest (ROIs).
    %
    %   The TRACKS class includes methods for:
    %   1) Creating and saving a cache of track data (frames, worldlines, etc.).
    %   2) Loading external data (XML, H5, NWB files) and incorporating it into the cache.
    %   3) Managing ROIs, including creation and movement of neuron tracking points.
    %   4) Managing "worldlines" (unique identifiers for tracked entities).
    %   5) Handling provenance information.
    %
    %   Usage:
    %       cache_file = tracks.cache();                  % Retrieve or create default cache
    %       tracks.load(filepath);                        % Load track data from a file
    %       tracks.import(positions, labels);             % Import positions & labels
    %       rois = tracks.find_roi('t', 10);              % Find ROIs at t=10
    %       tracks.draw();                                % Draw ROIs for current time/frame
    
    properties (Constant)
    end
    
    methods (Static, Access = public)
        function load(filepath)
            parent_task = "Importing annotations...";
            d = uiprogressdlg(Program.window, "Title", "NeuroPAL_ID", "Message", parent_task, "Indeterminate", "off");
            d.Message = sprintf("%s\n└🢒 Building cache...", parent_task); d.Value = 0/5;

            [path, name, ~] = fileparts(filepath);
            cache_path = fullfile(path, "track_cache.mat");

            if exist(cache_path, "file")
                check = uiconfirm(Program.window, "Found existing neuron track cache. Load or build from scratch?", "NeuroPAL_ID", "Options", ["Load from cache", "Build new"]);

                if strcmp(check, "Build new")
                    delete(cache_path);
                else
                    Program.Routines.Videos.cache.create(cache_path);
                end
            else
                Program.Routines.Videos.cache.create(cache_path);
            end


            d.Message = sprintf("%s\n└🢒 Reading %s...", parent_task, name); d.Value = 1/5;
            if endsWith(filepath, '.xml')
                [positions, labels] = DataHandling.readTrackmate(filepath);
                Program.app.import_annotations(positions, labels);

            elseif endsWith(filepath, '.h5')
                DataHandling.Helpers.h5.load_tracks(filepath);

            elseif endsWith(filepath, '.nwb')
                DataHandling.Helpers.nwb.load_tracks(filepath);

            end

            d.Message = parent_task;
            Program.Routines.Videos.worldlines.build_from_cache(d);
            
            d.Message = sprintf("%s\n└🢒 Drawing ROIs...", parent_task);
            d.Value = 4/5;
            Program.Routines.Videos.tracks.draw();
            close(d);
        end

        function draw(cursor)
            app = Program.app;
            dimensional_index = Program.Routines.Videos.annotations.dimensional_index;

            if nargin == 0
                cursor = Program.Routines.Videos.cursor;
            end
            
            if app.ShowallneuronsCheckBox.Value
                threshold = 9999;
            else
                threshold = 1;
            end

            target_roi = Program.Routines.Videos.annotations.find( ...
                cursor.t, ...
                'z', [cursor.z - threshold, cursor.z + threshold]);
            
            for n=1:length(target_roi)
                annotation = target_roi(n, :);
                roi_x = annotation(dimensional_index.x);
                roi_y = annotation(dimensional_index.y);
                worldline_id = annotation(dimensional_index.worldline_id);
                worldline = Program.Routines.Videos.worldlines.find(worldline_id);
                annotation_id = annotation(dimensional_index.annotation_id);

                this_roi = drawpoint(app.xyAxes, ...
                    'Position', [roi_x, roi_y], ...
                    'MarkerSize', cursor.marker_size, ...
                    'Color', worldline.color);

                addlistener(this_roi, ...
                    'ROIClicked', @(source, event) Program.Routines.Videos.worldlines.select(worldline_id, annotation, this_roi));

                addlistener(this_roi, ...
                    'ROIMoved', @(source_axes, event) Program.Routines.Videos.annotations.moved(source_axes, annotation_id, event));
            end
        end

        function save()
            cache = Program.Routines.Videos.cache.get();
            annotations_to_write = Program.Routines.Videos.annotations.get();
            worldlines_to_write = Program.Routines.Videos.worldlines.get();

            if ~isempty(worldlines_to_write)
                cache.worldlines = worldlines_to_write;
            end

            if ~isempty(annotations_to_write)
                annotations = cache.frames;
                dim_index = Program.Routines.Videos.annotations.dimensional_index;

                for n=1:length(annotations_to_write)
                    annotation_id = annotations_to_write(n, dim_index.annotation_id);
                    matching_row = annotations(:, dim_index.annotation_id) == annotation_id;

                    if any(matching_row)
                        annotations(matching_row, :) = annotations_to_write(n, :);

                    else
                        annotations(end+1, :) = annotations_to_write(n, :);
                    end
                end

                cache.frames = annotations;
            end

            Program.Routines.Videos.cache.save(cache);
        end

        function export()
            % TBD
        end
    end
end

