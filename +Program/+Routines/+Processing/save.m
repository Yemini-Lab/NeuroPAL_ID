function save()
    app = Program.app;

    Program.Handlers.dialogue.add_task('Updating file...');

    switch app.VolumeDropDown.Value
        case 'Colormap'
            Methods.ChunkyMethods.apply_colormap(app, fieldnames(app.flags));

        case 'Video'
            Methods.ChunkyMethods.apply_video(app, fieldnames(app.flags));
    end

    app.flags = struct();
    Program.Handlers.dialogue.resolve();

    check = uiconfirm(Program.window, ...
        "Successfully updated file. Load into main tab?", "NeuroPAL_ID", ...
        "Options",["Yes", "No"]);
    if strcmp(check, "Yes")
        Program.Routines.Processing.pass_to_main();
    end
end