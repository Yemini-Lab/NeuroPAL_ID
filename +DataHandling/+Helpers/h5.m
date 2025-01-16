classdef h5
    %HDMF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function load_tracks(filepath)
            [path, ~, ~] = fileparts(filepath);

            x_coords = h5read(filepath, '/x');
            y_coords = h5read(filepath, '/y');
            z_coords = h5read(filepath, '/z');

            frames = h5read(filepath, '/t_idx');
            if min(frames) == 0
                frames = frame + 1;
            end

            wlids = h5read(filepath, '/worldline_id');
            wl_idx = h5read([path, 'worldlines.h5'], '/id');
            wl_name = h5read([path, 'worldlines.h5'], '/name');

            cache = Program.Routines.Videos.tracks.cache;
            cache.Writable = true;
            cache.wl_record = wl_name;
            cache.provenances = {'HDMF'};
            [~, wl_ids] = ismember(wlids, wl_idx);
            cache.frames = [frames, x_coords, y_coords, z_coords, wl_name(wl_ids), 1, 1:length(x_coords)];
            cache.Writable = false;
            Program.Routines.Videos.tracks.save_cache(cache);
        end
    end
end

