classdef rois
    
    properties
    end
    
    methods (Static, Access = public)

        function target_annotations = target(x, y)
            persistent current_target

            if nargin == 2
                % If vertices have been passed, save them.
                current_target = struct('x', {x}, 'y', {y});

            elseif ~isempty(current_target)
                app = Program.app;
                rois = findobj(app.xyAxes, 'Type','images.roi.Point');

                % Test whether they are located within the target polgyon
                [in, on] = inpolygon( ...
                    rois(:, dim_index.x), rois(:, dim_index.y), ...
                    current_target.x, current_target.y);

                % Use booleans to filter the chunk load from cache
                in_bounds = find(in || on);
                target_annotations = rois(in_bounds);

            else
                
                target_annotations = current_target;
            end
        end
        
        function batch_edit(varargin)
            p = inputParser;

            addOptional(p, 'x', []);
            addOptional(p, 'y', []);
            addOptional(p, 'z', []);

            addOptional(p, 'dx', []);
            addOptional(p, 'dy', []);
            addOptional(p, 'dz', []);

            addOptional(p, 'macro', []);

            parse(p, varargin{:});
            inputs = p.Results; args = fieldnames(inputs);
            app = Program.app;

            rois = Program.Routines.Videos.rois.target();
            if isempty(rois)
                rois = findobj(app.xyAxes, 'Type','images.roi.Point');
            end

            for a=1:length(args)
                arg = args{a};
                input = inputs.(arg);

                if ~isempty(input)
                    pos = vertcat(rois.Position);
    
                    if ~strcmp(arg, 'macro')
                        if startsWith(arg, 'd')
                            dim = 1 + strcmp(arg(2:end), 'y');
                            pos(:, dim) = pos(:, dim) + input;
                        else
                            dim = 1 + strcmp(arg, 'y');
                            pos(:, dim) = input;
                        end
    
                    else
                        macro_code = split(input, '_');
                        pc_pos = Program.Helpers.calc_point_cloud_bbox(pos);
        
                        switch macro_code{1}
                            case 'flip'
                                switch macro_code{2}
                                    case 'ud'
                                        pc_pos.xy(:, 2) = pc_pos.xy(:, 2) - (pc_pos.xy(:, 2) - pc_pos.vertical_center)*2;
                                    case 'lr'
                                        pc_pos.xy(:, 1) = pc_pos.xy(:, 1) + (pc_pos.horizontal_center - pc_pos.xy(:, 1))*2;
                                end
        
                            case 'center'
                                switch macro_code{2}
                                    case 'hor'
                                        pc_pos.xy(:, 1) = pc_pos.xy(:, 1) + (app.video_info.nx/2 - pc_pos.horizontal_center);
                                    case 'vert'
                                        pc_pos.xy(:, 2) = pc_pos.xy(:, 2) + (app.video_info.ny/2 - pc_pos.vertical_center);
                                end

                            case 'deform'
                                switch macro_code{2}
                                    case 'width'
                                        pc_pos.xy(:, 1) = (pc_pos.xy(:, 1)/pc_pos.width) * app.WidthSpinner.Value;

                                    case 'height'
                                        pc_pos.xy(:, 2) = (pc_pos.xy(:, 2)/pc_pos.height) * app.HeightSpinner.Value;

                                    case 'scale'
                                        pc_pos.xy(:, 1) = (pc_pos.xy(:, 1)/pc_pos.width) * app.WidthSpinner.Value;
                                        pc_pos.xy(:, 2) = (pc_pos.xy(:, 2)/pc_pos.height) * app.HeightSpinner.Value;

                                end
        
                            case 'rotate'
                                app = Program.app;
                                theta = app.RotateEditField.Value;
                                
                                if strcmp(macro_code{2}, 'ccw')
                                    theta = theta * -1;
                                end
        
                                pc_pos.xy = Program.Helpers.rotate_xy_arr(pc_pos.xy, theta);
                        end

                        pos = pc_pos.xy;
                    end
    
                    pos = num2cell(pos, 2);
                    [rois.Position] = deal(pos{:});

                end
            end
        end
    end
end

