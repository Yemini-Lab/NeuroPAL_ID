classdef segmentation
    %SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        default_pct = 90;
    end
    
    methods (Static)
        function obj = paths()
            persistent segmentation_paths

            if isempty(segmentation_paths)
                p_cache = fullfile(Program.Handlers.pathing.file_dir, 'seg_data');
                p_data = fullfile(p_cache, 'data');
                p_results = fullfile(p_cache, 'auto_vol1');

                p_model = fullfile(p_cache, 'models');
                p_unet = fullfile(p_model, 'unet');
                p_weights = fullfile(p_model, 'unet-weights');

                segmentation_paths = struct( ...
                    'cache', {p_cache}, ...
                    'data', {p_data}, ...
                    'model', {p_model}, ...
                    'unet', {p_unet}, ...
                    'weights', {p_weights}, ...
                    'results', {p_results});
            end

            obj = segmentation_paths;
        end

        function noise_level = get_roi_noise()
            app = Program.GUIHandling.app;
            render_bools = Program.GUIHandling.active_channels;
            channel_idx = Program.GUIHandling.ordered_channels;

            uiwait(msgbox('Click and drag your cursor on the image to select a region and calculate its average intensity.','Instructions'))
            roi = drawfreehand(app.ImageAxes,'Color','black','StripeColor','m');
            mask = createMask(roi,app.image_view);

            roi_volume = app.image_data(:, :, round(app.Slider.Value), channel_idx(render_bools));
            roi_mean = mean(roi_volume, 4);
            noise_level = mean(roi_mean(mask))*100;

            delete(roi);
        end
        
        function noise_level = get_noise()
            app = Program.GUIHandling.app;
            render_bools = Program.GUIHandling.active_channels;
            channel_idx = Program.GUIHandling.ordered_channels;

            render_volume = app.image_data(:, :, :, channel_idx(render_bools));
            render_volume = double(render_volume(:));
            
            noise_level = prctile(render_volume, Program.Handlers.segmentation.default_pct);
        end
    end
end

