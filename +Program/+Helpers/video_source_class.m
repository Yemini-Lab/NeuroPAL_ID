function class_name = video_source_class(app)
%VIDEO_SOURCE_CLASS Infer loaded video sample class without reading a frame.

class_name = 'uint8';

try
    file = char(app.video_info.file);
    if endsWith(lower(file), '.h5')
        sample = h5read(file, '/data', [1 1 1 1 1], [1 1 1 1 1]);
        class_name = class(sample);
        return
    end
catch
end

try
    bit_depth = parse_bit_depth(app.video_info.bitDepth);
    if isempty(bit_depth) || ~isfinite(bit_depth)
        return
    end

    if bit_depth <= 8
        class_name = 'uint8';
    elseif bit_depth <= 16
        class_name = 'uint16';
    elseif bit_depth <= 32
        class_name = 'uint32';
    else
        class_name = 'uint64';
    end
catch
end
end

function bit_depth = parse_bit_depth(value)
bit_depth = [];

if isnumeric(value) && isscalar(value)
    bit_depth = double(value);
    return
end

if ischar(value) || isstring(value)
    token = regexp(char(value), '\d+', 'match', 'once');
    if ~isempty(token)
        bit_depth = str2double(token);
    end
end
end
