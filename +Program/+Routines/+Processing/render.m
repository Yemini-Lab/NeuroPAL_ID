function render()
    app = Program.app;
    Program.GUIHandling.ensure_processing_color_ui(app);
    Program.GUIHandling.update_processing_zslider_visibility(app);

    [package, package_info] = Program.Routines.Processing.get_cached_package(app);
    render_dims = local_volume_dims(package.render_volume);
    gui_limit_dims = local_gui_limit_dims(app, package, render_dims);
    view_reset_required = local_processing_view_reset_required(app, gui_limit_dims);
    if view_reset_required
        Program.GUIHandling.set_gui_limits(app, 'soft', gui_limit_dims);
    end

    Program.Handlers.dialogue.step('Rendering volume data...');
    [frames, ~] = Program.Routines.Processing.get_view_frames(app, package, package_info.package_signature);
    Program.Routines.Processing.draw_frames(app, frames);
    drawnow limitrate nocallbacks;

    if local_histograms_need_redraw(app)
        Program.Handlers.dialogue.step('Drawing histograms...');
        Program.Handlers.histograms.draw();
        Program.GUIHandling.shorten_knob_labels(app);
    end
end

function dims = local_volume_dims(volume)
dims = size(volume);
if numel(dims) < 4
    dims(4) = 1;
end
end

function dims = local_gui_limit_dims(app, package, render_dims)
dims = render_dims;
if isfield(package, 'raw') && isstruct(package.raw) && isfield(package.raw, 'state')
    switch lower(string(package.raw.state))
        case "colormap"
            if isfield(package.raw, 'dims') && numel(package.raw.dims) >= 4
                dims = package.raw.dims;
            end
        case "video"
            if isstruct(app.video_info) && isfield(app.video_info, 'nx')
                dims = [ ...
                    app.video_info.ny, ...
                    app.video_info.nx, ...
                    app.video_info.nz, ...
                    max(render_dims(4), app.video_info.nc), ...
                    app.video_info.nt];
            end
    end
end
end

function tf = local_processing_view_reset_required(app, dims)
tf = true;
key = 'proc_render_view_dims';

if isappdata(app.CELL_ID, key)
    previous_dims = getappdata(app.CELL_ID, key);
    tf = ~isequal(previous_dims, dims);
end

setappdata(app.CELL_ID, key, dims);
if tf
    return
end

tf = local_axes_out_of_bounds(app.proc_xyAxes, dims(2), dims(1));

if ~tf && app.ProcPreviewZslowCheckBox.Value
    tf = local_axes_out_of_bounds(app.proc_xzAxes, dims(2), dims(3)) || ...
        local_axes_out_of_bounds(app.proc_yzAxes, dims(3), dims(1));
end
end

function tf = local_axes_out_of_bounds(ax, nx, ny)
tf = true;
if isempty(ax) || ~isvalid(ax)
    return
end

xlim = ax.XLim;
ylim = ax.YLim;

tf = any(~isfinite([xlim ylim])) || ...
    xlim(1) < 1 || ylim(1) < 1 || ...
    xlim(2) > nx || ylim(2) > ny || ...
    diff(xlim) <= 0 || diff(ylim) <= 0;
end

function tf = local_histograms_need_redraw(app)
signature = Program.Helpers.processing_histogram_signature(app);
if isappdata(app.CELL_ID, 'proc_histogram_signature')
    cached_signature = getappdata(app.CELL_ID, 'proc_histogram_signature');
    if ischar(cached_signature) || isstring(cached_signature)
        tf = ~strcmp(char(cached_signature), signature);
    else
        tf = true;
    end
else
    tf = true;
end

if tf
    setappdata(app.CELL_ID, 'proc_histogram_signature', signature);
end
end
