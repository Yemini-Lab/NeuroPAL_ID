function signature = processing_raw_signature(app)
% Build a cache key for the current processing source volume.

if nargin < 1 || isempty(app)
    app = Program.app;
end

payload = struct( ...
    'mode', char(string(app.VolumeDropDown.Value)), ...
    'dims', local_volume_dims(app), ...
    'time_index', local_time_index(app), ...
    'slice_index', local_slice_index(app), ...
    'show_mip', logical(app.ProcShowMIPCheckBox.Value), ...
    'max_source_idx', double(Program.Handlers.channels.processing_state(app).max_source_idx));

signature = jsonencode(payload);
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
