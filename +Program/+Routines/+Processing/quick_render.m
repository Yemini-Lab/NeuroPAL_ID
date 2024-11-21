function quick_render()
    app = Program.GUIHandling.app;
    
    % Load appropriate volume
    frame = Methods.ChunkyMethods.load_proc_image(app);

    % Draw volume on appropriate axes.
    image(frame.xy, 'Parent', app.proc_xyAxes);
    if app.ProcPreviewZslowCheckBox.Value
        image(flipud(rot90(frame.yz)), 'Parent', app.proc_xzAxes);
        image(frame.xz, 'Parent', app.proc_yzAxes);
    end
end

