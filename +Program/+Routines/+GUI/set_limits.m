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

    app.proc_tEditField.Value = 1;
end
