function reset()
    app = Program.GUIHandling.app;

    d = uiprogressdlg(app.CELL_ID, ...
        "Message", "Resetting processing preview...", ...
        "Title", "NeuroPAL_ID", ...
        "Indeterminate", "on");

    current_mode = lower(string(app.VolumeDropDown.Value));
    snapshot = Program.GUIHandling.get_processing_defaults(app, current_mode);

    d.Message = "Clearing temporary state...";
    switch current_mode
        case "colormap"
            app.volume_crop_roi = [];
            if isa(app.proc_image, 'matlab.io.MatFile')
                try
                    app.image_prefs = app.proc_image.prefs;
                    app.image_gamma = Program.Helpers.expand_gamma( ...
                        app.image_prefs.gamma, ...
                        length(Program.GUIHandling.pos_prefixes));
                catch
                end
                if ~isempty(app.image_data)
                    app.image_data = app.proc_image.data;
                    app.image_data_zscored = Methods.Preprocess.zscore_frame(app.image_data);
                end
            end
            if isappdata(app.CELL_ID, 'proc_runtime_dirty')
                rmappdata(app.CELL_ID, 'proc_runtime_dirty');
            end
            vol_size = Program.Helpers.processing_colormap_context(app).dims;
            ny = vol_size(1);
            nx = vol_size(2);
            nz = vol_size(3);
            nt = 1;
        case "video"
            app.video_crop_roi = [];
            nx = app.video_info.nx;
            ny = app.video_info.ny;
            nz = app.video_info.nz;
            nt = app.video_info.nt;
        otherwise
            nx = app.proc_xSlider.Limits(2);
            ny = app.proc_ySlider.Limits(2);
            nz = app.proc_zSlider.Limits(2);
            nt = max(1, app.proc_tSlider.Limits(2));
    end

    Program.GUIHandling.reset_processing_runtime_state(app);

    d.Message = "Restoring controls...";
    Program.Routines.GUI.set_limits(nx, ny, nz, nt);
    app.proc_xEditField.Value = app.proc_xSlider.Value;
    app.proc_yEditField.Value = app.proc_ySlider.Value;
    app.proc_zEditField.Value = app.proc_zSlider.Value;
    app.proc_tEditField.Value = app.proc_tSlider.Value;

    if ~isempty(fieldnames(snapshot))
        Program.GUIHandling.restore_processing_defaults(app, snapshot);
    else
        Program.GUIHandling.set_thresholds(app, 255);
    end

    d.Message = "Redrawing preview...";
    Program.Routines.Processing.render();
    if strcmp(current_mode, "colormap")
        Program.Helpers.sync_main_display_from_processing(app, true);
    end

    close(d);
end
