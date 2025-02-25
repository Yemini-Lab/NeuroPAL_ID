function set_limits(nx, ny, nz, nt)
    app = Program.app;

    app.proc_xSlider.Limits = [1 nx];
    app.proc_ySlider.Limits = [1 ny];

    app.proc_zSlider.Limits = [1 nz];
    app.proc_hor_zSlider.Limits = [1 nz];
    app.proc_vert_zSlider.Limits = [1 nz];

    middle_x = round(nx/2);
    middle_y = round(ny/2);
    middle_z = round(nz/2);

    app.proc_xSlider.Value = middle_x;
    app.proc_ySlider.Value = middle_y;

    app.proc_zSlider.Value = middle_z;
    app.proc_hor_zSlider.Value = middle_z;
    app.proc_vert_zSlider.Value = middle_z;
    app.proc_zEditField.Value = middle_z;
    app.ProcZSlicesEditField.Value = middle_z;

    app.proc_tEditField.Value = 1;
end

