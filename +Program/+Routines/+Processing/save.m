function save(specific_action)
    app = Program.app;

    d = uiprogressdlg(Program.window, ...
        "Message", "Updating file...", ...
        "Indeterminate", "off");

    if ~exist('specific_action', 'var')
        switch app.VolumeDropDown.Value
            case 'Colormap'
                Methods.ChunkyMethods.apply_colormap(app, fieldnames(app.flags), d); 
                fEvent.file = app.proc_image.Properties.Source;
                app.OpenFile(fEvent);  
            case 'Video'
                Methods.ChunkyMethods.apply_video(app, fieldnames(app.flags), d);
        end

        app.flags = struct();

    else
        switch app.VolumeDropDown.Value
            case 'Colormap'
                Methods.ChunkyMethods.apply_colormap(app, {specific_action}, d);
                fEvent.file = app.proc_image.Properties.Source;
                app.OpenFile(fEvent);  

            case 'Video'
                Methods.ChunkyMethods.apply_video(app, {specific_action}, d);
        end

    end
    
    close(d)

    check = uiconfirm(Program.Window, ...
        "Successfully updated file. Load into main tab?", "NeuroPAL_ID", ...
        "Options",["Yes", "No"]);
    if strcmp(check, "Yes")
        Program.Routines.Processing.pass_to_main();
    end
end