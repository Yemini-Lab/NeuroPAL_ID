function toggle_video()
    app = Program.GUIHandling.app;
    Program.Helpers.set_grid_height(app.ProcDownsamplingGrid, 3, 20);
    Program.Helpers.set_grid_height(app.ProcDownsamplingGrid, 4, 20);
    Program.Helpers.set_grid_height(app.ProcSideGrid, 4, 0);

    app.ProcAxGrid.RowHeight{end+1} = 'fit';
    app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
    app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
    app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
    
    app.PlaceholderProcTimeline.Visible = 'on';

    app.StartFrameEditField.Enable = 'on';
    app.StartFrameEditField.Visible = 'on';

    app.EndFrameEditField.Enable = 'on';
    app.EndFrameEditField.Visible = 'on';

    app.TrimButton.Enable = 'on';
end

