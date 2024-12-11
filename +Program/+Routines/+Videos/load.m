function load(file)
    app = Program.app;
    app.video_path = file;
    [~, ~, ext] = fileparts(path);

    if strcmp(ext, '.h5')
        app.load_h5(file);
    elseif strcmp(ext, '.nwb')
        app.load_nwb(file);
    elseif strcmp(ext, '.nd2')
        app.load_nd2(file);
    end
end

