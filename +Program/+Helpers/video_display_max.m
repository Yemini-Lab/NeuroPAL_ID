function max_val = video_display_max(app)
%VIDEO_DISPLAY_MAX Return a threshold/display max without loading a frame.

max_val = 255;

try
    if isstruct(app.video_info) && isfield(app.video_info, 'bitDepth')
        bit_depth = parse_bit_depth(app.video_info.bitDepth);
        if ~isempty(bit_depth) && isfinite(bit_depth) && bit_depth > 0
            max_val = double(2 .^ bit_depth - 1);
            return
        end
    end
catch
end

try
    file = char(app.video_info.file);
    if endsWith(lower(file), '.h5')
        sample = h5read(file, '/data', [1 1 1 1 1], [1 1 1 1 1]);
        if isinteger(sample)
            max_val = double(intmax(class(sample)));
        else
            max_val = max(1, double(sample));
        end
    end
catch
    max_val = 255;
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
        return
    end
end
end
