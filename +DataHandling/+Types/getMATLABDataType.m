function [type_string, bits] = getMATLABDataType(bit_depth)
    if bit_depth <= 8
        bits = 8;
    elseif bit_depth <= 16
        bits = 16;
    elseif bit_depth <= 32
        bits = 32;
    elseif bit_depth <= 64
        bits = 64;
    else
        error('Unsupported bit depth: %d bits', bit_depth);
    end

    type_string = sprintf('uint%.f', bits);
end
