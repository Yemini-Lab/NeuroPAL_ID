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
            is_cache = endsWith(filepath, "_vt_cache.mat");
            [path, name, ~] = fileparts(filepath);

            if ~is_cache
                d.Message = sprintf("%s\n└🢒 Building cache...", parent_task); d.Value = 0/5;
                cache_path = fullfile(path, sprintf("%s_vt_cache.mat", name));
                if Program.Routines.Videos.cache.check_for_existing(cache_path)
                    close(d);
                    return
                end
            end

            d.Message = sprintf("%s\n└🢒 Reading %s...", parent_task, name); d.Value = 1/5;
            if endsWith(filepath, '.xml')
                [positions, labels] = DataHandling.readTrackmate(filepath);
                Program.app.import_annotations(positions, labels);

            elseif endsWith(filepath, '.h5')
                DataHandling.Helpers.h5.load_tracks(filepath);

            elseif endsWith(filepath, '.nwb')
                DataHandling.Helpers.nwb.load_tracks(filepath);

            elseif endsWith(filepath, "_vt_cache.mat")
                Program.Routines.Videos.cache.get(filepath);     
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
                threshold = 2;
            end

            target_roi = struct( ...
                'xy', {Program.Routines.Videos.annotations.find(cursor.t, 'z', [cursor.z - threshold, cursor.z + threshold])}, ...
                'xz', {Program.Routines.Videos.annotations.find(cursor.t, 'y', [cursor.x - threshold-1, cursor.x + threshold+1])}, ...
                'yz', {Program.Routines.Videos.annotations.find(cursor.t, 'x', [cursor.y - threshold-1, cursor.y + threshold+1])});
            perspectives = fieldnames(target_roi);

            for p=1:length(perspectives)
                perspective = perspectives{p};
                ax_handle = sprintf("%sAxes", perspective);
                rois = target_roi.(perspective);
                
                for n=1:size(rois, 1)
                    annotation = rois(n, :);
                    d1 = perspective(1);
                    d2 = perspective(2);

                    if ~strcmp(perspective, 'yz')
                        d1_coord = annotation(dimensional_index.(d1));
                        d2_coord = annotation(dimensional_index.(d2));
                    else
                        d1_coord = annotation(dimensional_index.(d2));
                        d2_coord = annotation(dimensional_index.(d1));
                    end

                    worldline_id = annotation(dimensional_index.worldline_id);
                    worldline = Program.Routines.Videos.worldlines.find(worldline_id);
                    annotation_id = annotation(dimensional_index.annotation_id);
    
                    this_roi = drawpoint( ...
                        app.(ax_handle), ...
                        'Position', [d1_coord, d2_coord], ...
                        'MarkerSize', cursor.marker_size, ...
                        'Color', worldline.color, ...
                        'Tag', num2str(annotation_id));
    
                    addlistener(this_roi, ...
                        'ROIClicked', @(source, event) Program.Routines.Videos.worldlines.select(worldline_id, annotation, this_roi));
    
                    addlistener(this_roi, ...
                        'ROIMoved', @(source, event) Program.Routines.Videos.annotations.move(source, annotation_id, event));
                end
            end
        end

        function save()
            cache = Program.Routines.Videos.cache.get();
            to_write = struct( ...
                'annotations', {Program.Routines.Videos.annotations.get()}, ...
                'worldlines', {Program.Routines.Videos.worldlines.get()}, ...
                'wl_record', {Program.Routines.Videos.worldlines.get_wl_record()}, ...
                'provenances', {Program.Routines.Videos.provenances.get()});

            if ~isempty(to_write.worldlines)
                cache.worldlines = to_write.worldlines;
            end

            if ~isempty(to_write.annotations)
                annotations = cache.frames;
                dim_index = Program.Routines.Videos.annotations.dimensional_index;

                for n=1:length(to_write.annotations)
                    annotation_id = to_write.annotations(n, dim_index.annotation_id);
                    matching_row = annotations(:, dim_index.annotation_id) == annotation_id;

                    if any(matching_row)
                        annotations(matching_row, :) = to_write.annotations(n, :);

                    else
                        annotations(end+1, :) = to_write.annotations(n, :);
                    end
                end

                cache.frames = annotations;
            end

            if ~isempty(to_write.wl_record)
                cache.wl_record = to_write.wl_record;
            end

            if ~isempty(to_write.provenances)
                cache.provenances = to_write.provenances;
            end

            Program.Routines.Videos.cache.save(cache);
        end

        function export()
            supported_formats = {'.h5', '.csv', '.xlsx', '.xml', '.mat'};
            [export_file, export_path] = uiputfile(supported_formats, ...
                'Select export location and format');
            export_filepath = fullfile(export_path, export_file);

            if isequal(export_file, 0) || isequal(export_path, 0)
                return
            end

            parent_task = 'Exporting neuron tracks...';
            d = uiprogressdlg(Program.window, 'Title', 'NeuroPAL_ID', parent_task, 'Indeterminate', 'off');
            cache = Program.Routines.Videos.cache.get();
            app = Program.app;

            if endsWith(export_file, 'h5')
                DataHandling.writeZephir(app.video_info, cache, export_filepath);

            elseif  endsWith(export_file, 'csv') || endsWith(export_file, 'xlsx')
                DataHandling.writeExcel(app.video_info, cache, export_filepath);

            elseif endsWith(export_file, 'xml')
                DataHandling.writeTrackMate(app.video_info, cache, export_filepath, Program.window);

            elseif endsWith(export_file, 'mat')
                neuron_tracks = struct( ...
                    'frames', {double([0 0 0 0 0 0])}, ...
                    'path', {export_filepath}, ...
                    'provenances', {{}}, ...
                    'wl_record', {{}}, ...
                    'worldlines', {{}});
                fields_to_write = fieldnames(neuron_tracks);
                n_fields = length(fields_to_write);
                save(export_filepath, "-struct", "neuron_tracks", '-v7.3');
                
                f = matfile(export_filepath, "Writable", true);
                for p=1:length(n_fields)
                    d.Value = p/length(n_fields);
                    field = fields_to_write{p};
                    d.Message = sprintf("%s\n└─{ Writing %s }...", parent_task, field);
                    f.(field) = cache.(field);
                end                
            end

            close(d);
        end
    end
end

