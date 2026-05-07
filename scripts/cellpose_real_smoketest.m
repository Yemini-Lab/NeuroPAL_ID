function cellpose_real_smoketest()
%CELLPOSE_REAL_SMOKETEST Validate real Cellpose inference and centroid import.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);

python_path = fullfile(repo_root, 'venv', 'bin', 'python');
if isempty(getenv('NEUROPAL_CELLPOSE_PYTHON')) && exist(python_path, 'file') == 2
    setenv('NEUROPAL_CELLPOSE_PYTHON', python_path);
end

model_path = getenv('NEUROPAL_CELLPOSE_MODEL');
if isempty(model_path)
    model_path = fullfile(getenv('HOME'), 'Downloads', 'cellpose_000715');
    if exist(model_path, 'file') == 2
        setenv('NEUROPAL_CELLPOSE_MODEL', model_path);
    end
end

assert(exist(model_path, 'file') == 2, ...
    'Cellpose model file not found. Set NEUROPAL_CELLPOSE_MODEL or place cellpose_000715 in ~/Downloads.');

data = zeros(48, 40, 9, 4, 'uint16');
data(10:18, 12:20, 3:6, 1) = 1800;
data(24:34, 20:30, 4:8, 2) = 2400;
data(30:38, 8:16, 2:5, 3) = 3200;

[sp, params] = Methods.CellposeDetect.detect('cellpose_real_smoketest', ...
    data, [0.32, 0.32, 1.5], 'Mode', "cellpose", 'KeepArtifacts', false);

assert(~isempty(sp), 'Expected non-empty supervoxels from real Cellpose inference.');
assert(size(sp.positions, 2) == 3, 'Expected centroid positions in xyz columns.');
assert(strcmp(params.backend, 'cellpose'), 'Expected the Cellpose backend metadata.');
assert(strcmp(params.mode, 'cellpose'), 'Expected the real Cellpose mode metadata.');

neurons = Neurons.Image(sp, 'head', 'scale', [0.32, 0.32, 1.5]);
Methods.Utils.removeNearbyNeurons(neurons, 2, 2);
positions = neurons.get_positions();

assert(~isempty(positions), 'Expected imported neurons after Cellpose centroid conversion.');
assert(size(positions, 2) == 3, 'Expected imported neuron positions to remain xyz triplets.');

fprintf('Cellpose real smoke test passed with %d neurons using %s.\n', ...
    neurons.num_neurons(), params.mask_source);
disp(positions);
end
