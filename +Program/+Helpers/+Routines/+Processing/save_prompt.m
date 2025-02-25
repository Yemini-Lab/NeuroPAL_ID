function save_prompt(action)
    app = Program.app;
    check = uiconfirm(app.CELL_ID, "Do you want to save this operation to the file?", "NeuroPAL_ID", "Options", ["Yes", "No, stick with preview"]);
    if strcmp(check, "Yes")
        app.proc_apply_processing(action);
        if isfield(app.flags, action)
            app.flags = rmfield(app.flags, action);
        end
    else
        app.flags.(action) = 1;
    end
end