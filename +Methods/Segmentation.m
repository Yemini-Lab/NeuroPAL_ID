classdef Segmentation
    % Class for segmentation. Only use it through the Tracker instance.
    
    properties
        volume_num
        x_siz
        y_siz
        z_siz
        z_xy_ratio
        z_scaling
        shrink
        noise_level
        min_size
        vol
        paths
        unet_model
        r_coordinates_segment_t0
        segresult
    end
    
    methods

        function obj = Segmentation(volume_num, siz_xyz, z_xy_ratio, z_scaling, shrink)
            obj.volume_num = volume_num;
            obj.x_siz = siz_xyz(1);
            obj.y_siz = siz_xyz(2);
            obj.z_siz = siz_xyz(3);
            obj.z_xy_ratio = z_xy_ratio;
            obj.z_scaling = z_scaling;
            obj.shrink = shrink;
            obj.noise_level = [];
            obj.min_size = [];
            obj.vol = [];
            obj.paths = [];
            obj.unet_model = [];
            obj.r_coordinates_segment_t0 = [];
            obj.segresult = SegResults();
        end

        function set_segmentation(obj, noise_level, min_size, del_cache)

            % Set the segmentation parameters
            % If parameters changed or if reset_=True, delete cached segmentation.
            %
            % Parameters
            % ----------
            % noise_level : float, optional
            %     Modify the attribute "noise_level" to this value. If None, no modification occur. Default: None
            % min_size : int, optional
            %     Modify the attribute "min_size" to this value. If None, no modification occur. Default: None
            % del_cache : bool, optional
            %     If True, delete all cached segmentation files under "/unet" folder. Default: False
            
            if obj.noise_level == noise_level && obj.min_size == min_size
                fprintf("Segmentation parameters were not modified\n")

            elseif isempty(noise_level) && isempty(min_size)
                fprintf("Segmentation parameters were not modified\n")

            else
                
                if ~isempty(noise_level)
                    obj.noise_level = noise_level;
                end

                if ~isempty(min_size)
                    obj.min_size = min_size;
                end

                fprintf("Parameters were modified: noise_level=%f, min_size=%d\n", obj.noise_level, obj.min_size)
                files = dir(obj.paths.unet_cache);

                for i = 1:length(files)
                    delete(fullfile(obj.paths.unet_cache, files(i).name));
                end

                fprintf("All files under /unet folder were deleted\n")
            end

            if del_cache
                files = dir(obj.paths.unet_cache);

                for i = 1:length(files)
                    delete(fullfile(obj.paths.unet_cache, files(i).name));
                end

                fprintf("All files under /unet folder were deleted\n")
            end
        end

        function r_disp = transform_layer_to_real(obj, voxel_disp)
            % Transform the coordinates from layer to real
            r_disp = obj.transform_disps(voxel_disp, obj.z_xy_ratio);
        end
        
        function i_disp = transform_real_to_interpolated(obj, r_disp)
            % Transform the coordinates from real to interpolated
            i_disp = round(obj.transform_disps(r_disp, obj.z_scaling / obj.z_xy_ratio));
        end
        
        function l_disp = transform_real_to_layer(obj, r_disp)
            % Transform the coordinates from real to layer
            l_disp = round(obj.transform_disps(r_disp, 1 / obj.z_xy_ratio));
        end
        
        function l_disp = transform_interpolated_to_layer(obj, i_disp)
            % Transform the coordinates from interpolated to layer
            l_disp = round(obj.transform_disps(i_disp, 1 / obj.z_scaling));
        end
        
        function load_unet(obj)
            % Load the pretrained unet model (keras Model file like "xxx.h5") and save its weights for retraining
            obj.unet_model = load_model(fullfile(obj.paths.models, obj.paths.unet_model_file));
            obj.unet_model.save_weights(fullfile(obj.paths.unet_weights, 'weights_initial.h5'));
            fprintf("Loaded the 3D U-Net model\n")
        end

        function segment_vol1(self, method)
            if nargin < 2
                method = "min_size";
            end
        
            self.vol = 1;
            [image_cell_bg, l_center_coordinates, segmentation_auto, image_gcn, r_coordinates_segment] = ...
                self._segment(self.vol, method, true);
            self.segresult.update_results(image_cell_bg, l_center_coordinates, segmentation_auto, image_gcn, r_coordinates_segment);
            self.r_coordinates_segment_t0 = self.segresult.r_coordinates_segment.copy();
            use_8_bit = true;
            if self.segresult.segmentation_auto.max() <= 255
                use_8_bit = false;
            end
        
            % save the segmented cells of volume #1
            save_img3(z_siz=self.z_siz, img=self.segresult.segmentation_auto, ...
                      path=self.paths.auto_segmentation_vol1 + "auto_t%04i_z%04i.tif", use_8_bit=use_8_bit);
            fprintf("Segmented volume 1 and saved it\n");
        end

        function [image_cell_bg, l_center_coordinates, segmentation_auto, image_gcn, r_coordinates_segment] = segment(self, vol, method, print_shape)
            if nargin < 4
                print_shape = false;
            end
        
            image_raw = read_image_ts(vol, self.paths.raw_image, self.paths.image_name, [0, self.z_siz], 'print_', print_shape);
        
            % image_gcn will be used to correct tracking results
            image_gcn = image_raw.copy() / 65536.0;
            image_cell_bg = self._predict_cellregions(image_raw, vol);
            if max(image_cell_bg(:)) <= 0.5
                error("No cell was detected by 3D U-Net! Try to reduce the noise_level.");
            end
        
            % segment connected cell-like regions using _watershed
            segmentation_auto = self._watershed(image_cell_bg, method);
            if max(segmentation_auto(:)) == 0
                error("No cell was detected by watershed! Try to reduce the min_size.");
            end
        
            % calculate coordinates of the centers of each segmented cell
            l_center_coordinates = snm.center_of_mass(segmentation_auto > 0, segmentation_auto, 1:segmentation_auto.max() + 1);
            r_coordinates_segment = self._transform_layer_to_real(l_center_coordinates);
        end

        function image_cell_bg = predict_cellregions(self, image_raw, vol)
            % Predict cell regions by 3D U-Net and save it if the prediction has not been cached
            try
                image_cell_bg = load(self.paths.unet_cache + "t%04i.npy", '-mat', 'vol');
            catch
                image_cell_bg = self.save_unet_regions(image_raw, vol);
            end
        end

        function image_cell_bg = save_unet_regions(self, image_raw, vol)
            % Predict the cell regions by 3D U-Net and cache the prediction
            % pre-processing: local contrast normalization
            image_norm = expand_dims(_normalize_image(image_raw, self.noise_level), [1, 5]);
            % predict cell-like regions using 3D U-net
            image_cell_bg = unet3_prediction(image_norm, self.unet_model, 'shrink', self.shrink);
            save(self.paths.unet_cache + "t%04i.npy", '-v7.3', '-mat', 'vol', 'image_cell_bg');
        end

        function segmentation_auto = watershed(self, image_cell_bg, method)
            % Segment the cell regions by watershed method
            [image_watershed2d_wo_border, ~] = watershed_2d(image_cell_bg(1, :, :, :, 1), 'z_range', self.z_siz, 'min_distance', 7);
            [~, image_watershed3d_wi_border, min_size, cell_num] = watershed_3d(image_watershed2d_wo_border, 'samplingrate', [1, 1, self.z_xy_ratio], 'method', method, 'min_size', self.min_size, 'cell_num', self.cell_num, 'min_distance', 3);
            [segmentation_auto, fw, inv] = relabel_sequential(image_watershed3d_wi_border);
            self.min_size = min_size;

            if strcmp(method, "min_size")
                self.cell_num = cell_num;
            end

        end
    end

    methods (Static)

        function new_disp = transform_disps(disp, factor)
            % Transform the coordinates with different units along z
            new_disp = disp;
            new_disp(:, 3) = new_disp(:, 3) * factor;
        end

    end

end
