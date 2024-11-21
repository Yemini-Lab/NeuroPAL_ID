function reset()
    app = Program.GUIHandling.app;

    d = uiprogressdlg(app.CELL_ID, "Message", "Resetting volume...", "Title", "NeuroPAL_ID", "Indeterminate", "on");
    
    d.Message = "Clearing ROIs...";
    switch app.VolumeDropDown.Value
        case 'Colormap'
            app.volume_crop_roi = [];

            vol_size = size(app.proc_image, 'data');

            nx = vol_size(1);
            ny = vol_size(2);
            nz = vol_size(3);

        case 'Video'
            app.video_crop_roi = [];

            nx = app.video_info.nx;
            ny = app.video_info.ny;
            nz = app.video_info.nz;
    end

    d.Message = "Resetting GUI...";
    app.proc_xyAxes.XLim = [1, nx];
    app.proc_xyAxes.YLim = [1, ny];

    app.proc_xzAxes.XLim = [1, nx];
    app.proc_yzAxes.YLim = [1, ny];

    app.proc_xSlider.Limits = [1, nx];
    app.proc_ySlider.Limits = [1, ny];
    app.proc_hor_zSlider.Limits = [1, nz];
    app.proc_vert_zSlider.Limits = [1, nz];

    app.proc_xSlider.Value = round(nx/2);
    app.proc_ySlider.Value = round(ny/2);
    app.proc_hor_zSlider.Value = round(nz/2);
    app.proc_vert_zSlider.Value = round(nz/2);

    d.Message = "Redrawing clean volume...";
    app.flags = struct();
    app.spectral_cache = struct( ...
        'ch_db', {[]}, ...
        'ch_px', {{}}, ...
        'ch_val', {[]}, ...
        'bg_px', {[]}, ...
        'bg_val', {[]}, ...
        'blurred_img', {[]});

    Program.Routines.Processing.quick_render();

    close(d);
end

