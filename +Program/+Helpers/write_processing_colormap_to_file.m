function saved = write_processing_colormap_to_file(app)
% Persist the shared in-memory colormap volume/prefs to the backing MAT file.

if nargin < 1 || isempty(app)
    app = Program.app;
end

saved = false;
if ~strcmpi(char(string(app.VolumeDropDown.Value)), 'Colormap')
    return
end

context = Program.Helpers.processing_colormap_context(app);
if isempty(context.volume) || strlength(string(context.path)) == 0
    return
end

Program.Helpers.sync_main_display_from_processing(app, false);

data = app.image_data;
prefs = app.image_prefs;

if isa(app.proc_image, 'matlab.io.MatFile')
    app.proc_image.Properties.Writable = true;
    cleanup = onCleanup(@() local_make_readonly(app));
    app.proc_image.data = data;
    if isstruct(prefs) && ~isempty(fieldnames(prefs))
        app.proc_image.prefs = prefs;
    end
else
    save(context.path, 'data', 'prefs', '-append');
end

if isappdata(app.CELL_ID, 'proc_runtime_dirty')
    rmappdata(app.CELL_ID, 'proc_runtime_dirty');
end

Program.GUIHandling.clear_processing_preview_cache(app);
saved = true;
end

function local_make_readonly(app)
if isa(app.proc_image, 'matlab.io.MatFile')
    app.proc_image.Properties.Writable = false;
end
end
