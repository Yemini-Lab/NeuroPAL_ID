classdef Segmentation < handle
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
        
    end

    methods (Static)

        function new_disp = transform_disps(disp, factor)
            % Transform the coordinates with different units along z
            new_disp = disp;
            new_disp(:, 3) = new_disp(:, 3) * factor;
        end

    end

end
