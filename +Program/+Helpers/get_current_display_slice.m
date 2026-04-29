function [frame, z_gui, z_data] = get_current_display_slice(app, target, display_volume)
% Extract the current UI-selected z-slice for the requested target.

if nargin < 1 || isempty(app)
    app = Program.app;
end
if nargin < 2 || strlength(string(target)) == 0
    target = "main";
end
if nargin < 3 || isempty(display_volume)
    package = Program.Helpers.get_display_volume(app, target);
    display_volume = package.display_volume;
end

target = lower(string(target));

switch target
    case "main"
        z_gui = double(app.ZSlider.Value);
        if isstruct(app.image_prefs) && isfield(app.image_prefs, 'is_Z_flip')
            is_z_flip = app.image_prefs.is_Z_flip;
        else
            is_z_flip = false;
        end
    case "processing"
        z_gui = double(app.proc_zSlider.Value);
        is_z_flip = false;
    otherwise
        error('Unknown display target: %s', target);
end

[frame, z_gui, z_data] = Program.Helpers.extract_z_slice(display_volume, z_gui, is_z_flip);
end
