function set_limits(nx, ny, nz, nt)
    app = Program.app;

    app.proc_xSlider.Limits = [1 nx];
    app.proc_ySlider.Limits = [1 ny];

    middle_x = round(nx/2);
    middle_y = round(ny/2);
    middle_z = round(nz/2);

    app.proc_xSlider.Value = middle_x;
    app.proc_ySlider.Value = middle_y;

    Program.Helpers.configure_processing_zsliders(app, nz, middle_z);
    app.ProcZSlicesEditField.Value = nz;

    if nargin >= 4 && ~isempty(nt)
        nt = max(1, round(double(nt)));
        Program.GUIHandling.configure_processing_tslider(app, nt);
        app.proc_tSlider.Value = 1;
        app.ProcTStartEditField.Limits = [1, max(2, nt)];
        app.ProcTStopEditField.Limits = [1, max(2, nt)];
        app.ProcTStartEditField.Value = 1;
        app.ProcTStopEditField.Value = nt;
        app.StartFrameEditField.Value = 1;
        app.EndFrameEditField.Value = nt;
    end

    app.proc_tEditField.Value = 1;
end
