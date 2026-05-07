function signature = processing_render_signature(app)
% Build a deterministic signature for the current processing render state.

if nargin < 1 || isempty(app)
    app = Program.app;
end

state = Program.Handlers.channels.processing_state(app);
rows = arrayfun(@local_row_signature, state.rows, 'UniformOutput', false);
dims = local_volume_dims(app);
downsample = local_downsample_request(app, dims);

payload = struct( ...
    'mode', char(string(app.VolumeDropDown.Value)), ...
    'dims', dims, ...
    'time_index', local_time_index(app), ...
    'slice_index', local_slice_index(app), ...
    'show_mip', logical(app.ProcShowMIPCheckBox.Value), ...
    'threshold_raw', 0, ...
    'xy_factor', downsample.xy_factor, ...
    'z_slices', downsample.z_target, ...
    'rotate_angle', double(app.proc_rot_spinner.Value), ...
    'flip_lr', logical(app.flip_lr.Value), ...
    'flip_ud', logical(app.flip_ud.Value), ...
    'flags', app.flags, ...
    'spectral_cache', Methods.ChunkyMethods.spectral_cache_signature(app), ...
    'rows', {rows});

signature = jsonencode(payload);
end

function row = local_row_signature(row)
row = struct( ...
    'row', row.row, ...
    'role', char(string(row.role_key)), ...
    'enabled', logical(row.enabled), ...
    'source_idx', double(row.source_idx), ...
    'gamma', double(row.settings.gamma), ...
    'low_high_in', double(row.settings.low_high_in), ...
    'low_high_out', double(row.settings.low_high_out));
end

function dims = local_volume_dims(app)
switch char(string(app.VolumeDropDown.Value))
    case 'Colormap'
        dims = Program.Helpers.processing_colormap_context(app).dims;
    case 'Video'
        dims = [app.video_info.ny, app.video_info.nx, app.video_info.nz, app.video_info.nc, app.video_info.nt];
    otherwise
        dims = [];
end
end

function t_idx = local_time_index(app)
if strcmp(char(string(app.VolumeDropDown.Value)), 'Video')
    t_idx = double(app.proc_tSlider.Value);
else
    t_idx = 1;
end
end

function z_idx = local_slice_index(app)
if strcmp(char(string(app.VolumeDropDown.Value)), 'Colormap') && ...
        ~logical(app.ProcShowMIPCheckBox.Value)
    z_idx = double(app.proc_zSlider.Value);
else
    z_idx = 1;
end
end

function request = local_downsample_request(app, dims)
if numel(dims) < 3 || isempty(dims)
    request = struct('xy_factor', double(app.ProcXYFactorEditField.Value), ...
        'z_target', double(app.ProcZSlicesEditField.Value));
    return
end

request = Methods.ChunkyMethods.proc_downsample_request(app, dims(1:3));
end
