function context = processing_colormap_context(app)
% Return the current shared colormap runtime state for the main/processing tabs.

if nargin < 1 || isempty(app)
    app = Program.app;
end

volume = [];
reader = [];
source_class = 'uint8';
has_full_volume = false;
is_lazy = false;

if ~isempty(app.image_data)
    volume = app.image_data;
    has_full_volume = true;
    source_class = class(volume);
elseif isa(app.proc_image, 'matlab.io.MatFile')
    reader = app.proc_image;
    is_lazy = true;
    try
        sample = reader.data(1, 1, 1, 1);
        source_class = class(sample);
    catch
        source_class = 'uint8';
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

if has_full_volume
    dims = size(volume);
elseif isa(reader, 'matlab.io.MatFile')
    try
        dims = size(reader, 'data');
    catch
        dims = [0 0 0 0];
    end
else
    dims = [0 0 0 0];
end

if isempty(dims)
    dims = [0 0 0 0];
else
    if numel(dims) == 3
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
    'reader', reader, ...
    'prefs', prefs, ...
    'path', char(source_path), ...
    'dims', dims, ...
    'source_class', source_class, ...
    'has_full_volume', has_full_volume, ...
    'is_lazy', is_lazy, ...
    'dirty', dirty);
end
