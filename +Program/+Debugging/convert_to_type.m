function convert_to_type()
    app = Program.GUIHandling.app;
    current_image = getimage(app.proc_xyAxes);
    target_type = app.TypeDropDown.Value;
    image(app.proc_xyAxes, cast(current_image, target_type));
end

