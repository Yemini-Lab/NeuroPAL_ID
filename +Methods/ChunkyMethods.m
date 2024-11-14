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
                    rotated_mask = imrotate(app.rotation_stack.cache.(app.VolumeDropDown.Value).mask, app.rotation_stack.cache.(app.VolumeDropDown.Value).angle);
                    nonzero_rows = squeeze(any(any(rotated_mask, 2), 3));
                    nonzero_columns = squeeze(any(any(rotated_mask, 1), 3));
                    
                    top_edge = find(nonzero_rows, 1, 'first');
                    bottom_edge = find(nonzero_rows, 1, 'last');
                    left_edge = find(nonzero_columns, 1, 'first');
                    right_edge = find(nonzero_columns, 1, 'last');

                    new_dims = og_dims;
                    new_dims(1:2) = [bottom_edge-top_edge+1, right_edge-left_edge+1];

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
                    output_slice = Program.rotation_gui.apply_mask(app, slice);

                case 'hori'
                    output_slice = slice(:,end:-1:1,end:-1:1,:,:);

                case 'vert'
                    output_slice = slice(end:-1:1,:,end:-1:1,:,:);

                case 'rotate'
                    output_slice = rotate(slice, app.RotateSlider.Value);

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

            if exist('progress', 'var')
                dialog_message = progress.Message;
                dialog_progress = progress.Value;
            end

            switch action
                case 'debleed'
                    processed_vol = Methods.ChunkyMethods.debleed(app, vol);

                otherwise
                    [new_dims, old_dims] = Methods.ChunkyMethods.calc_pp_size(app, action, vol);
                    nz = old_dims(3);

                    % Initialize cache array.
                    processed_vol = zeros(new_dims, class(vol));
    
                    % Iterate over slices.
                    for z=1:nz
                        if exist('progress', 'var')
                            progress.Message = sprintf("%s, slice %.f/%.f)", dialog_message, z, nz);
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

            if exist('progress', 'var')
                dialog_message = progress.Message;
            end

            % Calculate new colormap dimensions
            new_dims = size(app.proc_image, 'data');
            for a=1:length(actions)
                new_dims = Methods.ChunkyMethods.calc_pp_size(app, actions{a}, zeros(new_dims));
            end

            if length(actions) < 1
                return
            end

            for a=1:length(actions)
                if exist('progress', 'var')
                    progress.Message = sprintf("%s \n-> (%s", dialog_message, actions{a});
                    progress.Value = a/length(actions);
                    processed_vol = Methods.ChunkyMethods.apply_vol(app, actions{a}, app.proc_image.data, progress);
                else
                    processed_vol = Methods.ChunkyMethods.apply_vol(app, actions{a}, app.proc_image.data);
                end
            end
    
            % Save to file.
            app.proc_image.Properties.Writable = true;
            app.proc_image.data = processed_vol;
            app.proc_image.Properties.Writable = false;
        end

        function apply_video(app, actions, progress)
            % Apply set of operations to a video.

            if exist('progress', 'var')
                dialog_message = progress.Message;
                start_time = datetime("now");
            end

            % ...Set up necessary paths.
            ppath = fileparts(app.video_path); % Get current file's parent path.
            temp_path = sprintf('%s/cache_video.h5', ppath); % Create cache file to which we'll be writing.
            processed_path = sprintf('%s/processed_video.h5', ppath); % Create new video file to avoid overwriting original.

            % If a cache file already exists, delete it.
            if exist(temp_path, 'file')==2
                delete(temp_path);
            end

            % Calculate new video dimensions
            nt = app.video_info.nt;
            new_dims = size(app.retrieve_frame(1));
            for a=1:length(actions)
                action = actions{a};
                new_dims = Methods.ChunkyMethods.calc_pp_size(app, action, zeros(new_dims));
            end

            % Create the cache file we'll be writing to chunk-by-chunk.
            h5create(temp_path, '/data', [new_dims(1:end) nt], "Chunksize", [new_dims(1:end) 1]);

            for t=1:nt
                if exist('progress', 'var')
                    progress.Value = t/nt;
                    dialog_progress = progress.Value;
                    time_string = Program.GUIHandling.get_time_string(start_time, t, nt);
                end

                processed_frame = app.retrieve_frame(app.proc_tSlider.Value);

                for a=1:length(actions)
                    if exist('progress', 'var')
                        progress.Message = sprintf("%s \n-> frame %.f/%.f %s \n-> (%s", dialog_message, t, nt, time_string, actions{a});
                        progress.Value = dialog_progress + (dialog_progress/t)*(a/length(actions));
                        processed_frame = Methods.ChunkyMethods.apply_vol(app, actions{a}, processed_frame, progress);
                    else
                        processed_frame = Methods.ChunkyMethods.apply_vol(app, actions{a}, processed_frame);
                    end
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

        function spectral_unmix(app, channel)
            % Remove spectral crosstalk of images based on a linear spectral crosstalk remover.
            Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab');

            if isa(channel, 'matlab.ui.eventdata.ButtonPushedData')
                channel = channel.Source.Tag;
            end

            ch_idx = [str2num(app.ProcRDropDown.Value), str2num(app.ProcGDropDown.Value), str2num(app.ProcBDropDown.Value)];
            size_selection = app.DropperradiusSpinner.Value;
            sigma_gauss = app.SigmagaussEditField.Value;
            rgb = ch_idx(1:3);
            t_idx = [];

            vol = app.proc_image.data;

            % Pick & update ideal channel representations.
            target = Program.GUIHandling.dropper( ...
                sprintf('Click on the pixel on this slice that best represents %s.', channel), ...
                app.proc_xyAxes, vol, app.proc_zSlider.Value);

            if isempty(target.values)
                Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
                return
            else
                app.(sprintf("%s_r", channel)).Value = mean(target.values(ch_idx(1)), 'all');
                app.(sprintf("%s_g", channel)).Value = mean(target.values(ch_idx(2)), 'all');
                app.(sprintf("%s_b", channel)).Value = mean(target.values(ch_idx(3)), 'all');
            end

            % Construct filtered volume: stack channels & normalize.
            vol = double(Methods.Preprocess.zscore_frame(vol));
            vol(vol < 0) = 0;

            filtered_vol = zeros(length(rgb), size(vol,1), size(vol,2), size(vol,3));
            for i = 1:length(rgb)
                filtered_vol(i,:,:,:) = imgaussfilt3(vol(:,:,:,rgb(i))./max(vol(:,:,:,rgb(i)),[],'all').*65535, sigma_gauss);
            end

            switch channel
                case {'bg', 'background'}
                    app.spectral_cache.bg_px = target.pixels;
                    app.spectral_cache.bg_val = double(mean(filtered_vol(:,target.pixels(2)-size_selection:target.pixels(2)+size_selection,target.pixels(1)-size_selection:target.pixels(1)+size_selection,target.pixels(3)),[2,3]));
                case {'w', 'gfp', 'dic', 'gut', 'white'}
                    % TBD
                otherwise
                    t_idx = ch_idx(Program.GUIHandling.channel_map(channel));
            end

            if ~isempty(t_idx)
                if ~ismember(t_idx, app.spectral_cache.ch_db)
                    app.spectral_cache.ch_db = [app.spectral_cache.ch_db; t_idx];
                end

                % If necessary, grab background.
                if isempty(app.spectral_cache.bg_px) || isempty(app.spectral_cache.bg_val)
                    Methods.ChunkyMethods.spectral_unmix(app, 'background')
                end
    
                % Subtract background.
                for ii=1:length(app.spectral_cache.bg_val)
                    filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - app.spectral_cache.bg_val(ii); 
                end
                
                % Compute linear scaling for spectral crosstalk.
                channels_to_debleed = rgb~=app.spectral_cache.ch_db(t_idx, :);
                app.spectral_cache.ch_val(t_idx, :) = mean(filtered_vol(:,target.pixels(2)-size_selection:target.pixels(2)+size_selection,target.pixels(1)-size_selection:target.pixels(1)+size_selection,target.pixels(3)),[2,3]);
                app.spectral_cache.ch_val(t_idx, channels_to_debleed) = app.spectral_cache.ch_val(channels_to_debleed)/app.spectral_cache.ch_val(~channels_to_debleed);
                app.spectral_cache.ch_val(t_idx, ~channels_to_debleed) = app.spectral_cache.ch_val(~channels_to_debleed)/app.spectral_cache.ch_val(~channels_to_debleed);
    
                app.flags.debleed = 1;
            end
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
            ch_idx = [str2num(app.ProcRDropDown.Value), str2num(app.ProcGDropDown.Value), str2num(app.ProcBDropDown.Value)];
            size_selection = app.DropperradiusSpinner.Value;
            sigma_gauss = app.SigmagaussEditField.Value;
            rgb = ch_idx(1:3);
            channels_to_debleed = rgb~=app.spectral_cache.ch_db;

            % Normalize volume.
            switch class(vol)
                case {'single', 'double'}
                    % TBD
                case {'matlab.io.MatFile'}
                    vol = vol.data;
                    vol = double(vol)/double(intmax(class(vol)));
                otherwise
                    vol = double(vol)/double(intmax(class(vol)));
            end

            vol(vol<0) = 0;
            
            % Stack relevant channels and normalize.
            filtered_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            for i = 1:length(rgb)
                filtered_vol(i,:,:,:) = imgaussfilt3(vol(:,:,:,rgb(i))./max(vol(:,:,:,rgb(i)),[],'all').*65535, sigma_gauss);
            end

            switch mode
                case 'val'
                    % Remove background noise.
                    for ii=1:length(app.spectral_cache.bg_val)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - app.spectral_cache.bg_val(ii); 
                    end

                    % Debleed.
                    for t_idx = 1:length(app.spectral_cache.ch_db)
                        c = app.spectral_cache.ch_db(t_idx, :);
                        t_ch = channels_to_debleed(c, :);
                        
                        for db = 1:length(t_ch)
                            filtered_vol(db,:,:,:) = filtered_vol(db,:,:,:) - t_ch(db).*app.spectral_cache.ch_val(c, db)* filtered_vol(~t_ch,:,:,:);
                        end
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
                    for t_idx = 1:length(app.spectral_cache.ch_db)
                        c = app.spectral_cache.ch_db(t_idx, :);
                        filtered_vol(c,:,:,:) = filtered_vol(c,:,:,:) - app.spectral_cache.ch_db(c)*scale_crosstalk(c)* filtered_vol(~app.spectral_cache.ch_db,:,:,:);
                    end
            end

            % Normalize corrected image again.
            for i = 1:length(ch_idx)
                filtered_vol(i,:,:,:) = cast((filtered_vol(i,:,:,:)./max(filtered_vol(i,:,:,:),[],'all').*65535), 'uint64');
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

            neurons = struct('positions', {positions}, 'labels', {labels});
        end

        function frame = load_proc_image(app)
            frame = struct('xy', {[]}, 'yz', {[]}, 'xz', {[]});
            rgb = [str2num(app.ProcRDropDown.Value), str2num(app.ProcGDropDown.Value), str2num(app.ProcBDropDown.Value)];

            % Grab current volume.
            raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
            [raw.array, raw.dims] = Program.Validation.pad_rgb(raw.array);
            
            if strcmp(raw.state, 'colormap')
                t_array = raw.array;
                raw.array = uint16(double(intmax('uint16')) * double(raw.array)/double(max(raw.array(:))));
                raw.array = double(raw.array)/double(max(raw.array(:)));
                threshold_value = (app.ProcNoiseThresholdKnob.Value/double(max(t_array, [], 'all')))*double(max(raw.array, [], 'all'));
            else
                threshold_value = app.ProcNoiseThresholdKnob.Value;
            end

            % Threshold.
            raw.array(raw.array < threshold_value) = 0;
            
            % For each channel...
            for c=1:raw.dims(4)
                % ...Adjust the gamma & histogram.
                c_gamma = sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c});
                c_hist = sprintf("%s_hist_slider", Program.GUIHandling.pos_prefixes{c});
                slider_vals = app.(c_hist).Value; hist_limit = app.(c_hist).Limits(2);
                
                raw.array(:, :, :, c, :) = imadjustn(raw.array(:, :, :, c, :), [slider_vals(1)/hist_limit slider_vals(2)/hist_limit], [], app.(c_gamma).Value);
                
                if ~ismember(c, rgb)
                    raw.array(:, :, :, rgb) = raw.array(:, :, :, rgb) + repmat(raw.array(:, :, :, c, :), [1, 1, 1, 3]);
                    raw.array(:, :, :, c, :) = [];
                end
            end

            % Apply processing operations.
            actions = fieldnames(app.flags);
            for a=1:length(actions)
                action = actions{a};
                if app.flags.(action) == 1
                    raw.array = Methods.ChunkyMethods.apply_vol(app, action, raw.array);
                end
            end

            Program.GUIHandling.set_gui_limits(app, dims=raw.dims);
            Program.GUIHandling.histogram_handler(app, 'draw', raw.array);
            Program.GUIHandling.shorten_knob_labels(app);

            if app.ProcShowMIPCheckBox.Value
                frame.xy = squeeze(max(raw.array,[],3));
            else
                frame.xy = squeeze(raw.array);
            end

            if app.ProcPreviewZslowCheckBox.Value
                frame.xz = squeeze(raw.array(:,y,:,:,:));
                frame.yz = squeeze(raw.array(x,:,:,:,:));
            end
        end
    end
end