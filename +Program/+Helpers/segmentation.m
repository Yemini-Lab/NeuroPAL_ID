classdef segmentation
    %SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = segmentation(inputArg1,inputArg2)
            %SEGMENTATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function boundingBox = get_roi()
            % Initialize variables to store bounding box coordinates
            boundingBox = struct('minRow', Inf, 'maxRow', -Inf, 'minCol', Inf, 'maxCol', -Inf);
            
            % Find the bounding box excluding areas with all pixels equal to zero
            for n = min(app.zSlicesListBox.Value):max(app.zSlicesListBox.Value)
                subdata = app.image_data(:,:,n,chan_array);
                subdata = squeeze(subdata);
                subdata = max(subdata,[],3); % Take max value of RGB channels as intensity
                % Update bounding box coordinates
                [row, col] = find(subdata > 0);
                boundingBox.minRow = min(boundingBox.minRow, min(row));
                boundingBox.maxRow = max(boundingBox.maxRow, max(row));
                boundingBox.minCol = min(boundingBox.minCol, min(col));
                boundingBox.maxCol = max(boundingBox.maxCol, max(col));
            end
        end

        function save_thumbnails()
            bounds = Program.Helpers.segmentation.get_roi;

            % Save slices as TIF files within the bounding box
            for n = min(app.zSlicesListBox.Value):max(app.zSlicesListBox.Value)
                name = join([app.data_path, 'npal_','worm_','c1_',int2str(n-min(app.zSlicesListBox.Value)), '.tif']);
                subdata = app.image_data( ...
                    bounds.minRow:bounds.maxRow, ...
                    bounds.minCol:bounds.maxCol, ...
                    n, chan_array);

                subdata = squeeze(subdata);
                subdata = max(subdata,[],3); % Take max value of RGB channels as intensity
                subdata = uint8(subdata*1.2); % Convert to 8-bit integer

                imwrite(subdata, name, 'tif', 'WriteMode', 'overwrite');
            end
        end
    end

    methods (Static, Access = private)
        function path_struct = paths()
            persistent current_paths

            if isempty(current_paths)
                current_paths = struct( ...
                    'model', fullfile(), ...
                    'unet', fullfile(), ...
                    'weights', fullfile());
            end

            path_struct = current_paths;
        end
    end
end

