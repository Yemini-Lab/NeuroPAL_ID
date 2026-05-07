function reload(path)
    app = Program.app;
    app.video_info.file = path;
    if endsWith(lower(path), '.h5')
        data_info = h5info(path, '/data');
        dims = data_info.Dataspace.Size;
        if numel(dims) < 5
            dims(5) = 1;
        end
        app.video_info.ny = dims(1);
        app.video_info.nx = dims(2);
        app.video_info.nz = dims(3);
        app.video_info.nc = dims(4);
        app.video_info.nt = dims(5);
    else
        [~, ~, ext] = fileparts(path);
        switch lower(ext)
            case '.nd2'
                app.load_nd2(path);
            case {'.tif', '.tiff'}
                app.load_tif(path);
            case '.nwb'
                app.load_nwb(path);
            otherwise
                frame = app.retrieve_frame(1);
                app.video_info.ny = size(frame, 1);
                app.video_info.nx = size(frame, 2);
                app.video_info.nz = size(frame, 3);
                app.video_info.nc = size(frame, 4);
        end
    end

    app.video_info.aspect_ratio = app.video_info.ny/app.video_info.nx;  % Aspect Ratio
    app.video_info.cached = 1;                          % Frames cached
    app.video_frame_cache = [];
    app.video_frame_cache_key = struct('file', '', 't', NaN);

    Program.Helpers.set_bounds;
    Program.Routines.Processing.render;
end
