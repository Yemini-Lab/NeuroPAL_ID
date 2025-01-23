function load(file)
    app = Program.app;
    app.video_path = file;
    [~, ~, ext] = fileparts(path);

    switch ext
        case '.h5'
            app.load_h5(file);
        case '.nwb'
            app.load_nwb(file);
        case '.nd2'
            app.load_nd2(file);
        case '.tif'
            app.load_tif()
    end

    cache_path = strrep(path, ext, '_vt_cache.mat');
    if exist(cache_path, "file") == 2
        prompt_msg = sprintf("Found existing neuron track cache:\n%s\nLoad tracks from this cache?", cache_path);
        check = uiconfirm(Program.window, ...
            prompt_msg, "NeuroPAL_ID", ...
            "Options", ["Yes", "No"]);

        if strcmp(check, "Yes")
            delete(path);
            Program.Routines.Videos.tracks.load(cache_path);
        end
    end
end

