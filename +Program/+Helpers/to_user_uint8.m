function volume = to_user_uint8(volume)
% Convert source-native image data to the canonical user-facing uint8 scale.

if isa(volume, 'uint8')
    return
end

if isfloat(volume)
    finite_vals = volume(isfinite(volume));
    if isempty(finite_vals)
        volume = zeros(size(volume), 'uint8');
        return
    end

    min_val = min(finite_vals, [], 'all');
    max_val = max(finite_vals, [], 'all');
    if max_val <= 1 && min_val >= 0
        volume = im2uint8(volume);
        return
    end

    if max_val <= min_val
        volume = zeros(size(volume), 'uint8');
        return
    end

    volume = uint8(round(255 * (double(volume) - double(min_val)) / ...
        (double(max_val) - double(min_val))));
    return
end

volume = im2uint8(volume);
end
