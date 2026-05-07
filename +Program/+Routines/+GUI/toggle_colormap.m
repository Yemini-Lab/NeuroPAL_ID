function toggle_colormap()
    app = Program.GUIHandling.app;
    Program.Helpers.set_grid_height(app.ProcDownsamplingGrid, 3, 0);
    Program.Helpers.set_grid_height(app.ProcDownsamplingGrid, 4, 0);
    Program.GUIHandling.configure_processing_sidebar_layout(app);

    if isequal(app.PlaceholderProcTimeline.Parent, app.ProcAxGrid)
        timeline_row = app.PlaceholderProcTimeline.Layout.Row;
        if timeline_row >= 1 && timeline_row <= numel(app.ProcAxGrid.RowHeight)
            app.ProcAxGrid.RowHeight(timeline_row) = [];
        end
    end

    app.PlaceholderProcTimeline.Parent = app.CELL_ID;

    app.PlaceholderProcTimeline.Visible = 'off';

    app.StartFrameEditField.Enable = 'off';
    app.StartFrameEditField.Visible = 'off';
    
    app.EndFrameEditField.Enable = 'off';
    app.EndFrameEditField.Visible = 'off';

    app.TrimButton.Enable = 'off';
end
