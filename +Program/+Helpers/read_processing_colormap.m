function array = read_processing_colormap(app, varargin)
%READ_PROCESSING_COLORMAP Read a bounded processing preview from a colormap.

if nargin < 1 || isempty(app)
    app = Program.app;
end

p = inputParser;
addParameter(p, 'channels', []);
addParameter(p, 'z', []);
addParameter(p, 'mip', false);
parse(p, varargin{:});

context = Program.Helpers.processing_colormap_context(app);
dims = context.dims;
if numel(dims) < 4 || any(dims(1:4) <= 0)
    array = zeros(0, 0, 0, 0, context.source_class);
    return
end

channels = double(p.Results.channels);
if isempty(channels)
    channels = 1:dims(4);
end
channels = unique(round(channels(:).'), 'stable');
channels = channels(isfinite(channels) & channels >= 1 & channels <= dims(4));
if isempty(channels)
    channels = 1;
end

if logical(p.Results.mip)
    array = local_read_mip(context, dims, channels);
else
    z = p.Results.z;
    if isempty(z) || ~isnumeric(z) || ~isscalar(z) || ~isfinite(z)
        z = 1;
    end
    z = min(max(round(z), 1), dims(3));
    array = local_read_slice(context, z, channels);
end

array = local_ensure_4d(array);
end

function array = local_read_mip(context, dims, channels)
if context.has_full_volume
    array = max(context.volume(:, :, :, channels), [], 3);
    array = local_ensure_4d(array);
    return
end

array = zeros(dims(1), dims(2), 1, numel(channels), context.source_class);
for z = 1:dims(3)
    slice = local_read_slice(context, z, channels);
    if z == 1
        array = slice;
    else
        array = max(array, slice);
    end
end
end

function slice = local_read_slice(context, z, channels)
if context.has_full_volume
    slice = context.volume(:, :, z, channels);
elseif isa(context.reader, 'matlab.io.MatFile')
    slice = context.reader.data(:, :, z, channels);
else
    slice = zeros(context.dims(1), context.dims(2), 1, numel(channels), context.source_class);
end
slice = local_ensure_4d(slice);
end

function array = local_ensure_4d(array)
dims = size(array);
if numel(dims) == 2
    array = reshape(array, dims(1), dims(2), 1, 1);
elseif numel(dims) == 3
    array = reshape(array, dims(1), dims(2), 1, dims(3));
end
end
