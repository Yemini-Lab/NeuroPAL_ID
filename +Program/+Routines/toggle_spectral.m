function toggle_spectral(mode)
    app = Program.GUIHandling.app;

    switch mode
        case 'colormap'
            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(5) = 212;
            app.ProcSideGrid.RowHeight = side_grid;

        case 'video'
            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(5) = 0;
            app.ProcSideGrid.RowHeight = side_grid;

    end
end