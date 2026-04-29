function synced = sync_main_display_from_processing(app, redraw_main)
% Copy processing-tab display state onto the main NeuroPAL tab.

if nargin < 1 || isempty(app)
    app = Program.app;
end
if nargin < 2
    redraw_main = true;
end

synced = false;
if isempty(app.image_data)
    return
end

guard_key = 'proc_sync_main_display_guard';
if isappdata(app.CELL_ID, guard_key) && logical(getappdata(app.CELL_ID, guard_key))
    return
end

setappdata(app.CELL_ID, guard_key, true);
cleanup = onCleanup(@() rmappdata(app.CELL_ID, guard_key));

state = Program.Handlers.channels.processing_state(app);
main_dropdowns = { ...
    'RDropDown', ...
    'GDropDown', ...
    'BDropDown', ...
    'WDropDown', ...
    'DICDropDown', ...
    'GFPDropDown'};
main_checks = { ...
    'RCheckBox', ...
    'GCheckBox', ...
    'BCheckBox', ...
    'WCheckBox', ...
    'DICCheckBox', ...
    'GFPCheckBox'};
rows = {state.r, state.g, state.b, state.white, state.dic, state.gfp};

for k = 1:numel(rows)
    idx = rows{k}.source_idx;
    items = string(app.(main_dropdowns{k}).Items);
    if idx >= 1 && idx <= numel(items)
        app.(main_dropdowns{k}).Value = char(items(idx));
    end
    app.(main_checks{k}).Value = logical(rows{k}.enabled);
end

if ~isstruct(app.image_prefs)
    app.image_prefs = struct();
end

existing_rgbw = nan(1, 4);
if isfield(app.image_prefs, 'RGBW')
    existing_rgbw = double(app.image_prefs.RGBW);
    if numel(existing_rgbw) < 4
        existing_rgbw(end+1:4) = nan;
    end
end

app.image_prefs.RGBW = [ ...
    local_required_idx(state.r, 1), ...
    local_required_idx(state.g, 2), ...
    local_required_idx(state.b, 3), ...
    local_optional_idx(state.white, existing_rgbw(4))];
app.image_prefs.DIC = local_optional_idx(state.dic, NaN);
app.image_prefs.GFP = local_optional_idx(state.gfp, NaN);

gammas = zeros(1, length(Program.GUIHandling.pos_prefixes));
for n = 1:length(Program.GUIHandling.pos_prefixes)
    gammas(n) = app.(sprintf('%s_GammaEditField', Program.GUIHandling.pos_prefixes{n})).Value;
end
app.image_gamma = gammas(:);
app.image_prefs.gamma = app.image_gamma;

if ~isempty(app.image_data)
    nz = size(app.image_data, 3);
    z_value = min(max(round(app.proc_zSlider.Value), 1), nz);
    Program.Helpers.configure_main_zslider(app, nz, z_value);
    app.ZSlider.Value = z_value;
    if isprop(app, 'ZSliderS') && isvalid(app.ZSliderS)
        app.ZSliderS.Limits = [1, nz];
        app.ZSliderS.Value = z_value;
    end
end

synced = true;
if redraw_main
    Program.Routines.ID.render();
end
end

function idx = local_required_idx(row, fallback)
idx = double(row.source_idx);
if ~isfinite(idx) || idx < 1
    idx = fallback;
end
end

function idx = local_optional_idx(row, fallback)
idx = double(row.source_idx);
if ~isfinite(idx) || idx < 1
    idx = fallback;
end
end
