function save()
    app = Program.app;

    d = uiprogressdlg(Program.window, ...
        "Message", "Updating file...", ...
        "Indeterminate", "off");

    switch app.VolumeDropDown.Value
        case 'Colormap'
            Methods.ChunkyMethods.apply_colormap(app, fieldnames(app.flags), d);

        case 'Video'
            Methods.ChunkyMethods.apply_video(app, fieldnames(app.flags), d);
    end

    app.flags = struct();
    close(d)

    check = uiconfirm(Program.window, ...
        "Successfully updated file. Load into main tab?", "NeuroPAL_ID", ...
        "Options",["Yes", "No"]);
    if strcmp(check, "Yes")
        Program.Routines.Processing.pass_to_main();
    end
end