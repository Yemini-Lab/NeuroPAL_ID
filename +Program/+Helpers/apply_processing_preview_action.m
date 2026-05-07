function applied = apply_processing_preview_action(app, actions)
% Apply one or more processing actions to the shared in-memory colormap volume.

if nargin < 1 || isempty(app)
    app = Program.app;
end

applied = false;
if ~strcmpi(char(string(app.VolumeDropDown.Value)), 'Colormap')
    return
end

actions = cellstr(lower(string(actions)));
actions = actions(~cellfun('isempty', actions));
if isempty(actions)
    return
end

context = Program.Helpers.processing_colormap_context(app);
current_volume = context.volume;
if isempty(current_volume)
    if isfield(context, 'is_lazy') && context.is_lazy
        applied = local_apply_lazy_actions(app, context, actions);
    end
    return
end

for n = 1:numel(actions)
    action = actions{n};
    current_volume = Methods.ChunkyMethods.apply_vol(app, action, current_volume);
    if isfield(app.flags, action)
        app.flags = rmfield(app.flags, action);
    end
    if strcmpi(action, 'histmatch')
        if ~isstruct(app.image_prefs)
            app.image_prefs = struct();
        end
        app.image_prefs.is_matched = 1;
    end
end

app.image_data = current_volume;
app.image_data_zscored = Methods.Preprocess.zscore_frame(app.image_data);
setappdata(app.CELL_ID, 'proc_runtime_dirty', true);

Program.GUIHandling.clear_processing_preview_cache(app);

render_dims = size(app.image_data);
if ndims(app.image_data) == 3
    render_dims = [render_dims 1];
end
Program.GUIHandling.set_gui_limits(app, 'soft', [render_dims(1:4) 1]);

current_z = min(max(round(app.proc_zSlider.Value), 1), render_dims(3));
Program.Helpers.configure_main_zslider(app, render_dims(3), current_z);
app.ZSlider.Value = current_z;
if isprop(app, 'ZSliderS') && isvalid(app.ZSliderS)
    app.ZSliderS.Limits = [1, render_dims(3)];
    app.ZSliderS.Value = current_z;
end

if isgraphics(app.XY)
    app.XY.XLim = [0, render_dims(2)];
    app.XY.YLim = [0, render_dims(1)];
end

max_val = max(255, double(max(app.image_data, [], 'all')));
Program.GUIHandling.set_thresholds(app, max_val);
Program.Helpers.sync_main_display_from_processing(app, false);
Program.Routines.Processing.render();
Program.Routines.ID.render();

applied = true;
end

function applied = local_apply_lazy_actions(app, context, actions)
applied = false;

unsupported = intersect(actions, {'ds'});
if ~isempty(unsupported)
    uialert(app.CELL_ID, ...
        sprintf('The %s action is not yet chunk-safe for lazy colormap volumes. Crop/rotate/flip/channel-window actions can be streamed without full materialization.', ...
        strjoin(unsupported, ', ')), ...
        'Chunked Processing Limitation', 'Icon', 'warning');
    return
end

if ~isa(context.reader, 'matlab.io.MatFile') || strlength(string(context.path)) == 0
    return
end

dims = context.dims;
if numel(dims) < 4 || any(dims(1:4) <= 0)
    return
end

[folder, name, ~] = fileparts(context.path);
target_path = fullfile(folder, [name '_processed.mat']);
if exist(target_path, 'file') == 2
    delete(target_path);
end

source = context.reader;
metadata = local_read_metadata(source, app, actions);
save(target_path, '-struct', 'metadata', '-v7.3');
target = matfile(target_path, 'Writable', true);

d = uiprogressdlg(app.CELL_ID, ...
    'Title', 'NeuroPAL ID', ...
    'Message', 'Applying chunked colormap processing...', ...
    'Indeterminate', 'off');
cleanup = onCleanup(@() local_close_progress(d));

sample = source.data(:, :, 1, :);
sample = local_apply_actions_to_slice(app, sample, actions);
sample = local_ensure_4d(sample);
out_dims = [size(sample, 1), size(sample, 2), dims(3), size(sample, 4)];
target.data(out_dims(1), out_dims(2), out_dims(3), out_dims(4)) = cast(0, class(sample));
target.data(:, :, 1, :) = sample;

for z = 2:dims(3)
    d.Value = z / dims(3);
    d.Message = sprintf('Processing slice %d/%d...', z, dims(3));
    slice = source.data(:, :, z, :);
    slice = local_apply_actions_to_slice(app, slice, actions);
    slice = local_ensure_4d(slice);
    target.data(:, :, z, :) = slice;
end

app.image_file = target_path;
app.proc_image = matfile(target_path);
app.image_data = [];
app.image_data_zscored = [];
app.image_prefs = metadata.prefs;
for n = 1:numel(actions)
    if isfield(app.flags, actions{n})
        app.flags = rmfield(app.flags, actions{n});
    end
end
if isappdata(app.CELL_ID, 'proc_runtime_dirty')
    rmappdata(app.CELL_ID, 'proc_runtime_dirty');
end

Program.GUIHandling.clear_processing_preview_cache(app);
Program.GUIHandling.set_gui_limits(app, 'soft', [out_dims 1]);
Program.GUIHandling.set_thresholds(app, Program.Helpers.processing_colormap_max(app));
Program.Routines.Processing.render();
applied = true;
end

function metadata = local_read_metadata(source, app, actions)
metadata = struct();
vars = {'version', 'info', 'prefs', 'worm'};
for i = 1:numel(vars)
    name = vars{i};
    try
        metadata.(name) = source.(name);
    catch
    end
end

if ~isfield(metadata, 'prefs') || ~isstruct(metadata.prefs)
    metadata.prefs = app.image_prefs;
end
if any(strcmpi(actions, 'histmatch'))
    metadata.prefs.is_matched = 1;
end
end

function slice = local_apply_actions_to_slice(app, slice, actions)
for n = 1:numel(actions)
    slice = Methods.ChunkyMethods.apply_slice(app, actions{n}, slice);
end
end

function array = local_ensure_4d(array)
dims = size(array);
if numel(dims) == 2
    array = reshape(array, dims(1), dims(2), 1, 1);
elseif numel(dims) == 3
    array = reshape(array, dims(1), dims(2), 1, dims(3));
end
end

function local_close_progress(d)
try
    if ~isempty(d) && isvalid(d)
        close(d);
    end
catch
end
end
