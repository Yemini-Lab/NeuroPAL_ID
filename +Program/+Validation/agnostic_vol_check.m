function is_video = agnostic_vol_check)
    app = Program.app;
    stack = dbstack;
    is_video = strcmpi(app.VolumeDropDown.Value, 'video') || contains(stack, 'TraceActivityMenu_2Selected');
end

