function [frames, info] = get_view_frames(app, package, package_signature)
if nargin < 1 || isempty(app)
    app = Program.app;
end
if nargin < 2 || isempty(package)
    [package, package_info] = Program.Routines.Processing.get_cached_package(app);
    if nargin < 3 || isempty(package_signature)
        package_signature = package_info.package_signature;
    end
end
if nargin < 3 || isempty(package_signature)
    package_signature = Program.Helpers.processing_render_signature(app);
end

render_volume = package.render_volume;
render_dims = local_volume_dims(render_volume);
view_signature = local_view_signature(app, package_signature, render_dims);

info = struct( ...
    'signature', view_signature, ...
    'cache_hit', false, ...
    'mip_cache_hit', false);

if isappdata(app.CELL_ID, 'proc_view_cache')
    cache = getappdata(app.CELL_ID, 'proc_view_cache');
    if isstruct(cache) && isfield(cache, 'signature') && strcmp(cache.signature, view_signature)
        frames = cache.frames;
        info.cache_hit = true;
        return
    end
end

if app.ProcShowMIPCheckBox.Value
    [xy_frame, info.mip_cache_hit] = local_get_cached_mip_frame(app, render_volume, package_signature, render_dims);
else
    [xy_frame, ~, ~] = Program.Helpers.get_current_display_slice(app, 'processing', render_volume);
end

if app.ProcPreviewZslowCheckBox.Value
    [row_idx, col_idx] = local_cross_section_indices(app, render_volume);
    xz_frame = flipud(rot90(squeeze(render_volume(row_idx, :, :, :, :))));
    yz_frame = squeeze(render_volume(:, col_idx, :, :, :));
else
    xz_frame = [];
    yz_frame = [];
end

frames = struct( ...
    'xy', xy_frame, ...
    'xz', xz_frame, ...
    'yz', yz_frame, ...
    'render_dims', render_dims);

setappdata(app.CELL_ID, 'proc_view_cache', struct( ...
    'signature', view_signature, ...
    'frames', frames));
end

function dims = local_volume_dims(volume)
dims = size(volume);
if numel(dims) < 4
    dims(4) = 1;
end
end

function signature = local_view_signature(app, package_signature, render_dims)
payload = struct( ...
    'package_signature', package_signature, ...
    'render_dims', render_dims, ...
    'show_mip', logical(app.ProcShowMIPCheckBox.Value), ...
    'preview_zslow', logical(app.ProcPreviewZslowCheckBox.Value), ...
    'x', double(app.proc_xSlider.Value), ...
    'y', double(app.proc_ySlider.Value), ...
    'z', double(app.proc_zSlider.Value));
signature = jsonencode(payload);
end

function [frame, cache_hit] = local_get_cached_mip_frame(app, render_volume, package_signature, render_dims)
cache_hit = false;
cache_signature = jsonencode(struct( ...
    'package_signature', package_signature, ...
    'render_dims', render_dims));

if isappdata(app.CELL_ID, 'proc_mip_cache')
    cache = getappdata(app.CELL_ID, 'proc_mip_cache');
    if isstruct(cache) && isfield(cache, 'signature') && strcmp(cache.signature, cache_signature)
        frame = cache.frame;
        cache_hit = true;
        return
    end
end

frame = squeeze(max(render_volume, [], 3));
setappdata(app.CELL_ID, 'proc_mip_cache', struct( ...
    'signature', cache_signature, ...
    'frame', frame));
end

function [row_idx, col_idx] = local_cross_section_indices(app, render_volume)
row_idx = min(max(round(app.proc_ySlider.Value), 1), size(render_volume, 1));
col_idx = min(max(round(app.proc_xSlider.Value), 1), size(render_volume, 2));
end
