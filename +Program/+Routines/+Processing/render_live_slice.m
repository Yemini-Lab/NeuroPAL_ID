function render_live_slice()
app = Program.app;
[package, ~] = Program.Routines.Processing.get_cached_package(app);
render_dims = size(package.render_volume);
if numel(render_dims) < 4
    render_dims(4) = 1;
end

if app.ProcShowMIPCheckBox.Value
    xy_frame = local_get_live_mip_frame(app, package.render_volume, render_dims);
else
    [xy_frame, ~, ~] = Program.Helpers.get_current_display_slice(app, 'processing', package.render_volume);
end

Program.Routines.Processing.local_draw_frame(app, app.proc_xyAxes, xy_frame);
end

function frame = local_get_live_mip_frame(app, render_volume, render_dims)
cache_signature = jsonencode(struct( ...
    'render_dims', render_dims));

if isappdata(app.CELL_ID, 'proc_live_mip_cache')
    cache = getappdata(app.CELL_ID, 'proc_live_mip_cache');
    if isstruct(cache) && isfield(cache, 'signature') && strcmp(cache.signature, cache_signature)
        frame = cache.frame;
        return
    end
end

frame = squeeze(max(render_volume, [], 3));
setappdata(app.CELL_ID, 'proc_live_mip_cache', struct( ...
    'signature', cache_signature, ...
    'frame', frame));
end
