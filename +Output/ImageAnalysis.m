classdef ImageAnalysis
    %IMAGEANALYSIS Methods to analyze NeuroPAL images.
    
    % Analysis constants.
    properties (Constant, Access = public)
        GFP_bg_size = 5; % GFP background size (pixels squared)
    end
    
   % Public methods.
    methods (Static)
        function saveID2CSV(csvfile, prefs, data, data_zscored, neurons, um_scale)
            %SAVEID2CSV save the IDs, position, & colors to a CSV file.

            % Get the data class info & fix its class for calculations.
            data_class = class(data);
            data_max = intmax('uint16');
            if contains(data_class, 'int')
                data_max = intmax(data_class);
            end
            data = double(data);
            
            % Get the GFP channel & info.
            GFP_i = prefs.GFP;
            if isnan(GFP_i)
                GFP_image = nan(size(data,1:3));
            else
                GFP_image = squeeze(data(:,:,:,GFP_i));
            end
            
            % Compute the z-score info.
            GFP_mean = nan;
            GFP_std = nan;
            if ~isnan(GFP_i)
                GFP_mean = mean(GFP_image, 'all');
                GFP_std = std(GFP_image, 0, 'all');
            end
            RGBW = prefs.RGBW;
            RGBW_mean = nan(1,length(RGBW));
            RGBW_std = nan(1,length(RGBW));
            for i = 1:length(RGBW)
                RGBW_mean(i) = mean(data(:,:,:,RGBW(i)), 'all');
                RGBW_std(i) = std(data(:,:,:,RGBW(i)), 0, 'all');
            end
            
            % Measure the 8 image corners to determine an appropriate
            % GFP background threshold.
            %GFP_bg_size = Output.ImageAnalysis.GFP_bg_size;
            %[x,y,z] = size(GFP_image);
            %x1 = 1:GFP_bg_size;
            %x2 = (x - GFP_bg_size + 1):x;
            %y1 = 1:GFP_bg_size;
            %y2 = (y - GFP_bg_size + 1):y;
            %z1 = 1;
            %z2 = z;
            %corner(1) = median(GFP_image(x1,y1,z1), 'all');
            %corner(2) = median(GFP_image(x2,y1,z1), 'all');
            %corner(3) = median(GFP_image(x1,y2,z1), 'all');
            %corner(4) = median(GFP_image(x1,y1,z2), 'all');
            %corner(5) = median(GFP_image(x2,y2,z1), 'all');
            %corner(6) = median(GFP_image(x2,y1,z2), 'all');
            %corner(7) = median(GFP_image(x1,y2,z2), 'all');
            %corner(8) = median(GFP_image(x2,y2,z2), 'all');
            %min_corner = min(corner);
            %std_corner = std(corner);
            
            % Use the 5th percentile to determine an appropriate
            % GFP background threshold.
            GFP_bg = prctile(GFP_image(:), 5);
            GFP_bg_std = std(GFP_image(GFP_image <= GFP_bg), 0, 'all');
            
            % Take a minimal patch around the neuron center.
            % Note: we need to walk a thin line of being robust against
            % off-center dots, while not violating neighboring neurons.
            cube_size = [2,2,0];
            % Take a 1 micron radius around the neuron centers.
            % Note: users are way too sloppy for us to use this :(
            %cube_size = round([1,1,1] ./ um_scale');
            
            % Measure the GFP channel for the neurons.
            intensity_prctile = 50;
            ns = neurons.neurons;
            GFP_max = nan(length(ns),1);
            GFP_intensity = nan(length(ns),1);
            GFP_norm = nan(length(ns),1);
            for i=1:length(ns)
                cpatch = Methods.Utils.subcube(GFP_image, ...
                    round(ns(i).position), cube_size);
                GFP_max(i) = max(cpatch(:));
                thresh = prctile(cpatch(:), intensity_prctile);
                GFP_intensity(i) = nanmean(cpatch(cpatch >= thresh), 'all');
                GFP_norm(i) = GFP_intensity(i) / ns(i).color_readout(4);
            end
            %GFP_Z_max = (GFP_max - GFP_mean) ./ GFP_std;
            %GFP_Z_intensity = (GFP_intensity - GFP_mean) ./ GFP_std;
            
            % Compute an appropriate GFP Otsu threshold.
            is_GFP_nan = all(isnan(GFP_intensity));
            otsu_thresh = nan;
            otsu_score = nan;
            if ~is_GFP_nan
                min_GFP = nanmin(GFP_intensity);
                scaled_GFP = double(GFP_intensity) - min_GFP;
                max_GFP = nanmax(GFP_intensity);
                scaled_GFP = scaled_GFP ./ max_GFP;
                [otsu_thresh, otsu_score] = graythresh(scaled_GFP);
                otsu_thresh = otsu_thresh * max_GFP + min_GFP;
            end
            
            % Compute an appropriate GFP linear change threshold.
            change_thresh = nan;
            change_residual = nan;
            if ~is_GFP_nan
                GFP_sorted = sort(GFP_intensity);
                [change_point, change_residual] = findchangepts(GFP_sorted, ...
                    'MaxNumChanges', 1, 'Statistic', 'linear');
                change_thresh = nan;
                change_i = round(change_point);
                if ~isempty(change_i) && ...
                        change_i > 1 && change_i < length(GFP_sorted)
                    change_thresh = GFP_sorted(change_i);
                end
            end

            % Get the aligned neuron data.
            aligned_xyzRGBs = neurons.get_aligned_xyzRGBs();
            %if ~isempty(aligned_xyzRGBs)
                
                % Get the real neuron colors.
                %neuron_RGBWs = neurons.get_colors_readout();
                %neuron_RGBs = neuron_RGBWs(:,[1 2 3]);
            
                % Find transformation between original and aligned data.
                %beta_col = linsolve([neuron_RGBs ones(size(neuron_RGBs,1),1)],...
                %    [aligned_xyzRGBs(:,4:end) ones(size(neuron_RGBs,1),1)]);
                %aligned_colors_rgb = [neuron_RGBWs(:,[1,2,3]) ones(size(neuron_RGBWs,1),1)]*beta_col;
                %aligned_colors_rab = [neuron_RGBWs(:,[1,4,3]) ones(size(neuron_RGBWs,1),1)]*beta_col;
                %aligned_colors = [aligned_colors_rgb(:,1:3), aligned_colors_rab(:,2)];
            %end
            
            % Open the file.
            fileID = fopen(csvfile, 'w');
            
            % Write the background and Otsu thresholds.
            fprintf(fileID, ['Atlas Version,,' ...
                'Pixel Type,Max Pixel Value,,' ...
                'GFP Background,GFP Background S.D.,,' ...
                'GFP Otsu Threshold (Estimated),GFP Otsu Score (Estimated),,' ...
                'GFP Linear Change Point (Estimated),GFP Change Residual (Estimated)\n']);
            fprintf(fileID, '%f,,%s,%d,,%f,%f,,%f,%f,,%f,%f\n\n', ...
                neurons.atlas_version, data_class, data_max, ...
                GFP_bg, GFP_bg_std, otsu_thresh, otsu_score, ...
                change_thresh, change_residual);
            
            % Write the z-score information.
            fprintf(fileID, ['Z-Score Info,,' ...
                'Red Channel,Green Channel,Blue Channel,White Channel,,' ...
                'GFP Channel\n']);
            fprintf(fileID, 'Mean,,%f,%f,%f,%f,,%f\n', ...
                RGBW_mean(1), RGBW_mean(2), RGBW_mean(3), RGBW_mean(4), ...
                GFP_mean);
            fprintf(fileID, 'S.D.,,%f,%f,%f,%f,,%f\n\n', ...
                RGBW_std(1), RGBW_std(2), RGBW_std(3), RGBW_std(4), ...
                GFP_std);
            
            % Determine the header output.
            id_str = 'User ID,User Confidence,Emphasized?,Auto ID,Auto Confidence,,';
            real_position_str = 'Real X (um),Real Y (um),Real Z (um),,';
            real_color_str = 'Z-Scored Red,Z-Scored Green,Z-Scored Blue,Z-Scored White,,';
            aligned_position_str = [];
            aligned_color_str = [];
            aligned_GFP_str = [];
            if ~isempty(aligned_xyzRGBs)
                aligned_position_str = 'Aligned X (um),Aligned Y (um),Aligned Z (um),,';
                aligned_color_str = 'Aligned Red,Aligned Green,Aligned Blue,,';
                aligned_GFP_str = 'Pseudo-Aligned GFP,';
            end
            GFP_str = 'Estimated GFP,Max GFP,Normalized GFP,';
            out_str = [id_str, real_position_str, real_color_str, ...
                aligned_position_str, aligned_color_str, GFP_str, ...
                aligned_GFP_str, '\n'];
            
            % Determine the data output.
            id_fmt = '%s,%f,%d,%s,%f,,';
            real_position_fmt = '%f,%f,%f,,';
            real_color_fmt = '%f,%f,%f,%f,,';
            aligned_position_fmt = [];
            aligned_color_fmt = [];
            aligned_GFP_fmt = [];
            if ~isempty(aligned_xyzRGBs)
                aligned_position_fmt = '%f,%f,%f,,';
                aligned_color_fmt = '%f,%f,%f,,';
                aligned_GFP_fmt = '%f,';
            end
            GFP_fmt = '%f,%f,%f,';
            out_fmt = [id_fmt, real_position_fmt, real_color_fmt, ...
                aligned_position_fmt, aligned_color_fmt, GFP_fmt, ...
                aligned_GFP_fmt, '\n'];
            
            % Sort the neurons by position.
            % Note: x & y are reversed.
            positions = neurons.get_positions();
            positions = positions(:,[2,1,3]);
            [~, sort_i] = sortrows(positions);
            ns = ns(sort_i);
            GFP_max = GFP_max(sort_i);
            GFP_intensity = GFP_intensity(sort_i);
            GFP_norm = GFP_norm(sort_i);
            
            % Write the neurons.
            um_scale = um_scale';
            fprintf(fileID, out_str);
            for i = 1:length(ns)
                n = ns(i);

                if size(um_scale,1) > size(um_scale,2)
                    pos = n.position .* um_scale';
                else
                    pos = n.position .* um_scale;
                end

                % Determine the auto IDs.
                probabilistic_id = [];
                probabilistic_prob = [];
                if ~isempty(n.probabilistic_ids)
                    probabilistic_id = n.probabilistic_ids{1};
                    probabilistic_prob = n.probabilistic_probs(1);
                end

                % Write the real data only.
                if isempty(aligned_xyzRGBs)
                    fprintf(fileID, out_fmt, ...
                        n.annotation, n.annotation_confidence, ...
                        n.is_emphasized, ...
                        probabilistic_id, probabilistic_prob, ...
                        pos(2), pos(1), pos(3), ...
                        n.color_readout(1), n.color_readout(2), ...
                        n.color_readout(3), n.color_readout(4), ...
                        GFP_intensity(i), GFP_max(i), GFP_norm(i));
                    
                % Write the real & aligned data.
                else
                    
                    % Does this neuron have aligned data?
                    aligned_pos = nan(1,3);
                    aligned_RGB = nan(1,3);
                    aligned_GFP = nan;
                    if ~isempty(n.aligned_xyzRGB)
                        aligned_pos = n.aligned_xyzRGB(1:3);
                        aligned_RGB = n.aligned_xyzRGB(4:6);
                        aligned_GFP = GFP_intensity(i) * ...
                            (aligned_RGB(2) / n.color_readout(2));
                    end
                    
                    % Write the real & aligned data.
                    fprintf(fileID, out_fmt, ...
                        n.annotation, n.annotation_confidence, ...
                        n.is_emphasized, ...
                        probabilistic_id, probabilistic_prob, ...
                        pos(2), pos(1), pos(3), ...
                        n.color_readout(1), n.color_readout(2), ...,
                        n.color_readout(3), n.color_readout(4), ...
                        aligned_pos(1), aligned_pos(2), aligned_pos(3), ...
                        aligned_RGB(1), aligned_RGB(2), aligned_RGB(3), ...
                        GFP_intensity(i), GFP_max(i), GFP_norm(i), ...
                        aligned_GFP);
                end
            end
            
            % Done.
            fclose(fileID);
        end
    end
end
