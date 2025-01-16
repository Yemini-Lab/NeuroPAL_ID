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
end

