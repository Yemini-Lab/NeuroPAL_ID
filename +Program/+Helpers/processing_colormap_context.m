function context = processing_colormap_context(app)
% Return the current shared colormap runtime state for the main/processing tabs.

if nargin < 1 || isempty(app)
    app = Program.app;
end

volume = [];
if ~isempty(app.image_data)
    volume = app.image_data;
elseif isa(app.proc_image, 'matlab.io.MatFile')
    try
        volume = app.proc_image.data;
    catch
        volume = [];
    end
end

prefs = struct();
if isstruct(app.image_prefs) && ~isempty(fieldnames(app.image_prefs))
    prefs = app.image_prefs;
elseif isa(app.proc_image, 'matlab.io.MatFile')
    try
        prefs = app.proc_image.prefs;
    catch
        prefs = struct();
    end
end

source_path = "";
if ~isempty(app.image_file)
    source_path = string(app.image_file);
elseif isa(app.proc_image, 'matlab.io.MatFile')
    try
        source_path = string(app.proc_image.Properties.Source);
    catch
        source_path = "";
    end
end

if isempty(volume)
    dims = [0 0 0 0];
else
    dims = size(volume);
    if ndims(volume) == 3
        dims = [dims 1];
    end
    if numel(dims) < 4
        dims(end+1:4) = 1;
    end
end

dirty = isappdata(app.CELL_ID, 'proc_runtime_dirty') && ...
    logical(getappdata(app.CELL_ID, 'proc_runtime_dirty'));

context = struct( ...
    'volume', volume, ...
    'prefs', prefs, ...
    'path', char(source_path), ...
    'dims', dims, ...
    'dirty', dirty);
end
