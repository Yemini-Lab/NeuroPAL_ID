function [arr, ndims] = pad_rgb(arr)
    dims = size(arr);
    is_single_channel = length(size(arr)) == 2;

    if is_single_channel
        for mc=1:2
            arr = cat(4, arr, zeros(dims)); 
        end

    elseif size(arr, 4) < 3
        arr = cat(4, arr, zeros([dims(1:3) 1]));
        
    end

    ndims = size(arr);
end

