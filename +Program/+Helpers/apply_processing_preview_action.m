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
