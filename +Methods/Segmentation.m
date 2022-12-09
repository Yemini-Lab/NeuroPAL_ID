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
            obj.segresult = [];
        end
    end
end