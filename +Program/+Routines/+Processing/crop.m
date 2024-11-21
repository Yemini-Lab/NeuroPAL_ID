function crop()
    app = Program.GUIHandling.app;
    mip_flag = 0;

    if ~app.ProcShowMIPCheckBox.Value
        mip_flag = 1;
        app.ProcShowMIPCheckBox.Value = 1;
        Program.Routines.Processing.quick_render();
        drawnow;
    end

    Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab', event);
    check = uiconfirm(app.CELL_ID, "Draw a bounding box on the volume to crop the image.", "NeuroPAL_ID", "Options", ["OK", "Cancel"]);
    if ~strcmp(check, "OK")
        return
    end

    roi = drawrectangle(app.proc_xyAxes,'Color','black','StripeColor','m');
    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');

    Program.rotation_gui.draw(app, roi);

    if app.EnabledebugmenuCheckBox.Value
        Program.Routines.Debug.rotation();
    end

    if mip_flag
        app.ProcShowMIPCheckBox.Value = 0;
        Program.Routines.Processing.quick_render();
        drawnow;
    end
end

