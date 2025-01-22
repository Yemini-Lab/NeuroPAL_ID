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
            cache.Writable = true;
            
            if worldline_id > size(cache, 'worldline')
                [node, color, style, worldline_id] = Program.Routines.worldlines.add_node('Unknown');
                Program.Routines.Videos.worldlines.add(node, 'Unknown', color, style, worldline_id);
            end

            cache.frames = [cache.frames; t x y z worldline_id provenance_id size(cache.frames, 1)+1];

            cache.Writable = false;
            Program.Routines.Videos.cache.save(cache);
        end

        function target_roi = find(varargin)            
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
            dimensional_index = Program.Routines.Videos.annotations.dimensional_index;

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
    end
end

