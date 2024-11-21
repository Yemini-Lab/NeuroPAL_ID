function toggle_colormap()
    app = Program.GUIHandling.app;
    Program.Helpers.set_grid_height(app.ProcDownsamplingGrid, 3, 0);
    Program.Helpers.set_grid_height(app.ProcDownsamplingGrid, 4, 0);
    Program.Helpers.set_grid_height(app.ProcSideGrid, 4, 114);
    Program.Helpers.set_grid_height(app.ProcSideGrid, 5, 212);

    app.ProcAxGrid.RowHeight(end) = [];
    app.PlaceholderProcTimeline.Parent = app.CELL_ID;

    app.PlaceholderProcTimeline.Visible = 'off';

    app.StartFrameEditField.Enable = 'off';
    app.StartFrameEditField.Visible = 'off';
    
    app.EndFrameEditField.Enable = 'off';
    app.EndFrameEditField.Visible = 'off';

    app.TrimButton.Enable = 'off';
end