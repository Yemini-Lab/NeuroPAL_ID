function synced = sync_processing_from_main(app, image_path)
synced = false;

if nargin < 2
    image_path = "";
end

if isempty(app.image_data) || isempty(app.image_file)
    Program.Helpers.debug_event('ProcSync', 'Skipped: no main image loaded');
    return
end

current_path = string(app.image_file);
target_path = string(image_path);
if strlength(target_path) > 0 && current_path ~= target_path
    Program.Helpers.debug_event('ProcSync', ...
        'Skipped: main image path %s does not match target %s', ...
        current_path, target_path);
    return
end

channel_count = min(6, length(app.proc_channel_grid.RowHeight));
main_values = { ...
    app.RDropDown.Value, ...
    app.GDropDown.Value, ...
    app.BDropDown.Value, ...
    app.WDropDown.Value, ...
    app.DICDropDown.Value, ...
    app.GFPDropDown.Value};
main_bools = [ ...
    app.RCheckBox.Value, ...
    app.GCheckBox.Value, ...
    app.BCheckBox.Value, ...
    app.WCheckBox.Value, ...
    app.DICCheckBox.Value, ...
    app.GFPCheckBox.Value];

for c = 1:channel_count
    dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
    cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
    items = app.(dd_handle).Items;

    idx = str2double(string(main_values{c}));
    if ~isempty(items) && isfinite(idx) && idx >= 1 && idx <= numel(items)
        app.(dd_handle).Value = items{idx};
    end

    app.(cb_handle).Value = main_bools(c);
end

gammas = Program.Helpers.expand_gamma(app.image_gamma, length(Program.GUIHandling.pos_prefixes));
for n = 1:length(Program.GUIHandling.pos_prefixes)
    app.(sprintf('%s_GammaEditField', Program.GUIHandling.pos_prefixes{n})).Value = gammas(n);
end

z_value = min(max(round(app.ZSlider.Value), app.proc_zSlider.Limits(1)), app.proc_zSlider.Limits(2));
Program.GUIHandling.suspend_processing_zslider_callbacks(app, true);
cleanup = onCleanup(@() Program.GUIHandling.suspend_processing_zslider_callbacks(app, false));
app.proc_zSlider.Value = z_value;
app.proc_zEditField.Value = z_value;
app.proc_hor_zSlider.Value = z_value;
app.proc_vert_zSlider.Value = z_value;

Program.Helpers.debug_event('ProcSync', ...
    'Inherited main display state: path=%s rgbwdgfp=%s checks=%s gammas=%s z=%d', ...
    current_path, ...
    mat2str(cellfun(@str2double, main_values)), ...
    mat2str(main_bools), ...
    mat2str(gammas), ...
    z_value);

synced = true;
end
