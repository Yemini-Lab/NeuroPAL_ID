classdef ChunkyMethods
    % Processing functions that support lazy read/write.

    %% Public variables.
    properties (Access = public)
    end

    methods (Static)

        function [new_dims, og_dims] = calc_pp_size(app, action, vol)
            % Calculate the post-processing dimensions of a volume.

            if isa(vol, 'matlab.io.MatFile')
                og_dims = size(vol, 'data');
            else
                og_dims = size(vol);
            end

            switch action
                case 'crop'
                    new_dims = og_dims;

                    if app.ProcColormapButton.Value
                        new_dims(1:2) = [app.volume_crop_roi(4)+1 app.volume_crop_roi(3)+1];
                    elseif app.ProcVideoButton.Value
                        new_dims(1:2) = [app.video_crop_roi(4)+1 app.video_crop_roi(3)+1];
                    end

                case 'ds'
                    new_dims = og_dims;
                    new_dims(1:2) = new_dims(1:2)*app.ProcXYFactorEditField.Value;
                    new_dims(3) = app.ProcZSlicesEditField.Value;

                case {'hori', 'vert', 'cc', 'acc'}
                    temp_arr = zeros(og_dims);

                    switch action
                        case 'hori'
                            temp_arr = temp_arr(:,end:-1:1,end:-1:1,:,:);
                        case 'vert'
                            temp_arr = temp_arr(end:-1:1,:,end:-1:1,:,:);
                        case 'cc'
                            temp_arr = permute(temp_arr, [2,1,3,4]);
                            temp_arr = temp_arr(:,end:-1:1,:,:,:);
                        case 'acc'
                            temp_arr = permute(temp_arr, [2,1,3,4]);
                            temp_arr = temp_arr(end:-1:1,:,:,:,:);
                    end

                    new_dims = og_dims;
                    new_dims(1:2) = [size(temp_arr, 1) size(temp_arr, 2)];
                    delete(temp_arr);

                otherwise
                    new_dims = og_dims;
            end
        end

        function output_slice = apply_slice(app, action, slice)
            % Apply operation to a slice.
            RGBW = [str2num(app.ProcRDropDown.Value), str2num(app.ProcGDropDown.Value), str2num(app.ProcBDropDown.Value), str2num(app.ProcWDropDown.Value)];
            
            switch action
                case 'zscore'
                    output_slice = Methods.Preprocess.zscore_frame(slice); 
                case 'histmatch'
                    slice(:, :, :, RGBW(1:3)) = Methods.run_histmatch(slice, RGBW);
                    output_slice = Methods.Preprocess.zscore_frame(slice);     
                case 'crop'
                    if app.ProcColormapButton.Value
                        crop_roi = app.volume_crop_roi;
                    elseif app.ProcVideoButton.Value
                        crop_roi = app.video_crop_roi;
                    end

                    left_crop = round(crop_roi(1));
                    right_crop = round(crop_roi(1)+crop_roi(3));
                    top_crop = round(crop_roi(2));
                    bottom_crop = round(crop_roi(2)+crop_roi(4));

                    output_slice = slice(top_crop:bottom_crop, left_crop:right_crop, :, :);

                case 'hori'
                    output_slice = slice(:,end:-1:1,end:-1:1,:,:);

                case 'vert'
                    output_slice = slice(end:-1:1,:,end:-1:1,:,:);

                case 'cc'
                    temp_slice = permute(slice, [2,1,3,4]);
                    output_slice = temp_slice(:,end:-1:1,:,:,:);

                case 'acc'
                    temp_slice = permute(slice, [2,1,3,4]);
                    output_slice = temp_slice(end:-1:1,:,:,:,:);

                case 'ds'
                    temp_slice = imresize(slice,[size(slice, 1)*app.ProcXYFactorEditField.Value size(slice, 2)*app.ProcXYFactorEditField.Value]);
                    target_slices = Methods.ChunkyMethods.proc_target_slices(size(temp_slice, 3), app.ProcZSlicesEditField.Value);
                    output_slice = temp_slice(:, :, target_slices, :);

                case 'debleed'
                    % TBD
            end            
        end

        function processed_vol = apply_vol(app, action, vol, progress)
            % Apply operation to a volume.

            switch action
                case 'debleed'
                    processed_vol = Methods.ChunkyMethods.debleed(app, vol);

                otherwise
                    [new_dims, old_dims] = Methods.ChunkyMethods.calc_pp_size(app, action, vol);

                    % Initialize cache array.
                    processed_vol = zeros(new_dims);
    
                    % Iterate over slices.
                    for z=1:old_dims(3)
                        if exist('progress', 'var')
                            progress.Value = z/old_dims(3);   
                        end
    
                        % Grab slice.
                        if isa(vol, 'matlab.io.MatFile')
                            slice = app.proc_image.data(:, :, z, :);
                        else
                            slice = vol(:, :, z, :);
                        end
    
                        % Apply operation.
                        slice = Methods.ChunkyMethods.apply_slice(app, action, slice);
    
                        % Update appropriate slice in cache array.
                        processed_vol(:, :, z, :) = slice;
                    end
            end            
        end

        function apply_colormap(app, actions, progress)
            % Apply set of operations to a colormap.

            % Calculate new colormap dimensions
            new_dims = size(app.proc_image, 'data');
            for a=1:length(actions)
                new_dims = Methods.ChunkyMethods.calc_pp_size(app, actions{a}, zeros(new_dims));
            end

            for a=1:length(actions)
                if exist('progress', 'var')
                    progress.Value = a/length(actions);
                end

                processed_vol = Methods.ChunkyMethods.apply_vol(app, actions{a}, processed_vol);
            end
    
            % Save to file.
            app.proc_image.Properties.Writable = true;
            app.proc_image.data = processed_vol;
            app.proc_image.Properties.Writable = false;
        end

        function apply_video(app, actions, progress)
            % Apply set of operations to a video.

            % ...Set up necessary paths.
            ppath = fileparts(app.video_path); % Get current file's parent path.
            temp_path = sprintf('%s/cache_video.h5', ppath); % Create cache file to which we'll be writing.
            processed_path = sprintf('%s/processed_video.h5', ppath); % Create new video file to avoid overwriting original.

            % If a cache file already exists, delete it.
            if exist(temp_path, 'file')==2
                delete(temp_path);
            end

            % Calculate new video dimensions
            new_dims = size(app.retrieve_frame(1));
            for a=1:length(actions)
                action = actions{a};
                new_dims = Methods.ChunkyMethods.calc_pp_size(app, action, zeros(new_dims));
            end

            % Create the cache file we'll be writing to chunk-by-chunk.
            h5create(temp_path, '/data', [new_dims(2) new_dims(1) new_dims(3:end)], "Chunksize", [new_dims(2) new_dims(1) new_dims(3:4) 1]);

            for t=1:nt
                if exist('progress', 'var')
                    progress.Value = t/nt;
                end

                processed_frame = app.retrieve_frame(app.proc_tSlider.Value);

                for a=1:length(actions)
                    if exist('progress', 'var')
                        progress.Value = min((t+a/length(actions))/nt, 1);
                    end
                    processed_frame = Methods.ChunkyMethods.apply_vol(app, actions{a}, processed_frame);
                end

                % Ensure cache frame retains time dimension.
                write_size = [size(processed_frame) 1];
                processed_frame = reshape(processed_frame, write_size);

                % Write cache frame to cache file.
                h5write(temp_path, '/data', processed_frame, [1 1 1 1 t], write_size);
            end

            if exist(processed_path, 'file')==2
                delete(processed_path);
            end

            movefile(temp_path, processed_path);
            app.video_info.file = processed_path;
            app.proc_swap_video();
        end

        function spectral_unmix(app, ctx)
            % Remove spectral crosstalk of images based on a linear spectral crosstalk remover.
            
            % Grab parent app & lock image processing tab.
            channel = ctx.Source.Tag;
            app.proc_lock('lock');

            % Check if we've saved unmixing parameters. If not, initialize.
            if ~exist('app.spectral_cache', 'var')
                app.spectral_cache = struct('ch_db', [], 'ch_px', {}, 'ch_val', {}, 'bg_px', [], 'bg_val', [], 'blurred_img', []);
            end

            % Grab channel indices.
            ch_idx = [app.RDropDown.Value, app.GDropDown.Value, app.BDropDown.Value, app.WDropDown.Value];

            check = uiconfirm(app.UIFigure,sprintf('Click on the pixel on this slice that best represents %s.', channel),'Confirmation','Options',{'OK', 'Select different slice'},'DefaultOption','OK');

            switch check
                case 'OK'
                    color_roi = drawpoint(app.proc_xyAxes);
                    pos = round(color_roi.Position);
                    delete(color_roi);

                    pixels = [pos(1), pos(2), round(app.proc_zSlider.Value)];

                    r = impixel(app.image_data(:,:,app.proc_zSlider.Value, ch_idx(1)), pos(1), pos(2));
                    g = impixel(app.image_data(:,:,app.proc_zSlider.Value, ch_idx(2)), pos(1), pos(2));
                    b = impixel(app.image_data(:,:,app.proc_zSlider.Value, ch_idx(3)), pos(1), pos(2));

                    switch channel
                        case 'r'
                            t_idx = ch_idx(1);
                            app.red_r.Value = r(1);
                            app.red_g.Value = g(1);
                            app.red_b.Value = b(1);
                        case 'g'
                            t_idx = ch_idx(2);
                            app.green_r.Value = r(1);
                            app.green_g.Value = g(1);
                            app.green_b.Value = b(1);
                        case 'b'
                            t_idx = ch_idx(3);
                            app.blue_r.Value = r(1);
                            app.blue_g.Value = g(1);
                            app.blue_b.Value = b(1);
                        case {'w', 'gfp', 'dic', 'gut'}
                            % TBD
                    end

                    if ~ismember(channel, app.spectral_cache.ch_db)
                        app.spectral_cache.ch_db = [app.spectral_cache.ch_db, t_idx];
                    end

                    app.spectral_cache.ch_px{t_idx} = pixels;

                case 'Select different slice'
                    app.proc_lock('unlock');
                    return
            end

            % If necessary, grab background.
            if ~isempty(app.spectral_cache.bg_px)
                bg_pixels = app.spectral_cache.bg_px;
            else
                uiconfirm(app.UIFigure,'Click on the pixel on this slice that best represents background.','Confirmation','Options',{'OK'},'DefaultOption','OK');
                color_roi = drawpoint(app.proc_xyAxes);
                pos = round(color_roi.Position);
                delete(color_roi);

                bg_pixels = [pos(1), pos(2), round(app.proc_zSlider.Value)];
                app.spectral_cache.bg_px = bg_pixels;
            end

            loc_pixel = [pixels; bg_pixels];

            if ~isempty(app.spectral_cache.blurred_img)
                sigma_gauss = 0.0001;
            else
                app.spectral_cache.blurred_img = 1;
            end

            if app.ProcColormapButton.Value
                vol = app.proc_image.data(:);
            elseif app.ProcVideoButton.Value
                vol = app.retrieve_frame(app.proc_tSlider.Value);
            end

            rgb = ch_idx(1:3);
            vol = double(Methods.Preprocess.zscore_frame(vol));
            vol(vol<0) = 0;

            og_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            
            % Stack relevant channels and normalize.
            filtered_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            for i = 1:length(rgb)
                filtered_vol(i,:,:,:) = imgaussfilt3(vol(:,:,:,rgb(i))./max(vol(:,:,:,rgb(i)),[],'all').*65535, sigma_gauss);
                og_vol(i,:,:,:) = vol(:,:,:,rgb(i));
            end

            % Construct background array (based on last row of loc_pixels).
            app.spectral_cache.bg_val = double(mean(filtered_vol(:,loc_pixel(end,2)-size_selection:loc_pixel(end,2)+size_selection,loc_pixel(end,1)-size_selection:loc_pixel(end,1)+size_selection,loc_pixel(end,3)),[2,3]));
            for ii=1:size(app.spectral_cache.bg_val)
                filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - app.spectral_cache.bg_val(ii); 
            end
            
            % Compute linear scaling for spectral crosstalk.
            app.spectral_cache.ch_val = mean(filtered_vol(:,loc_pixel(1,2)-size_selection:loc_pixel(1,2)+size_selection,loc_pixel(1,1)-size_selection:loc_pixel(1,1)+size_selection,loc_pixel(1,3)),[2,3]);
            app.spectral_cache.ch_val(channels_to_debleed) = app.spectral_cache.ch_val(channels_to_debleed)/app.spectral_cache.ch_val(~channels_to_debleed);
            app.spectral_cache.ch_val(~channels_to_debleed) = app.spectral_cache.ch_val(~channels_to_debleed)/app.spectral_cache.ch_val(~channels_to_debleed);

            app.flags.debleed = 1;
            app.drawProcImage();
        end

        function output = debleed(app, vol, mode)
            % Check whether to use cache values or cache coords.
            if ~exist('mode', 'var')
                if ~isempty(app.spectral_cache.ch_val)
                    mode = 'val';
                else
                    mode = 'coord';
                end
            end

            % Back up full volume.
            output = vol;

            % Grab processing tab values.
            ch_idx = [app.RDropDown.Value, app.GDropDown.Value, app.BDropDown.Value, app.WDropDown.Value];
            rgb = ch_idx(1:3);

            % Normalize volume.
            vol = double(Methods.Preprocess.zscore_frame(vol));
            vol(vol<0) = 0;
            
            % Stack relevant channels and normalize.
            filtered_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            for i = 1:length(rgb)
                filtered_vol(i,:,:,:) = imgaussfilt3(vol(:,:,:,rgb(i))./max(vol(:,:,:,rgb(i)),[],'all').*65535, sigma_gauss);
            end

            switch mode
                case 'val'
                    % Remove background noise.
                    for ii=1:size(app.spectral_cache.bg_val)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - app.spectral_cache.bg_val(ii); 
                    end

                    % Debleed.
                    for ii = 1:length(app.spectral_cache.ch_db)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - app.spectral_cache.ch_db(ii)*app.spectral_cache.ch_val(ii)* filtered_vol(~app.spectral_cache.ch_db,:,:,:);
                    end
                case 'coord'

                    % Construct background array
                    bg = double(mean(filtered_vol(:,app.spectral_cache.bg_px(2)-size_selection:app.spectral_cache.bg_px(2)+size_selection,app.spectral_cache.bg_px(1)-size_selection:app.spectral_cache.bg_px(1)+size_selection,app.spectral_cache.bg_px(3)),[2,3]));
                    for ii=1:size(bg)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - bg(ii); 
                    end

                    loc_pixel = [app.spectral_cache.ch_px{1};app.spectral_cache.ch_px{2};app.spectral_cache.ch_px{3}];

                    % Compute linear scaling for spectral crosstalk.
                    scale_crosstalk = mean(filtered_vol(:,loc_pixel(1,2)-size_selection:loc_pixel(1,2)+size_selection,loc_pixel(1,1)-size_selection:loc_pixel(1,1)+size_selection,loc_pixel(1,3)),[2,3]);
                    scale_crosstalk(app.spectral_cache.ch_db) = scale_crosstalk(app.spectral_cache.ch_db)/scale_crosstalk(~app.spectral_cache.ch_db);
                    scale_crosstalk(~app.spectral_cache.ch_db) = scale_crosstalk(~app.spectral_cache.ch_db)/scale_crosstalk(~app.spectral_cache.ch_db);
                    
                    % Debleed.
                    for ii = 1:length(app.spectral_cache.ch_db)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - app.spectral_cache.ch_db(ii)*scale_crosstalk(ii)* filtered_vol(~app.spectral_cache.ch_db,:,:,:);
                    end
            end

            % Normalize corrected image again.
            for i = 1:length(ch_idx)
                filtered_vol(i,:,:,:) = uint16(filtered_vol(i,:,:,:)./max(filtered_vol(i,:,:,:),[],'all').*65535);
            end

            % Permute image to get same format as input.
            filtered_vol = permute(filtered_vol, [4,2,3,1]);
            filtered_vol = permute(filtered_vol,[2,3,1,4]);
            filtered_vol = Methods.Preprocess.zscore_frame(filtered_vol);

            % Replace OG RGB channels and return resulting array.
            output(:,:,:,rgb(1)) = filtered_vol(:,:,:,1);
            output(:,:,:,rgb(2)) = filtered_vol(:,:,:,2);
            output(:,:,:,rgb(3)) = filtered_vol(:,:,:,3);
        end

        function sliceIndices = proc_target_slices(nz, nnz)
            % Calculate the indices of slices to retain for a new volume with nnz slices while preserving isotropy.
        
            % Validate inputs
            if nnz >= nz
                error('nnz must be less than nz');
            end
        
            % Calculate the indices to retain
            mid = ceil(nz / 2); % Middle slice index of the original volume
            half_nnz = floor(nnz / 2); % Half the number of slices to retain
        
            if mod(nnz, 2) == 0
                % If nnz is even, we take slices symmetrically around the middle slice
                startIndex = mid - half_nnz;
                endIndex = mid + half_nnz - 1;
                
                % If nz is odd, exclude the middle slice
                if mod(nz, 2) ~= 0
                    sliceIndices = [startIndex:mid-1, mid+1:endIndex];
                else
                    sliceIndices = startIndex:endIndex;
                end
            else
                % If nnz is odd, we take an odd number of slices symmetrically
                startIndex = mid - half_nnz;
                endIndex = mid + half_nnz;
                sliceIndices = startIndex:endIndex;
            end
        end

        function neurons = stream_neurons(mode)
            video_info = Program.GUIHandling.global_grab('NeuroPAL ID', 'video_info');
            video_neurons = Program.GUIHandling.global_grab('NeuroPAL ID', 'video_neurons');

            if ~exist('mode', 'var')
                if isfield(video_info.annotations)
                    mode = 'annotations';
                elseif length(video_neurons) > 1
                    mode = 'tree';
                end
            end

            switch mode
                case 'annotations'
                    [~, ~, fmt] = fileparts(video_info.annotations);
                    
                    switch fmt
                        case '.xml'
                            [positions, labels] = DataHandling.readTrackmate(video_info.annotations);
                        case '.h5'
                            [positions, labels] = DataHandling.readAnnoH5(video_info.annotations);                            
                    end

                case 'tree'
                    labels = {};
                    positions = [];
                    for i=1:length(video_neurons)
                        neuron = video_neurons(i);

                        for j=1:length(neuron.rois)
                            x = neuron.rois.x_slice;
                            y = neuron.rois.y_slice;
                            z = neuron.rois.z_slice;
                            t = j;

                            positions = [positions; [x y z t]];
                            labels{end+1} = neuron.worldline.name;
                        end
                    end
                    
            end

            neurons = struct('positions', positions, 'labels', labels);
        end
    end
end