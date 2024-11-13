function toggle_downsampling(mode)
    app = Program.GUIHandling.app;

    switch mode
        case 'colormap'
            app.StartFrameEditField.Visible = 'off';
            app.EndFrameEditField.Visible = 'off';
            app.ProcDownsamplingGrid.RowHeight = {20, 20, 0, 0, 0, 'fit'};

            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(4) = 'fit';
            app.ProcSideGrid.RowHeight = side_grid;

        case 'video'
            app.StartFrameEditField.Visible = 'on';
            app.EndFrameEditField.Visible = 'on';
            app.ProcDownsamplingGrid.RowHeight = {20, 20, 20, 20, 0, 'fit'};

            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(4) = 154;
            app.ProcSideGrid.RowHeight = side_grid;

    end
end

