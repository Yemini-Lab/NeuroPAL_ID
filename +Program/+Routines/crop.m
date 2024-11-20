function crop()
    app = Program.GUI.app;
    mip_flag = 0;
    
    if ~app.ProcShowMIPCheckBox.Value
        mip_flag = 1;
        app.ProcShowMIPCheckBox.Value = 1;
        app.drawProcImage();
        drawnow;
    end
    
    Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab', event);
    check = uiconfirm(app.CELL_ID, "Draw a bounding box on the volume to crop the image.", "NeuroPAL_ID", "Options", ["OK", "Cancel"]);
    if ~strcmp(check, "OK")
        return
    end
    
    roi = drawrectangle(app.proc_xyAxes,'Color','black','StripeColor','m');
    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
    
    Program.Handlers.rotation.draw(roi);
    
    if mip_flag
        app.ProcShowMIPCheckBox.Value = 0;
        drawnow;
    end
end

