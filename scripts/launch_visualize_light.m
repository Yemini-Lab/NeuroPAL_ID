repo_root = fileparts(fileparts(mfilename('fullpath')));
cd(repo_root);

app_path = fullfile(repo_root, 'visualize_light.mlapp');
if exist(app_path, 'file') ~= 2
    error('NeuroPAL:MissingApp', 'Could not find %s', app_path);
end

addpath(repo_root);
visualize_light;
