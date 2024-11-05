function arr = apply_actions(arr)
    app = Program.GUIHandling.app;
    actions = fieldnames(app.flags);
    for a=1:length(actions)
        action = actions{a};
        if app.flags.(action) == 1
            arr = Methods.ChunkyMethods.apply_vol(app, action, arr);
        end
    end
end

