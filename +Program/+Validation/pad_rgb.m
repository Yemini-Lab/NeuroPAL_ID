function [arr, dims_out] = pad_rgb(arr)
    dims = size(arr);
    is_single_channel = length(size(arr)) == 2;

    if is_single_channel
        arr = reshape(arr, dims(1), dims(2), 1, 1);
    elseif ndims(arr) == 3
        arr = reshape(arr, dims(1), dims(2), dims(3), 1);
    end

    while size(arr, 4) < 3
        arr = cat(4, arr, zeros([size(arr, 1), size(arr, 2), size(arr, 3), 1], 'like', arr));
    end

    dims_out = size(arr);
end
