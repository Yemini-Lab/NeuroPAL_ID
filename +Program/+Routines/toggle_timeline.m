function toggle_timeline(mode)
    app = Program.GUIHandling.app;

    switch mode
        case 'colormap'
            app.PlaceholderProcTimeline.Parent = app.CELL_ID;
            app.PlaceholderProcTimeline.Visible = ~app.PlaceholderProcTimeline.Visible;
            app.ProcAxGrid.RowHeight(end) = [];

        case 'video'
            app.ProcAxGrid.RowHeight{end+1} = 'fit';
            app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
            app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
            app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
            app.PlaceholderProcTimeline.Visible = ~app.PlaceholderProcTimeline.Visible;

    end
end