function max_val = processing_colormap_max(app)
%PROCESSING_COLORMAP_MAX Estimate a safe display maximum without full loads.

if nargin < 1 || isempty(app)
    app = Program.app;
end

context = Program.Helpers.processing_colormap_context(app);
if context.has_full_volume
    max_val = double(max(context.volume, [], 'all'));
    if isfinite(max_val) && max_val > 0
        return
    end
end

dims = context.dims;
if numel(dims) < 4 || any(dims(1:4) <= 0)
    max_val = 255;
    return
end

z_samples = unique(round(linspace(1, dims(3), min(dims(3), 7))));
max_val = 0;
for z = z_samples
    try
        slice = Program.Helpers.read_processing_colormap(app, ...
            'z', z, ...
            'channels', 1:dims(4), ...
            'mip', false);
        if ~isempty(slice)
            max_val = max(max_val, double(max(slice, [], 'all')));
        end
    catch
    end
end

if ~(isfinite(max_val) && max_val > 0)
    try
        sample = Program.Helpers.read_processing_colormap(app, 'z', 1, 'channels', 1);
        if isinteger(sample)
            max_val = double(intmax(class(sample)));
        else
            max_val = 255;
        end
    catch
        max_val = 255;
    end
end

if ~(isfinite(max_val) && max_val > 0)
    max_val = 255;
end
end
