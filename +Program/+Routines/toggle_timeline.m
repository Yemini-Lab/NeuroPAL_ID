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

            if app.ProcTStartEditField.Value == 0 || app.ProcTStopEditField.Value == 0
                app.ProcTStartEditField.Value = app.proc_tSlider.Limits(1);
                app.ProcTStopEditField.Value = app.proc_tSlider.Limits(2);
            end

    end
end