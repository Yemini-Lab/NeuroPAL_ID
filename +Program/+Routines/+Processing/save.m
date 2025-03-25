function save()
    [app, window, ~] = Program.ctx;
    Program.dlg.add_task('Updating file');
    Program.Routines.Processing.apply()

    app.flags = struct();
    Program.dlg.resolve();

    check = uiconfirm(window, ...
        "Successfully updated file. Load into main tab?", "NeuroPAL_ID", ...
        "Options",["Yes", "No"]);
    if strcmp(check, "Yes")
        Program.Routines.Processing.pass_to_main();
    end
end