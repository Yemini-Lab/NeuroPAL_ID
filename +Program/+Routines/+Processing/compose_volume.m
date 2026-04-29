function package = compose_volume(app, raw)
if nargin < 1 || isempty(app)
    app = Program.app;
end
if nargin < 2 || isempty(raw)
    raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
end

[raw_volume, raw_dims] = Program.Validation.pad_rgb(raw.array);
preview_raw_volume = Methods.ChunkyMethods.apply_preview_actions(app, raw_volume);
display_package = Program.Helpers.get_display_volume(app, 'processing', preview_raw_volume);
channels = display_package.channels;
threshold_raw = display_package.threshold_raw;
render_volume = display_package.display_volume;

package = struct( ...
    'raw', raw, ...
    'raw_volume', raw_volume, ...
    'preview_raw_volume', preview_raw_volume, ...
    'raw_dims', raw_dims, ...
    'channels', channels, ...
    'render_volume', render_volume, ...
    'threshold_raw', threshold_raw);
end
