function [x, y, z, t] = parse_gui()
    app = Program.app;
    x = app.proc_xSlider.Value;
    y = app.proc_ySlider.Value;
    z = app.proc_zSlider.Value;
    t = app.proc_tSlider.Value;
end

