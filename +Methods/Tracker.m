classdef Tracker < Segmentation

    % Data and methods for tracking cells
    %
    % Properties:
    %   volume_num: int
    %       The number of volumes (time points) of the 3D + T image to be tracked
    %   x_siz: int
    %   y_siz: int
    %   z_siz: int
    %       Size of each 3D image. Obtained from the siz_xyz parameter (tuple) with (x_siz:Height, y_siz:Width, z_siz:Depth)
    %   z_xy_ratio: float
    %       The resolution (length per voxels) ratio between the z axis and the x-y plane, used in tracking.
    %       Does not need to very precise
    %   z_scaling: int 
    %       An integer (>= 1) for interpolating/smoothing images along z direction.
    %       z_scaling = 1 makes no interpolation but only smoothing.
    %   noise_level: float
    %       A threshold to discriminate noise/artifacts from cell regions, used in preprocess.normalize_image function
    %   min_size: int
    %       A threshold of the minimum cell size (unit: voxels) to remove tiny regions that may be non-cell objects,
    %       used in watershed.watershed_3d function
    %   beta_tk: float
    %       Control coherence by a weighted average of movements from neighbouring cells.
    %       A larger BETA will include more cells and thus generates more coherent movements.
    %   lambda_tk: float
    %       Control coherence by applying a penalty for the incoherence of cell movements.
    %       A large LAMBDA will generates more coherent movements.
    %   maxiter_tk: int
    %       The maximum number of iterations of PR-GLS during once application of FFN + PR-GLS.
    %       A large values will generate more accurate tracking but will also increase the runtime.
    %   cell_num: int
    %       The number of cells to be extracted from watershed. It is used only when segmentation method is "cell_num".
    %       Default: 0
    %   ensemble: bool or int, optional
    %       If false, track cells in single mode. If an integer, track cells in ensemble mode.
    %       The integer indicates number of predictions to be averaged. Default: false
    %   adjacent: bool, optional
    %       Only used in ensemble mode. If true, make predictions of cell positions at t from
    %       adjacent previous volumes such as t-1, t-2, t-3,..., t-10 (when ensemble=10).
    %       If false, make prediction from distributed previous volumes. For example, predict cells at t=101 from
    %       t = 1, 11, 21, ..., 91 (when ensemble=10). Default: false
    %   shrink: tuple, optional
    %       For padding the images before applying U-Net and for shrinking the cell prediction in the center part
    %       of the U-Net output. Each value should be < (x, y, or z size of the U-Net input // 2), Default: (24, 24, 2)
    %   miss_frame: list, optional
    %       A list of volumes (int) which includes serious problem in the raw images and thus will be skipped for tracking.
    %       Default: none
    %   cell_num_t0: int
    %       The detected cell numbers in the manually corrected segmentation in volume 1
    %   Z_RANGE_INTERP: Range object
    %       The sequence of the indexes along z axis in the interpolated image corresponding to the layers in the raw image
    %   region_list: list
    %       List of the 3D sub-images [array_cell1, array_cell2, ...] with binary values
    %       (1: this cell; 0: background or other cells)
    %   region_width: list
    %       List of the width of [[x_width, y_width, z_width]_cell1, ...] each sub-image in x, y, and z axis
    %   region_xyz_min: list
    %       List of the minimum coordinates [[x_min, y_min, z_min]_cell1, ...] of each sub-image in the raw image
    %   pad_x: int
    %   pad_y: int
    %   pad_z: int
    %       The values for padding a zero array with the raw image size
    %   label_padding: numpy.ndarray
    %       A 3D array with zero values, used in accurate correction during tracking.
    %       Shape: (row + 2 * pad_x, column + 2 * pad_y, layer + 2 * pad_z)
    %   segmentation_manual_relabels: numpy.ndarray
    %       The relabeled manual segmentation. Shape: (row, column, layer)
    %   segresult: SegResults object
    %       The results of the segmentation in current volume
    %   unet_model: keras.Model
    %       The pretrained/retrained 3D U-Net model

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
            obj.train_image_norm = normalize_image(obj.image_raw_vol1, obj.noise_level);
            obj.label_vol1 = obj.remove_2d_boundary(obj.segmentation_manual_relabels) > 0;
            obj.train_label_norm = normalize_label(obj.label_vol1);
            fprintf('Images were normalized\n')
        
            obj.train_subimage = divide_img(obj.train_image_norm, obj.unet_model.input_shape(2:4));
            obj.train_subcells = divide_img(obj.train_label_norm, obj.unet_model.input_shape(2:4));
            fprintf('Images were divided\n') 
        
            image_gen = ImageDataGenerator(rotation_range=90, width_shift_range=0.2, height_shift_range=0.2, shear_range=0.2, horizontal_flip=true, fill_mode='reflect');
        
            obj.train_generator = augmentation_generator(obj.train_subimage, obj.train_subcells, image_gen, batch_siz=8);
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
        
            obj.retrain_preprocess()
        
            obj.unet_model.compile(loss='binary_crossentropy', optimizer="adam")
            obj.unet_model.load_weights(fullfile(obj.paths.unet_weights, 'weights_initial.h5'))
        
            % evaluate model prediction before retraining
            val_loss = obj.unet_model.evaluate(obj.train_subimage, obj.train_subcells);
            fprintf('val_loss before retraining: %d\n', val_loss)
            obj.val_losses = val_loss;
            obj.draw_retrain(step="before retrain")
        
            for step = 1:iteration
                obj.unet_model.fit_generator(obj.train_generator)
            end
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

        function interpolate_seg(self)
            % _interpolate layers in z axis
            self.seg_cells_interpolated_corrected = self.interpolate();
            self.Z_RANGE_INTERP = self.z_scaling / 2:self.z_scaling:self.seg_cells_interpolated_corrected.shape(3);
        
            % re-segmentation
            self.seg_cells_interpolated_corrected = self.relabel_separated_cells(self.seg_cells_interpolated_corrected);
            self.segmentation_manual_relabels = self.seg_cells_interpolated_corrected(:,:,self.Z_RANGE_INTERP);
        
            % save labels in the first volume (interpolated)
            save_img3ts(0:self.z_siz-1, self.segmentation_manual_relabels, self.paths.track_results+"track_results_t%04i_z%04i.tif", 1, self.use_8_bit);
        
            % calculate coordinates of cell centers at t=1
            center_points_t0 = snm.center_of_mass(self.segmentation_manual_relabels > 0, self.segmentation_manual_relabels, 1:self.segmentation_manual_relabels.max());
            r_coordinates_manual_vol1 = self.transform_layer_to_real(center_points_t0);
            self.r_coordinates_tracked_t0 = r_coordinates_manual_vol1;
            self.cell_num_t0 = size(r_coordinates_manual_vol1, 1);
        end

        function seg_cells_interpolated_corrected = self.interpolate()
            seg_cells_interpolated = gaussian_filter(self.segmentation_manual_relabels, z_scaling=self.z_scaling, smooth_sigma=2.5);
            seg_cell_or_bg = zeros(size(self.segmentation_manual_relabels));
            seg_cells_interpolated_corrected = watershed_2d_markers(seg_cells_interpolated, seg_cell_or_bg, z_range=self.z_siz * self.z_scaling + 10);
            seg_cells_interpolated_corrected = seg_cells_interpolated_corrected(5:self.x_siz + 5, 5:self.y_siz + 5, 5:self.z_siz * self.z_scaling + 5);
        end

        function cal_subregions(self)
            % Compute subregions of each cells for quick "accurate correction"
            seg_16 = int16(self.seg_cells_interpolated_corrected);
        
            [self.region_list, self.region_width, self.region_xyz_min] = get_subregions(seg_16, max(seg_16(:)));
            self.pad_x = max(self.region_width(:, 1));
            self.pad_y = max(self.region_width(:, 2));
            self.pad_z = max(self.region_width(:, 3));
            self.label_padding = padarray(seg_16, [self.pad_x, self.pad_y, self.pad_z], 0, 'both');
        end
        
        function check_multicells(self)
            for i = 1:numel(self.region_list)
                region = self.region_list{i};
                assert sum(unique(label(region))) == 1, sprintf('more than one cell in region %d', i);
            end
        end

        function load_ffn(self)
            self.ffn_model = load_model(fullfile(self.paths.models, self.paths.ffn_model_file));
            fprintf('Loaded the FFN model\n');
        end


        function should_stop = evaluate_correction(self, r_displacement_correction)
            % evaluate if the accurate correction should be stopped
            i_disp_test = r_displacement_correction;
            i_disp_test(:, 3) = i_disp_test(:, 3) .* self.z_scaling / self.z_xy_ratio;
            if max(abs(i_disp_test(:))) >= 0.5
                % fprintf('%f,', max(abs(i_disp_test(:))));
                should_stop = false;
            else
                % fprintf('%f\n', max(abs(i_disp_test(:))));
                should_stop = true;
            end
        end

        function tracked_labels = transform_motion_to_image(self, cells_on_boundary_local, i_disp_from_vol1_updated)
            % Transform the predicted movements to the moved labels in 3D image
            [i_tracked_cells_corrected, i_overlap_corrected] = self.transform_cells_quick(i_disp_from_vol1_updated);
            % re-calculate boundaries by _watershed
            i_tracked_cells_corrected(i_overlap_corrected > 1) = 0;
            for i = cells_on_boundary_local == 1
                i_tracked_cells_corrected(i_tracked_cells_corrected == i) = 0;
            end
            tracked_labels = watershed_2d_markers(i_tracked_cells_corrected(:,:,self.Z_RANGE_INTERP), i_overlap_corrected(:,:,self.Z_RANGE_INTERP), z_range=self.z_siz);
        end

        function save_coordinates(self)
            coord = self.history.r_tracked_coordinates;
            coord = cell2mat(coord);
            t = size(coord, 1);
            cell = size(coord, 2);
            pos = size(coord, 3);
            coord_table = [repmat(1:t, cell, 1), repmat((1:cell)', t, 1), reshape(coord, t * cell, pos)];
            dlmwrite(fullfile(self.paths.track_information, 'tracked_coordinates.csv'), coord_table, 'delimiter', ',', 'precision', 6);
            fprintf('Cell coordinates were stored in ./track_information/tracked_coordinates.csv\n');
        end


    end
end




