function [is_valid_dtype, bit_depth, dtype_str, dtype_max] = resolve_dtype(bit_depth)
    switch class(bit_depth)
        case {'string', 'char'}
            dtype_str = bit_depth;
            bit_depth = str2double(extract(dtype_str, digitsPattern));

        case {'Program.volume', 'struct'}
            if ~isempty(bit_depth.dtype) && bit_depth.dtype ~= 0
                bit_depth = bit_depth.dtype;
            elseif ~isempty(bit_depth.dtype_str)
                [is_valid_dtype, bit_depth, dtype_str, dtype_max] = Program.Helpers.resolve_dtype(bit_depth.dtype_str);
                return
            end

        case ~isinteger(bit_depth)
            error("Invalid bit depth %s of class %s passed to resolve_dtype.", bit_depth, class(bit_depth));
    end

    is_valid_dtype = mod(bit_depth, 8) == 0;
    if ~is_valid_dtype
        valid_dtypes = 8:8:64;
        [~, closest_valid_dtype] = min(abs(bit_depth-valid_dtypes));
        bit_depth = valid_dtypes(closest_valid_dtype);
    end

    dtype_str = sprintf('uint%.f', bit_depth);
    dtype_max = intmax(dtype_str);
end

