function response = runCellposeCentroids(volume, scale_um_xyz, options)
%RUNCELLPOSECENTROIDS Execute the Cellpose wrapper and decode centroid output.

arguments
    volume
    scale_um_xyz double
    options.Mode (1,1) string = "cellpose"
    options.PythonExecutable (1,1) string = ""
    options.ModelPath (1,1) string = ""
    options.Prefix (1,1) string = "cellpose_volume"
    options.MaskSource (1,1) string = "stitched"
    options.OutputDir (1,1) string = ""
    options.KeepArtifacts (1,1) logical = false
    options.SaveMasksMat (1,1) logical = false
end

scale_um_xyz = double(scale_um_xyz(:)');
if numel(scale_um_xyz) ~= 3
    error('Wrapper:InvalidScale', ...
        'scale_um_xyz must contain exactly 3 values in [x y z] order.');
end

request.volume = volume;
request.scale_um_xyz = scale_um_xyz;
volume_shape = size(volume);
if numel(volume_shape) < 4
    volume_shape(end+1:4) = 1;
end

wrapper_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(wrapper_dir);

python_executable = local_pick_python(repo_root, char(options.PythonExecutable));
if isempty(python_executable)
    error('Wrapper:NoPython', ...
        ['Could not resolve a Python interpreter. Set NEUROPAL_CELLPOSE_PYTHON, ' ...
         'pass the PythonExecutable option, or install Cellpose into ./venv.']);
end

model_path = local_pick_model(repo_root, char(options.ModelPath));
if options.Mode ~= "stub" && isempty(model_path)
    error('Wrapper:NoCellposeModel', ...
        ['Could not resolve a Cellpose model file. Set NEUROPAL_CELLPOSE_MODEL, ' ...
         'pass the ModelPath option, or place the model at +CellPose/models/cellpose_000715.']);
end

output_dir = char(options.OutputDir);
cleanup_output_dir = false;
if isempty(strtrim(output_dir))
    output_dir = tempname;
    cleanup_output_dir = ~options.KeepArtifacts;
end
if exist(output_dir, 'dir') ~= 7
    [ok, msg] = mkdir(output_dir);
    if ~ok
        error('Wrapper:OutputDir', ...
            'Could not create Cellpose output directory %s: %s', output_dir, msg);
    end
end
output_dir = local_realpath(output_dir);

volume_path = [tempname, '.mat'];
request_path = [tempname, '.json'];
response_path = [tempname, '.json'];
cleanup_obj = onCleanup(@() cleanup_temp_files({volume_path, request_path, response_path}, ...
    output_dir, cleanup_output_dir));

save(volume_path, '-struct', 'request', '-v7');

request_manifest = struct();
request_manifest.version = 2;
request_manifest.mode = char(options.Mode);
request_manifest.scale_um_xyz = scale_um_xyz;
request_manifest.model_path = model_path;
request_manifest.prefix = char(options.Prefix);
request_manifest.mask_source = char(options.MaskSource);
request_manifest.save_masks_mat = options.SaveMasksMat;
request_manifest.output_dir = output_dir;
request_manifest.keep_artifacts = options.KeepArtifacts;
request_manifest.volume_source = struct( ...
    'path', volume_path, ...
    'format', 'mat', ...
    'axis_order', 'XYZC', ...
    'index_base', 1, ...
    'shape_xyzc', volume_shape);
request_fid = fopen(request_path, 'w');
if request_fid == -1
    error('Wrapper:RequestWriteFailed', ...
        'Unable to write Cellpose request manifest: %s', request_path);
end
fwrite(request_fid, jsonencode(request_manifest), 'char');
fclose(request_fid);

script_path = fullfile(wrapper_dir, 'cellpose_centroids.py');

command = local_join_quoted_command({ ...
    python_executable, script_path, ...
    '--input', request_path, ...
    '--output', response_path, ...
    '--mode', char(options.Mode)});
[status, output] = system(command);
if status ~= 0
    error('Wrapper:CellposeCommandFailed', ...
        'Cellpose wrapper command failed (%d).\nCommand:\n%s\n\nOutput:\n%s', ...
        status, command, strtrim(output));
end

if ~exist(response_path, 'file')
    error('Wrapper:MissingResponse', ...
        'Cellpose wrapper did not create a response file: %s', response_path);
end

response = jsondecode(fileread(response_path));
end

function cleanup_temp_files(paths, output_dir, cleanup_output_dir)
for i = 1:numel(paths)
    if exist(paths{i}, 'file')
        delete(paths{i});
    end
end
if cleanup_output_dir && exist(output_dir, 'dir') == 7
    try
        rmdir(output_dir, 's');
    catch
        % Leave artifacts behind if the OS still has handles open.
    end
end
end

function path_value = local_pick_python(repo_root, python_candidate)
path_value = strtrim(char(string(python_candidate)));
if isempty(path_value)
    path_value = strtrim(getenv('NEUROPAL_CELLPOSE_PYTHON'));
end
candidate_paths = {
    path_value
    fullfile(repo_root, 'venv', 'bin', 'python')
    fullfile(repo_root, 'neuropal_env_new', 'bin', 'python')
    'python3'
    'python'
    };
path_value = '';
for i = 1:numel(candidate_paths)
    resolved = local_realpath_interpreter(candidate_paths{i});
    if ~isempty(resolved)
        path_value = resolved;
        return;
    end
end
end

function model_path = local_pick_model(repo_root, model_candidate)
model_path = strtrim(char(string(model_candidate)));
if isempty(model_path)
    model_path = strtrim(getenv('NEUROPAL_CELLPOSE_MODEL'));
end
candidate_paths = {
    model_path
    fullfile(repo_root, '+CellPose', 'models', 'cellpose_000715')
    fullfile(getenv('HOME'), 'Downloads', 'cellpose_000715')
    };
model_path = '';
for i = 1:numel(candidate_paths)
    candidate = local_realpath(candidate_paths{i});
    if ~isempty(candidate) && exist(candidate, 'file') == 2
        model_path = candidate;
        return;
    end
end
end

function path_value = local_realpath(path_value)
path_value = strtrim(char(string(path_value)));
if isempty(path_value)
    return
end
[tf, attr] = fileattrib(path_value);
if tf
    path_value = attr.Name;
end
end

function path_value = local_realpath_interpreter(path_value)
path_value = strtrim(char(string(path_value)));
if isempty(path_value)
    return
end
[tf, attr] = fileattrib(path_value);
if tf && exist(attr.Name, 'file') == 2
    path_value = attr.Name;
    return
end
if ispc
    [status, result] = system(['where ' path_value ' 2>nul']);
else
    [status, result] = system(['command -v ' path_value ' 2>/dev/null']);
end
if status ~= 0
    path_value = '';
    return
end
result = strtrim(result);
newline_i = find(result == newline, 1);
if ~isempty(newline_i)
    result = result(1:newline_i-1);
end
[tf, attr] = fileattrib(result);
if tf
    path_value = attr.Name;
else
    path_value = result;
end
end

function command = local_join_quoted_command(parts)
quote_part = @(value) ['"' strrep(char(value), '"', '\"') '"'];
pieces = cellfun(@(value) [quote_part(value) ' '], parts, 'UniformOutput', false);
command = strtrim([pieces{:}]);
end
