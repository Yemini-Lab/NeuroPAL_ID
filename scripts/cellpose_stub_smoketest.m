function cellpose_stub_smoketest()
%CELLPOSE_STUB_SMOKETEST Validate the Cellpose stub wrapper and import contract.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);

data = zeros(48, 64, 12, 4, 'single');
data(12, 16, 4, 1) = 25;
data(24, 32, 6, 2) = 30;
data(36, 48, 8, 3) = 35;

[sp, params] = Methods.CellposeDetect.detect('cellpose_stub_smoketest', ...
    data, [0.32, 0.32, 1.0], 'Mode', "stub");
assert(~isempty(sp), 'Expected non-empty supervoxels from the Cellpose stub.');
assert(size(sp.positions, 2) == 3, 'Expected centroid positions in xyz columns.');

neurons = Neurons.Image(sp, 'head', 'scale', [0.32, 0.32, 1.0]);
Methods.Utils.removeNearbyNeurons(neurons, 2, 2);
positions = neurons.get_positions();

assert(~isempty(positions), 'Expected imported neurons after centroid conversion.');
assert(size(positions, 2) == 3, 'Expected neuron positions to remain xyz triplets.');
assert(strcmp(params.backend, 'cellpose'), 'Expected the Cellpose backend metadata.');
assert(strcmp(params.mode, 'stub'), 'Expected the stub mode metadata.');

fprintf('Cellpose stub smoke test passed with %d neurons.\n', neurons.num_neurons());
disp(positions);
end
