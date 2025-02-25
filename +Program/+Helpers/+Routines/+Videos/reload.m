function reload(path)
    app = Program.app;
    app.video_info.file = path;
    frame = app.retrieve_frame(1);

    app.video_info.ny = size(frame, 1);            % Height
    app.video_info.nx = size(frame, 2);            % Width
    app.video_info.nz = size(frame, 3);            % Slice count
    app.video_info.nc = size(frame, 4);            % Channel count
    app.video_info.aspect_ratio = app.video_info.ny/app.video_info.nx;  % Aspect Ratio
    app.video_info.cached = 1;                          % Frames cached

    Program.Helpers.set_bounds;
    Program.Routines.Processing.render;
end

