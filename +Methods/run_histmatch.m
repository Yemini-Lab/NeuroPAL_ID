function matched_data = run_histmatch(image_data, RGBW)
    rgb_idx = double(RGBW(1:min(3, numel(RGBW))));
    rgb_idx = rgb_idx(rgb_idx >= 1 & rgb_idx <= size(image_data, 4));
    if numel(rgb_idx) < 3
        rgb_idx = 1:min(3, size(image_data, 4));
    end

    source_rgb = image_data(:,:,:,rgb_idx(1:3));
    display_rgb = Program.Helpers.to_user_uint8(source_rgb);
    matched_uint8 = uint8(Methods.MatchHist(uint64(display_rgb)));
    matched_data = local_restore_matched_channels(source_rgb, matched_uint8);
end

function restored = local_restore_matched_channels(source_rgb, matched_uint8)
    restored = zeros(size(source_rgb), 'like', source_rgb);

    for ch = 1:size(source_rgb, 4)
        reference = source_rgb(:,:,:,ch);
        ref_double = double(reference);
        finite_mask = isfinite(ref_double);
        if ~any(finite_mask(:))
            continue
        end

        ref_vals = ref_double(finite_mask);
        ref_min = min(ref_vals, [], 'all');
        ref_max = max(ref_vals, [], 'all');

        if ~isfinite(ref_min) || ~isfinite(ref_max) || ref_max <= ref_min
            restored(:,:,:,ch) = cast(ref_double, class(reference));
            continue
        end

        matched = double(matched_uint8(:,:,:,ch)) / 255;
        restored_channel = matched * (ref_max - ref_min) + ref_min;

        if isfloat(reference)
            restored(:,:,:,ch) = cast(restored_channel, class(reference));
        else
            restored_channel = min(max(round(restored_channel), ref_min), ref_max);
            restored(:,:,:,ch) = cast(restored_channel, class(reference));
        end
    end
end
