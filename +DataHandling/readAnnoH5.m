function [positions, labels] = readAnnoH5(path)
    positions = [];
    labels = {};

    [ppath, ~, ~] = fileparts(path);
    wl_path = fullfile(ppath, 'worldlines.h5');

    if exist(wl_path, 'file')
        wlid_key = struct();
        wlid_key.idx = h5read(wl_path, '/id');
        wlid_key.name = h5read(wl_path, '/name');
    else
        delete(wl_path);
        wlid_key = [];
    end

    num_anno = h5info(path, '/t_idx').Dataspace;
    for n=1:num_anno
        
        x = h5read(path, '/x', n, 1);
        y = h5read(path, '/y', n, 1);
        z = h5read(path, '/z', n, 1);
        t = h5read(path, '/t_idx', n, 1);
        positions = [positions; x y z t];

        wlid = h5read(path, '/worldline_id', n, 1);

        if ~isempty(wlid_key)
            labels{end+1} = wlid_key.name(ismember(wlid, wlid_key.idx));
        end
    end
end