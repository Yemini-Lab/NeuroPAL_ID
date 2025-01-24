classdef annotations
    
    properties (Constant)
        %DIMENSIONAL_INDEX Struct for dimension indexes of track data columns.
        %   The fields in DIMENSIONAL_INDEX map descriptive dimension names
        %   (t, x, y, z, worldline_id, provenance_id, annotation_id) to
        %   their corresponding column indices.
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
        function roi = currently_selected(new_roi)
            persistent selected_roi

            if nargin == 1
                selected_roi = new_roi;
            end

            if ~selected_roi.Selected
                selected_roi.Selected = 1;
            end

            roi = selected_roi;
        end

        function annotations = get(annotations)
            persistent cached_annotation_changes

            if nargin == 1
                cached_annotation_changes = annotations;
            end

            annotations = cached_annotation_changes;
        end

        function add(t, x, y, z, worldline_id, provenance_id)
            cache = Program.Routines.Videos.cache.get();
            dim_index = Program.Routines.Videos.annotations.dimensional_index;
            annotations = Program.Routines.Videos.annotations.get();
            
            if worldline_id > length(Program.Routines.Videos.worldlines.get())
                [node, color, style, worldline_id] = Program.Routines.worldlines.add_node('???');
                Program.Routines.Videos.worldlines.add(node, '???', color, style, worldline_id);
            end

            if provenance_id > length(Program.Routines.Videos.provenances.get())
                Program.Routines.Videos.provenances.add('????', cache);
            end

            annotations(:, dim_index.annotation_id) = [t x y z worldline_id, provenance_id];

            Program.Routines.Videos.annotations.get(annotations);
        end

        function target_annotation = find(varargin)            
            p = inputParser;

            addRequired(p, 't');
            addOptional(p, 'x', []);
            addOptional(p, 'y', []);
            addOptional(p, 'z', []);
            addOptional(p, 'worldline_id', []);
            addOptional(p, 'provenance_id', []);
            addOptional(p, 'annotation_id', []);

            parse(p, varargin{:});
            
            cache = Program.Routines.Videos.cache.get();
            dim_index = Program.Routines.Videos.annotations.dimensional_index;

            target_annotation = cache.frames;
            dimensions = fieldnames(dim_index);

            for d=1:length(dimensions)
                dim = dimensions{d};
                req = p.Results.(dim);

                if ~isempty(req)
                    if isscalar(req)
                        target_annotation = target_annotation(target_annotation(:, dim_index.(dim)) == req, :);

                    else
                        target_annotation = target_annotation(target_annotation(:, dim_index.(dim)) >= req(1), :);
                        target_annotation = target_annotation(target_annotation(:, dim_index.(dim)) <= req(2), :);
                    end
                end
            end
        end

        function edit(annotation_id, property, value)
            annotation = Program.Routines.Videos.annotations.find(annotation_id);
            dim_index = Program.Routines.Videos.annotations.dimensional_index;

            switch property
                case 'Position'
                    annotation(dim_index.x) = value(1);
                    annotation(dim_index.y) = value(2);
                    annotation(dim_index.z) = value(3);

                case fieldnames(dim_index)
                    annotation(dim_index.(property)) = value;
            end
        end

        function move(source_axes, annotation_id, event)            
            app = Program.app;
            dim_index = Program.Routines.Videos.annotations.dimensional_index;
            cache = Program.Routines.Videos.cache.get();
            roi_idx = find(cache.frames(:, dim_index.annotation_id) == annotation_id);
            cache.Writable = true;
            
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
            Program.Routines.Videos.cache.save(cache);
        end

        function target_annotations = target(x, y)
            persistent current_target

            if nargin == 2
                % If vertices have been passed, save them.
                current_target = struct('x', {x}, 'y', {y});

            elseif ~isempty(current_target)
                % Otherwise, grab all annotations in the cache
                cache = Program.Routines.Videos.cache.get();
                annotations = cache.frames;

                % Test whether they are located within the target polgyon
                [in, on] = inpolygon( ...
                    annotations(:, dim_index.x), annotations(:, dim_index.y), ...
                    current_target.x, current_target.y);

                % Use booleans to filter the chunk load from cache
                in_bounds = find(in || on);
                target_annotations = cache.frames(in_bounds, :);

            else
                
                target_annotations = current_target;
            end
        end

        function apply_edits()
            cache = Program.Routines.Videos.cache.get();
            rois = Program.Routines.Videos.rois.active();
            dim_index = Program.Routines.Videos.annotations.dimensional_index;

            pos = vertcat(rois.Position);
            annotation_ids = str2double({rois.Tag});
            
            frames = cache.frames;
            frames(annotation_ids, dim_index.x:dim_index.y) = pos;

            cache.frames = frames;
            Program.Routines.Videos.cache.save(cache);
        end
    end
end

