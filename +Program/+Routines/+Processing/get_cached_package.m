function [package, info] = get_cached_package(app)
if nargin < 1 || isempty(app)
    app = Program.app;
end

signature = Program.Helpers.processing_render_signature(app);
use_cache = strcmp(char(string(app.VolumeDropDown.Value)), 'Colormap');

info = struct( ...
    'package_signature', signature, ...
    'use_cache', use_cache, ...
    'package_cache_hit', false, ...
    'raw_cache_hit', false);

if use_cache && isappdata(app.CELL_ID, 'proc_render_cache')
    cache = getappdata(app.CELL_ID, 'proc_render_cache');
    if isstruct(cache) && isfield(cache, 'signature') && strcmp(cache.signature, signature)
        package = cache.package;
        info.package_cache_hit = true;
        info.raw_cache_hit = true;
        return
    end
end

if use_cache
    [raw, info.raw_cache_hit] = local_get_cached_raw_payload(app);
else
    raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
end

package = Program.Routines.Processing.compose_volume(app, raw);

if use_cache
    setappdata(app.CELL_ID, 'proc_render_cache', struct( ...
        'signature', signature, ...
        'package', package));
end
end

function [raw, cache_hit] = local_get_cached_raw_payload(app)
cache_hit = false;
raw_key = Program.Helpers.processing_raw_signature(app);
if isappdata(app.CELL_ID, 'proc_raw_cache')
    cache = getappdata(app.CELL_ID, 'proc_raw_cache');
    if isstruct(cache) && isfield(cache, 'signature') && strcmp(cache.signature, raw_key)
        raw = cache.raw;
        cache_hit = true;
        return
    end
end

raw = local_get_full_colormap_payload(app);
setappdata(app.CELL_ID, 'proc_raw_cache', struct( ...
    'signature', raw_key, ...
    'raw', raw));
end

function raw = local_get_full_colormap_payload(app)
context = Program.Helpers.processing_colormap_context(app);
volume = context.volume;
state = Program.Handlers.channels.processing_state(app);
max_idx = state.max_source_idx;
if max_idx < 1
    dims = context.dims;
    channel_class = 'uint8';
    if ~isempty(volume)
        channel_class = class(volume);
    end
    array = zeros(dims(1), dims(2), dims(3), 1, channel_class);
else
    if isempty(volume)
        dims = context.dims;
        array = zeros(dims(1), dims(2), dims(3), 1, 'uint8');
    else
        max_idx = min(max_idx, size(volume, 4));
        array = volume(:, :, :, 1:max_idx);
    end
end
if ndims(array) == 3
    array = reshape(array, size(array,1), size(array,2), size(array,3), 1);
end
raw = struct( ...
    'state', 'colormap', ...
    'dims', size(array), ...
    'array', array, ...
    'coords', [app.proc_xSlider.Value, app.proc_ySlider.Value, app.proc_zSlider.Value, app.proc_tSlider.Value]);
end
