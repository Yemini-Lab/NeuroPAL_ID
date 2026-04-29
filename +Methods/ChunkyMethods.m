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
                    rotated_mask = imrotate( ...
                        app.rotation_stack.cache.(app.VolumeDropDown.Value).mask, ...
                        -app.rotation_stack.cache.(app.VolumeDropDown.Value).angle);
                    nonzero_rows = squeeze(any(any(rotated_mask, 2), 3));
                    nonzero_columns = squeeze(any(any(rotated_mask, 1), 3));
                    
                    top_edge = find(nonzero_rows, 1, 'first');
                    bottom_edge = find(nonzero_rows, 1, 'last');
                    left_edge = find(nonzero_columns, 1, 'first');
                    right_edge = find(nonzero_columns, 1, 'last');

                    new_dims = og_dims;
                    new_dims(1:2) = [bottom_edge-top_edge+1, right_edge-left_edge+1];

                case 'ds'
                    [target_xy, target_slices] = Methods.ChunkyMethods.proc_downsample_targets(app, og_dims(1:3));
                    new_dims = og_dims;
                    new_dims(1:2) = target_xy;
                    new_dims(3) = numel(target_slices);

                case {'hori', 'vert', 'cc', 'acc', 'rotate'}
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

                        case 'rotate'
                            temp_arr = imrotate(temp_arr, app.proc_rot_spinner.Value);
                            
                    end

                    new_dims = og_dims;
                    new_dims(1:2) = [size(temp_arr, 1) size(temp_arr, 2)];

                otherwise
                    new_dims = og_dims;
            end
        end

        function output_slice = apply_slice(app, action, slice)
            % Apply operation to a slice.
            state = Program.Handlers.channels.processing_state(app);
            RGBW = [state.r.source_idx, state.g.source_idx, state.b.source_idx, state.white.source_idx];

            if size(slice, 4) < max(RGBW)
                RGBW = 1:size(slice, 4);
            end
            
            switch action
                case 'zscore'
                    output_slice = Methods.Preprocess.normalize_frame(slice); 

                case 'histmatch'
                    slice(:, :, :, RGBW(1:3)) = Methods.run_histmatch(slice, RGBW);
                    output_slice = slice;

                case 'crop'
                    output_slice = Program.crop_rotate_gui.apply_mask(app, slice);

                case 'hori'
                    output_slice = slice(:,end:-1:1,end:-1:1,:,:);

                case 'vert'
                    output_slice = slice(end:-1:1,:,end:-1:1,:,:);

                case 'rotate'
                    output_slice = imrotate(slice, app.proc_rot_spinner.Value);

                case 'cc'
                    temp_slice = permute(slice, [2,1,3,4]);
                    output_slice = temp_slice(:,end:-1:1,:,:,:);

                case 'acc'
                    temp_slice = permute(slice, [2,1,3,4]);
                    output_slice = temp_slice(end:-1:1,:,:,:,:);

                case 'ds'
                    [target_xy, target_slices] = Methods.ChunkyMethods.proc_downsample_targets(app, ...
                        [size(slice, 1), size(slice, 2), size(slice, 3)]);
                    temp_slice = imresize(slice, target_xy);
                    output_slice = temp_slice(:, :, target_slices, :);

                case 'window'
                    output_slice = Methods.ChunkyMethods.apply_channel_windows(app, slice);

                case 'debleed'
                    % TBD
            end            
        end

        function processed_vol = apply_vol(app, action, vol)
            % Apply operation to a volume.

            switch action
                case 'debleed'
                    processed_vol = Methods.ChunkyMethods.debleed(app, vol);

                otherwise
                    [new_dims, old_dims] = Methods.ChunkyMethods.calc_pp_size(app, action, vol);
                    nz = old_dims(3);

                    if strcmp(action, 'ds')
                        processed_vol = Methods.ChunkyMethods.apply_slice(app, action, vol);
                        return
                    end

                    if isa(vol, 'matlab.io.MatFile')
                        sample = vol.data(1, 1, 1, 1);
                        output_class = class(sample);
                    else
                        output_class = class(vol);
                    end

                    % Initialize cache array.
                    processed_vol = zeros(new_dims, output_class);
    
                    % Iterate over slices.
                    for z=1:nz
                        Program.Handlers.dialogue.step(sprintf("Slice %.f/%.f", z, nz));
    
                        % Grab slice.
                        if isa(vol, 'matlab.io.MatFile')
                            slice = vol.data(:, :, z, :);
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

        function apply_colormap(app, actions)
            % Apply set of operations to a colormap.

            if nargin < 2 || isempty(actions)
                return
            end

            actions = cellstr(lower(string(actions)));
            actions = actions(~cellfun('isempty', actions));
            if isempty(actions)
                return
            end

            % Calculate new colormap dimensions
            Program.Handlers.dialogue.step('Calculating new dimensions...');
            context = Program.Helpers.processing_colormap_context(app);
            if isempty(context.volume)
                return
            end

            new_dims = size(context.volume);
            for a=1:length(actions)
                new_dims = Methods.ChunkyMethods.calc_pp_size(app, actions{a}, zeros(new_dims));
            end

            current_vol = context.volume;
            for a=1:length(actions)
                Program.Handlers.dialogue.add_task(sprintf("Applying %s", actions{a}));
                Program.Handlers.dialogue.set_value(a/length(actions));
                processed_vol = Methods.ChunkyMethods.apply_vol(app, actions{a}, current_vol);
                current_vol = processed_vol;
            end

            app.image_data = current_vol;
            app.image_data_zscored = Methods.Preprocess.zscore_frame(app.image_data);
            setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
            Program.Helpers.write_processing_colormap_to_file(app);
        end

        function apply_video(app, actions, progress)
            % Apply set of operations to a video.

            start_time = datetime("now");

            % ...Set up necessary paths.
            ppath = fileparts(app.video_path); % Get current file's parent path.
            temp_path = sprintf('%s/cache_video.h5', ppath); % Create cache file to which we'll be writing.
            processed_path = sprintf('%s/processed_video.h5', ppath); % Create new video file to avoid overwriting original.

            % If a cache file already exists, delete it.
            if exist(temp_path, 'file')==2
                delete(temp_path);
            end

            % Calculate new video dimensions
            Program.Handlers.dialogue.step('Calculating new dimensions...');
            nt = app.video_info.nt;
            p_frame = app.retrieve_frame(1);
            new_dims = size(p_frame);
            for a=1:length(actions)
                action = actions{a};
                new_dims = Methods.ChunkyMethods.calc_pp_size(app, action, zeros(new_dims));
            end

            % Create the cache file we'll be writing to chunk-by-chunk.
            Program.Handlers.dialogue.step('Creating cache file...');
            h5create(temp_path, '/data', [new_dims(1:end) nt], "Chunksize", [new_dims(1:end) 1], "Datatype", class(p_frame));

            for t=1:nt
                frame_progress = t/nt;
                Program.Handlers.dialogue.set_value(frame_progress);
                time_string = Program.GUIHandling.get_time_string(start_time, t, nt);
                Program.Handlers.dialogue.add_task(sprintf("Frame %.f/%.f %s", t, nt, time_string));

                processed_frame = app.retrieve_frame(t);

                for a=1:length(actions)
                    Program.Handlers.dialogue.set_value(min(frame_progress + (frame_progress/t)*(a/length(actions)), 1));
                    processed_frame = Methods.ChunkyMethods.apply_vol(app, actions{a}, processed_frame);
                end

                % Ensure cache frame retains time dimension.
                write_size = [size(processed_frame) 1];
                processed_frame = reshape(processed_frame, write_size);
                
                % Write cache frame to cache file.
                h5write(temp_path, '/data', processed_frame, [1 1 1 1 t], write_size);

                Program.Handlers.dialogue.resolve();
            end

            if exist(processed_path, 'file')==2
                delete(processed_path);
            end

            movefile(temp_path, processed_path);
            app.video_info.nt = nt;
            Program.Routines.Videos.reload(processed_path);
        end

        function spectral_unmix(app, channel)
            % Remove spectral crosstalk of images based on a linear spectral crosstalk remover.
            Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab');
            cleanup = onCleanup(@() Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab')); %#ok<NASGU>

            if isa(channel, 'matlab.ui.eventdata.ButtonPushedData')
                channel = channel.Source.Tag;
            end
            channel = lower(string(channel));

            [rgb_source_idx, role_names] = Methods.ChunkyMethods.spectral_rgb_source_indices(app);
            if isempty(rgb_source_idx)
                return
            end

            if logical(app.ProcShowMIPCheckBox.Value)
                Program.Handlers.dialogue.step('Spectral calibration requires a single slice. Disabling MIP preview...');
                app.ProcShowMIPCheckBox.Value = false;
                Program.GUIHandling.update_processing_zslider_visibility(app);
                Program.Routines.Processing.render();
                drawnow limitrate nocallbacks;
            end

            radius = max(1, round(double(app.DropperradiusSpinner.Value)));
            sigma_gauss = max(0, double(app.SigmagaussEditField.Value));
            cache = Methods.ChunkyMethods.ensure_spectral_cache(app);
            cache.rgb_source_idx = rgb_source_idx;
            cache.sigma_gauss = sigma_gauss;
            cache.dropper_radius = radius;

            vol = Methods.ChunkyMethods.spectral_source_volume(app);
            vol = Methods.ChunkyMethods.apply_preview_actions(app, vol, {'debleed'});

            prompt = sprintf( ...
                'Click on the center of the %d-pixel radius ROI on this slice that best represents %s.', ...
                radius, channel);

            % Pick & update ideal channel representations.
            target = Program.GUIHandling.dropper( ...
                prompt, ...
                app.proc_xyAxes, vol, app.proc_zSlider.Value, radius);

            if isempty(target.values)
                return
            end

            filtered_vol = Methods.ChunkyMethods.spectral_cached_filtered_rgb_volume( ...
                app, vol, rgb_source_idx, sigma_gauss);
            measured_vector = Methods.ChunkyMethods.spectral_roi_vector( ...
                filtered_vol, target.roi_pixels);

            switch channel
                case {'bg', 'background'}
                    cache.background_pixel = target.pixels;
                    cache.background_vector = measured_vector;
                    cache.bg_px = target.pixels;
                    cache.bg_val = measured_vector;
                    Methods.ChunkyMethods.update_spectral_fields(app, 'background', measured_vector);
                otherwise
                    role_idx = Methods.ChunkyMethods.spectral_role_index(channel, role_names);
                    if isempty(role_idx)
                        return
                    end

                    background_vector = cache.background_vector;
                    if isempty(background_vector) || ~all(isfinite(background_vector))
                        background_vector = zeros(1, 3);
                    end

                    signal_vector = max(measured_vector - background_vector, 0);
                    target_strength = signal_vector(role_idx);
                    if ~isfinite(target_strength) || target_strength <= eps
                        return
                    end

                    coefficients = signal_vector / target_strength;
                    coefficients(role_idx) = 1;

                    cache.coefficients(role_idx, :) = coefficients;
                    cache.measured_pixels(role_idx, :) = target.pixels;
                    cache.measured_vectors(role_idx, :) = signal_vector;

                    % Keep legacy fields populated until the UI/property model is fully cleaned up.
                    cache.ch_db = find(any(isfinite(cache.coefficients), 2))';
                    cache.ch_px{role_idx} = target.pixels;
                    cache.ch_val = cache.coefficients;

                    Methods.ChunkyMethods.update_spectral_fields(app, role_names{role_idx}, coefficients);
                    app.flags.debleed = 1;
            end

            app.spectral_cache = cache;
            if isfield(app.flags, 'debleed')
                Program.Routines.Processing.render();
            end
        end

        function output = debleed(app, vol, mode)
            %#ok<INUSD>
            cache = Methods.ChunkyMethods.ensure_spectral_cache(app);
            coefficients = cache.coefficients;
            if isempty(coefficients) || ~any(isfinite(coefficients), 'all')
                output = vol;
                return
            end

            output = vol;

            [rgb_source_idx, ~] = Methods.ChunkyMethods.spectral_rgb_source_indices(app);
            rgb_apply_idx = Methods.ChunkyMethods.spectral_apply_indices(vol, rgb_source_idx);
            if isempty(rgb_apply_idx)
                return
            end

            [normalized_vol, channel_maxima] = Methods.ChunkyMethods.spectral_normalized_rgb_volume( ...
                vol, rgb_apply_idx);
            background_vector = cache.background_vector;
            if isempty(background_vector) || ~all(isfinite(background_vector))
                background_vector = zeros(1, 3);
            end
            base_volume = max(normalized_vol - reshape(background_vector, 1, 1, 1, []), 0);
            corrected_volume = base_volume;

            for target_idx = 1:3
                target_coefficients = coefficients(target_idx, :);
                if ~all(isfinite(target_coefficients))
                    continue
                end

                target_channel = base_volume(:, :, :, target_idx);
                for observed_idx = 1:3
                    if observed_idx == target_idx
                        continue
                    end

                    bleed_scale = target_coefficients(observed_idx);
                    if ~isfinite(bleed_scale) || bleed_scale <= 0
                        continue
                    end

                    corrected_volume(:, :, :, observed_idx) = ...
                        corrected_volume(:, :, :, observed_idx) - bleed_scale * target_channel;
                end
            end

            corrected_volume = max(corrected_volume, 0);

            for role_idx = 1:3
                corrected_channel = corrected_volume(:, :, :, role_idx) * channel_maxima(role_idx);
                output(:, :, :, rgb_apply_idx(role_idx)) = ...
                    Methods.ChunkyMethods.cast_like_channel(corrected_channel, ...
                    output(:, :, :, rgb_apply_idx(role_idx)));
            end
        end

        function output = apply_preview_actions(app, vol, exclude_actions)
            if nargin < 3 || isempty(exclude_actions)
                exclude_actions = {};
            end

            exclude_actions = cellstr(lower(string(exclude_actions)));

            output = vol;
            actions = fieldnames(app.flags);
            for a = 1:length(actions)
                action = actions{a};
                if ~app.flags.(action) || any(strcmpi(action, exclude_actions))
                    continue
                end

                msg = sprintf('Applying %s...', action);
                Program.Handlers.dialogue.step(msg);
                output = Methods.ChunkyMethods.apply_vol(app, action, output);
            end
        end

        function cache = spectral_cache_template()
            cache = struct( ...
                'coefficients', nan(3, 3), ...
                'measured_pixels', nan(3, 3), ...
                'measured_vectors', nan(3, 3), ...
                'background_pixel', nan(1, 3), ...
                'background_vector', nan(1, 3), ...
                'rgb_source_idx', nan(1, 3), ...
                'sigma_gauss', nan, ...
                'dropper_radius', nan, ...
                'ch_db', {[]}, ...
                'ch_px', {cell(1, 3)}, ...
                'ch_val', nan(3, 3), ...
                'bg_px', {[]}, ...
                'bg_val', nan(1, 3), ...
                'blurred_signature', "", ...
                'blurred_img', {[]});
        end

        function cache = ensure_spectral_cache(app)
            template = Methods.ChunkyMethods.spectral_cache_template();
            cache = template;

            if isprop(app, 'spectral_cache') && isstruct(app.spectral_cache)
                existing = app.spectral_cache;
                fields = fieldnames(template);
                for f = 1:numel(fields)
                    name = fields{f};
                    if isfield(existing, name)
                        cache.(name) = existing.(name);
                    end
                end
            end

            app.spectral_cache = cache;
        end

        function [rgb_source_idx, role_names] = spectral_rgb_source_indices(app)
            state = Program.Handlers.channels.processing_state(app);
            rgb_source_idx = double([state.r.source_idx, state.g.source_idx, state.b.source_idx]);
            role_names = {'red', 'green', 'blue'};

            if numel(rgb_source_idx) ~= 3 || any(~isfinite(rgb_source_idx)) || ...
                    any(rgb_source_idx < 1) || numel(unique(rgb_source_idx)) < 3
                rgb_source_idx = [];
                role_names = {};
            end
        end

        function rgb_apply_idx = spectral_apply_indices(vol, rgb_source_idx)
            n_channels = size(vol, 4);
            if n_channels == 3
                rgb_apply_idx = 1:3;
            elseif numel(rgb_source_idx) == 3 && all(rgb_source_idx >= 1) && all(rgb_source_idx <= n_channels)
                rgb_apply_idx = rgb_source_idx;
            else
                rgb_apply_idx = [];
            end
        end

        function role_idx = spectral_role_index(channel, role_names)
            role_idx = find(strcmpi(channel, role_names), 1);
        end

        function update_spectral_fields(app, prefix, values)
            channel_labels = {'r', 'g', 'b'};
            values = reshape(double(values), 1, []);
            if numel(values) < 3
                values(3) = 0;
            end

            for i = 1:3
                field_name = sprintf('%s_%s', prefix, channel_labels{i});
                if isprop(app, field_name) && isvalid(app.(field_name))
                    app.(field_name).Value = values(i);
                end
            end
        end

        function filtered_vol = spectral_filtered_rgb_volume(vol, rgb_source_idx, sigma_gauss)
            [filtered_vol, ~] = Methods.ChunkyMethods.spectral_normalized_rgb_volume(vol, rgb_source_idx);

            if sigma_gauss <= 0
                return
            end

            for i = 1:3
                filtered_vol(:, :, :, i) = imgaussfilt3(filtered_vol(:, :, :, i), sigma_gauss);
            end
        end

        function filtered_vol = spectral_cached_filtered_rgb_volume(app, vol, rgb_source_idx, sigma_gauss)
            cache = Methods.ChunkyMethods.ensure_spectral_cache(app);
            signature = Methods.ChunkyMethods.spectral_filtered_signature(app, vol, rgb_source_idx, sigma_gauss);

            if isfield(cache, 'blurred_signature') && strcmp(string(cache.blurred_signature), signature) && ...
                    ~isempty(cache.blurred_img) && isequal(size(cache.blurred_img), [size(vol, 1), size(vol, 2), size(vol, 3), 3])
                filtered_vol = cache.blurred_img;
                return
            end

            filtered_vol = Methods.ChunkyMethods.spectral_filtered_rgb_volume(vol, rgb_source_idx, sigma_gauss);
            cache.blurred_signature = signature;
            cache.blurred_img = filtered_vol;
            app.spectral_cache = cache;
        end

        function [normalized_vol, channel_maxima] = spectral_normalized_rgb_volume(vol, rgb_source_idx)
            normalized_vol = zeros([size(vol, 1), size(vol, 2), size(vol, 3), 3], 'double');
            channel_maxima = ones(1, 3);

            for i = 1:3
                channel = double(vol(:, :, :, rgb_source_idx(i)));
                finite_mask = isfinite(channel);
                if ~any(finite_mask, 'all')
                    continue
                end

                channel(~finite_mask) = 0;
                min_val = min(channel(finite_mask), [], 'all');
                if min_val < 0
                    channel = channel - min_val;
                end

                max_val = max(channel, [], 'all');
                channel_maxima(i) = max(max_val, 1);
                if max_val > 0
                    normalized_vol(:, :, :, i) = channel / max_val;
                end
            end
        end

        function vol = spectral_source_volume(app)
            state = Program.Handlers.channels.processing_state(app);
            max_idx = max(1, state.max_source_idx);

            switch char(string(app.VolumeDropDown.Value))
                case 'Colormap'
                    context = Program.Helpers.processing_colormap_context(app);
                    dims = context.dims;
                    if isempty(context.volume)
                        vol = zeros(dims(1), dims(2), dims(3), 1, 'uint8');
                        return
                    end
                    n_channels = dims(4);
                    max_idx = min(max_idx, n_channels);
                    vol = context.volume(:, :, :, 1:max_idx);

                case 'Video'
                    frame = app.retrieve_frame(app.proc_tSlider.Value);
                    if ndims(frame) == 3
                        frame = reshape(frame, size(frame, 1), size(frame, 2), size(frame, 3), 1);
                    end
                    max_idx = min(max_idx, size(frame, 4));
                    vol = frame(:, :, :, 1:max_idx);

                otherwise
                    vol = Program.GUIHandling.get_active_volume(app, 'request', 'array').array;
            end

            if ndims(vol) == 3
                vol = reshape(vol, size(vol, 1), size(vol, 2), size(vol, 3), 1);
            end
        end

        function signature = spectral_filtered_signature(app, vol, rgb_source_idx, sigma_gauss)
            flags = fieldnames(app.flags);
            active_actions = {};
            for i = 1:numel(flags)
                action = flags{i};
                if app.flags.(action) && ~strcmpi(action, 'debleed')
                    active_actions{end+1} = action; %#ok<AGROW>
                end
            end

            active_actions = sort(active_actions);
            payload = struct( ...
                'mode', char(string(app.VolumeDropDown.Value)), ...
                'time_index', double(app.proc_tSlider.Value), ...
                'volume_size', double(size(vol)), ...
                'volume_class', class(vol), ...
                'rgb_source_idx', double(rgb_source_idx), ...
                'sigma_gauss', double(sigma_gauss), ...
                'rotate_angle', double(app.proc_rot_spinner.Value), ...
                'actions', {active_actions});
            signature = string(jsonencode(payload));
        end

        function clear_spectral_filtered_cache(app)
            cache = Methods.ChunkyMethods.ensure_spectral_cache(app);
            cache.blurred_signature = "";
            cache.blurred_img = [];
            app.spectral_cache = cache;
        end

        function measured_vector = spectral_roi_vector(filtered_vol, pixels, radius)
            if nargin < 3
                radius = [];
            end

            if isempty(pixels)
                measured_vector = nan(1, size(filtered_vol, 4));
                return
            end

            if isvector(pixels)
                roi_pixels = Methods.ChunkyMethods.spectral_disk_pixels(filtered_vol, pixels, radius);
            else
                roi_pixels = round(double(pixels));
            end

            if isempty(roi_pixels)
                measured_vector = nan(1, size(filtered_vol, 4));
                return
            end

            linear_idx = sub2ind(size(filtered_vol, 1:3), ...
                roi_pixels(:, 2), roi_pixels(:, 1), roi_pixels(:, 3));
            measured_vector = nan(1, size(filtered_vol, 4));

            for c = 1:size(filtered_vol, 4)
                channel = filtered_vol(:, :, :, c);
                measured_vector(c) = mean(channel(linear_idx), 'omitnan');
            end
        end

        function roi_pixels = spectral_disk_pixels(filtered_vol, pixel, radius)
            if nargin < 3 || isempty(radius) || ~isfinite(radius)
                radius = 1;
            end

            radius = max(1, round(double(radius)));
            x = min(max(round(double(pixel(1))), 1), size(filtered_vol, 2));
            y = min(max(round(double(pixel(2))), 1), size(filtered_vol, 1));
            z = min(max(round(double(pixel(3))), 1), size(filtered_vol, 3));

            x_range = max(1, x - radius):min(size(filtered_vol, 2), x + radius);
            y_range = max(1, y - radius):min(size(filtered_vol, 1), y + radius);
            [xx, yy] = meshgrid(x_range, y_range);
            mask = (xx - x).^2 + (yy - y).^2 <= radius.^2;

            roi_pixels = [xx(mask), yy(mask), repmat(z, nnz(mask), 1)];
        end

        function cast_channel = cast_like_channel(channel, reference_channel)
            target_class = class(reference_channel);
            if isa(reference_channel, 'single') || isa(reference_channel, 'double')
                cast_channel = cast(channel, target_class);
                return
            end

            channel = round(channel);
            channel = min(max(channel, 0), double(intmax(target_class)));
            cast_channel = cast(channel, target_class);
        end

        function signature = spectral_cache_signature(app)
            cache = Methods.ChunkyMethods.ensure_spectral_cache(app);
            signature = struct( ...
                'coefficients', double(cache.coefficients), ...
                'measured_pixels', double(cache.measured_pixels), ...
                'background_pixel', double(cache.background_pixel), ...
                'background_vector', double(cache.background_vector), ...
                'rgb_source_idx', double(cache.rgb_source_idx), ...
                'sigma_gauss', double(cache.sigma_gauss), ...
                'dropper_radius', double(cache.dropper_radius));
        end

        function sliceIndices = proc_target_slices(nz, nnz)
            % Calculate the indices of slices to retain for a new volume with nnz slices while preserving isotropy.

            nz = max(1, round(double(nz)));
            nnz = min(max(round(double(nnz)), 1), nz);

            if nnz <= 1
                sliceIndices = ceil(nz / 2);
                return
            end

            if nnz >= nz
                sliceIndices = 1:nz;
                return
            end

            target_positions = linspace(1, nz, nnz);
            available = 1:nz;
            sliceIndices = zeros(1, nnz);
            used = false(1, nz);

            for k = 1:nnz
                [~, order] = sort(abs(available - target_positions(k)), 'ascend');
                for candidate_idx = order
                    candidate = available(candidate_idx);
                    if ~used(candidate)
                        sliceIndices(k) = candidate;
                        used(candidate) = true;
                        break
                    end
                end
            end

            sliceIndices = sort(sliceIndices);
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
            [package, package_info] = Program.Routines.Processing.get_cached_package(app);
            Program.Handlers.histograms.draw();
            Program.GUIHandling.shorten_knob_labels(app);
            frames = Program.Routines.Processing.get_view_frames(app, package, package_info.package_signature);
            frame.xy = frames.xy;
            frame.xz = frames.xz;
            frame.yz = frames.yz;
        end

        function output = apply_channel_windows(app, volume)
            output = volume;
            if ndims(output) < 4
                return
            end

            window_settings = Methods.ChunkyMethods.proc_window_settings(app, size(output, 4));
            if isempty(window_settings)
                return
            end

            for n = 1:numel(window_settings)
                source_idx = window_settings(n).source_idx;
                output(:, :, :, source_idx) = Methods.ChunkyMethods.apply_channel_window( ...
                    output(:, :, :, source_idx), ...
                    window_settings(n).low_high_in);
            end
        end

        function window_settings = proc_window_settings(app, n_channels)
            state = Program.Handlers.channels.processing_state(app);
            template = struct('source_idx', 0, 'low_high_in', [0 1]);
            assigned = false(1, n_channels);
            window_settings = repmat(template, 1, n_channels);

            for n = 1:numel(state.rows)
                row = state.rows(n);
                source_idx = row.source_idx;
                if source_idx < 1 || source_idx > n_channels || assigned(source_idx)
                    continue
                end

                low_high = double(row.settings.low_high_in);
                if isempty(low_high) || numel(low_high) ~= 2
                    continue
                end

                low_high = Methods.ChunkyMethods.normalize_window_range(low_high);
                if all(abs(low_high - [0 1]) <= (0.5 / 255))
                    continue
                end

                window_settings(source_idx).source_idx = source_idx;
                window_settings(source_idx).low_high_in = low_high;
                assigned(source_idx) = true;
            end

            window_settings = window_settings(assigned);
        end

        function output = apply_channel_window(channel, low_high_in)
            low_high_in = Methods.ChunkyMethods.normalize_window_range(low_high_in);
            if all(abs(low_high_in - [0 1]) <= (0.5 / 255))
                output = channel;
                return
            end

            if isfloat(channel)
                finite_mask = isfinite(channel);
                if ~any(finite_mask, 'all')
                    output = channel;
                    return
                end

                finite_vals = channel(finite_mask);
                min_val = min(finite_vals, [], 'all');
                max_val = max(finite_vals, [], 'all');
                if min_val >= 0 && max_val <= 1
                    min_val = 0;
                    max_val = 1;
                end
                if max_val <= min_val
                    output = zeros(size(channel), 'like', channel);
                    return
                end

                normalized = zeros(size(channel), 'double');
                normalized(finite_mask) = (double(channel(finite_mask)) - double(min_val)) ./ ...
                    (double(max_val) - double(min_val));
                normalized = min(max(normalized, 0), 1);
                adjusted = imadjustn(normalized, low_high_in, [0 1], 1);

                output = channel;
                adjusted = double(adjusted) .* (double(max_val) - double(min_val)) + double(min_val);
                output(finite_mask) = cast(adjusted(finite_mask), class(channel));
                return
            end

            output = imadjustn(channel, low_high_in, [0 1], 1);
        end

        function low_high = normalize_window_range(low_high)
            if isempty(low_high) || numel(low_high) < 2
                low_high = [0 1];
                return
            end

            low_high = double(low_high(:)');
            low_high = min(max(low_high(1:2), 0), 1);
            if low_high(1) > low_high(2)
                low_high = fliplr(low_high);
            end
        end

        function request = proc_downsample_request(app, dims3)
            ny = max(1, round(double(dims3(1))));
            nx = max(1, round(double(dims3(2))));
            nz = max(1, round(double(dims3(3))));

            min_xy_factor = 1 / max([ny, nx]);
            xy_factor = double(app.ProcXYFactorEditField.Value);
            if ~isfinite(xy_factor)
                xy_factor = 1;
            end
            xy_factor = min(max(xy_factor, min_xy_factor), 1);

            z_target = double(app.ProcZSlicesEditField.Value);
            if ~isfinite(z_target)
                z_target = nz;
            end
            z_target = min(max(round(z_target), 1), nz);

            target_xy = max(1, round([ny, nx] * xy_factor));
            target_xy = min(target_xy, [ny, nx]);
            target_slices = Methods.ChunkyMethods.proc_target_slices(nz, z_target);

            if isequal(target_xy, [ny, nx])
                xy_factor = 1;
            end
            if numel(target_slices) == nz
                z_target = nz;
            else
                z_target = numel(target_slices);
            end

            request = struct( ...
                'dims3', [ny, nx, nz], ...
                'min_xy_factor', min_xy_factor, ...
                'xy_factor', xy_factor, ...
                'target_xy', target_xy, ...
                'z_target', z_target, ...
                'target_slices', target_slices, ...
                'is_identity', isequal(target_xy, [ny, nx]) && numel(target_slices) == nz);
        end

        function [target_xy, target_slices] = proc_downsample_targets(app, dims3)
            request = Methods.ChunkyMethods.proc_downsample_request(app, dims3);
            target_xy = request.target_xy;
            target_slices = request.target_slices;
        end
    end
end
