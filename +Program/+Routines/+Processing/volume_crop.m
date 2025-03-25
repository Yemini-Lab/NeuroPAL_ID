function volume_crop(volume)
    if nargin == 0
        volume = Program.state().active_volume;
    end

    app = Program.app;
    window = Program.window;

    Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab');
    check = uiconfirm(window, "Draw a bounding box on the volume to crop the image.", "NeuroPAL_ID", "Options", ["OK", "Cancel"]);
    if ~strcmp(check, "OK")
        return
    end

    roi = drawrectangle(app.proc_xyAxes,'Color','black','StripeColor','m');
    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');

    Program.rotation_gui.draw(app, roi);

    if app.EnabledebugmenuCheckBox.Value
        Program.Routines.Debug.rotation();
    end
end

