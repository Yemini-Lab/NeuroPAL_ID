classdef h5
    %HDMF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [positions, labels] = load_tracks(filepath)
            [path, ~, ~] = fileparts(filepath);

            frame_results = h5read(filepath, '/t_idx');
            wlid_results = h5read(filepath, '/worldline_id');
            x_results = h5read(filepath, '/x');
            y_results = h5read(filepath, '/y');
            z_results = h5read(filepath, '/z');
    
            if isfile([path, 'worldlines.h5'])
                wl_idx = h5read([path, 'worldlines.h5'], '/id');
                wl_name = h5read([path, 'worldlines.h5'], '/name');
            else
                uiconfirm(app.CELL_ID, "Unable to import annotations due to lack of worldlines. Make sure your worldlines.h5 file is in the same folder as your annotations file.", "Error!");
                return
            end

            positions = [cast(frame_results+1, 'like', x_results), x_results, y_results, z_results];

            labels = cell(size(wlid_results));
            [~, idx] = ismember(wlid_results, wl_idx);
            for i = 1:length(wlid_results)
                if idx(i) > 0
                    labels{i} = wl_name{idx(i)};
                else
                    labels{i} = 'Unknown';
                end
            end

            labels = labels';
        end
    end
end

