classdef Tracker < handle

    properties % Public Access
        miss_frame
        noise_level
        min_size
        beta_tk
        lambda_tk
        max_iteration
        ensemble
        adjacent
        cell_num
        cell_num_t0
        Z_RANGE_INTERP
        region_list
        region_width
        region_xyz_min
        pad_x
        pad_y
        pad_z
        label_padding
        segmentation_manual_relabels
        cells_on_boundary
        ffn_model
        val_losses
        paths
        history
        use_8_bit
    end
    
    methods(Access=public)

        function obj = Tracker(volume_num, siz_xyz, z_xy_ratio, z_scaling, noise_level, min_size, beta_tk, lambda_tk, maxiter_tk, folder_path, image_name, unet_model_file, ffn_model_file, cell_num, ensemble, adjacent, shrink, miss_frame)
            obj = obj@Segmentation(volume_num, siz_xyz, z_xy_ratio, z_scaling, shrink);

            if isempty(miss_frame)
                obj.miss_frame = [];
            else
                obj.miss_frame = miss_frame;
            end

            obj.noise_level = noise_level;
            obj.min_size = min_size;
            obj.beta_tk = beta_tk;
            obj.lambda_tk = lambda_tk;
            obj.max_iteration = maxiter_tk;
            obj.ensemble = ensemble;
            obj.adjacent = adjacent;
            obj.cell_num = cell_num;
            obj.cell_num_t0 = [];
            obj.Z_RANGE_INTERP = [];
            obj.region_list = [];
            obj.region_width = [];
            obj.region_xyz_min = [];
            obj.pad_x = [];
            obj.pad_y = [];
            obj.pad_z = [];
            obj.label_padding = [];
            obj.segmentation_manual_relabels = [];
            obj.cells_on_boundary = [];
            obj.ffn_model = [];
            obj.val_losses = [];
            obj.paths = Paths(folder_path, image_name, unet_model_file, ffn_model_file);
            obj.history = History();
            obj.paths.make_folders(adjacent, ensemble);
            obj.use_8_bit = true;
        end

        function set_tracking(obj, beta_tk, lambda_tk, maxiter_tk)

            if obj.beta_tk == beta_tk && obj.lambda_tk == lambda_tk && obj.max_iteration == maxiter_tk
                fprintf('Tracking parameters were not modified\n')
            else
                obj.beta_tk = beta_tk;
                obj.lambda_tk = lambda_tk;
                obj.max_iteration = maxiter_tk;
                fprintf('Parameters were modified: beta_tk=%d, lambda_tk=%d, maxiter_tk=%d\n', obj.beta_tk, obj.lambda_tk, obj.max_iteration)
            end
        end

        function load_manual_seg(obj)

            fprintf(obj.paths.manual_segmentation_vol1)
            segmentation_manual = load_image(obj.paths.manual_segmentation_vol1, print_=false);
            fprintf('Loaded manual _segment at vol 1\n')
            [obj.segmentation_manual_relabels, ~, ~] = relabel_sequential(segmentation_manual);
            if obj.segmentation_manual_relabels.max() > 255
                obj.use_8_bit = false;
            end
        end

        function retrain_preprocess(obj)
            obj.image_raw_vol1 = read_image_ts(1, obj.paths.raw_image, obj.paths.image_name, [0, obj.z_siz]);
            obj.train_image_norm = _normalize_image(obj.image_raw_vol1, obj.noise_level);
            obj.label_vol1 = obj._remove_2d_boundary(obj.segmentation_manual_relabels) > 0;
            obj.train_label_norm = _normalize_label(obj.label_vol1);
            fprintf('Images were normalized\n')
        
            obj.train_subimage = _divide_img(obj.train_image_norm, obj.unet_model.input_shape(2:4));
            obj.train_subcells = _divide_img(obj.train_label_norm, obj.unet_model.input_shape(2:4));
            fprintf('Images were divided\n') 
        
            image_gen = ImageDataGenerator(rotation_range=90, width_shift_range=0.2, height_shift_range=0.2, shear_range=0.2, horizontal_flip=true, fill_mode='reflect');
        
            obj.train_generator = _augmentation_generator(obj.train_subimage, obj.train_subcells, image_gen, batch_siz=8);
            obj.valid_data = [obj.train_subimage, obj.train_subcells];
            fprintf('Data for training 3D U-Net were prepared\n')
        end
        
        function labels_new = remove_2d_boundary(obj, labels3d)
            labels_new = labels3d.copy();
            for z = 1:obj.z_siz
                labels = labels_new(:, :, z);
                labels(find_boundaries(labels, mode='outer') == 1) = 0;
            end
        end

        function retrain_unet(obj, iteration, weights_name)

            if nargin < 2
                iteration = 10;
            end

            if nargin < 3
                weights_name = 'unet_weights_retrain_';
            end
        
            obj._retrain_preprocess()
        
            obj.unet_model.compile(loss='binary_crossentropy', optimizer="adam")
            obj.unet_model.load_weights(fullfile(obj.paths.unet_weights, 'weights_initial.h5'))
        
            % evaluate model prediction before retraining
            val_loss = obj.unet_model.evaluate(obj.train_subimage, obj.train_subcells);
            fprintf('val_loss before retraining: %d\n', val_loss)
            obj.val_losses = val_loss;
            obj._draw_retrain(step="before retrain")
        
            for step = 1:iteration
                obj.unet_model.fit_generator(obj.train_generator
            end
        end

        function draw_retrain(obj, step)
            % Draw the ground truth and the updated predictions during retraining the unet
            train_prediction = squeeze(...
                unet3_prediction(expand_dims(obj.train_image_norm, axis=(0, 4)), obj.unet_model));
            fig = figure;
            axs = axes(fig, 'NextPlot', 'add', 'XTick', [], 'YTick', []);
            imagesc(axs, [max(obj.label_vol1, [], 3), max(train_prediction, [], 3) > 0.5], ...
                'CDataMapping', 'scaled', 'AlphaData', 0.5)
            colormap(axs, gray)
            title(axs, ["Cell regions from manual segmentation at vol 1", ...
                sprintf("Cell prediction at step %d at vol 1", step)], ...
                'FontSize', 16, 'FontWeight', 'bold')
            pause(0.1)
        end

        function select_unet_weights(obj, step, weights_name)

            if nargin < 3
                weights_name = 'unet_weights_retrain_';
            end
        
            if step == 0
                obj.unet_model.load_weights(fullfile(obj.paths.unet_weights, 'weights_initial.h5'))
            elseif step > 0
                obj.unet_model.load_weights(fullfile(obj.paths.unet_weights, ...
                    sprintf("%sstep%d.h5", weights_name, step)));
                obj.unet_model.save(fullfile(obj.paths.unet_weights, "unet3_retrained.h5"))
            else
                error("step should be an interger >= 0")
            end
        end
    end
end




