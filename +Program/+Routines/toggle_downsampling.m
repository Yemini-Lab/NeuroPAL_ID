function toggle_downsampling(mode)
    app = Program.GUIHandling.app;

    switch mode
        case 'colormap'
            vol_sz = size(app.proc_image, 'data');
            app.ProcZSlicesEditField.Value = vol_sz(3);

            app.TrimButton.Enable = 'off';
            app.ProcTStartEditField.Enable = 'off';
            app.ProcTStopEditField.Enable = 'off';

            app.StartFrameEditField.Visible = 'off';
            app.EndFrameEditField.Visible = 'off';
            app.ProcDownsamplingGrid.RowHeight = {20, 20, 0, 0, 0, 'fit'};

            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(4) = {'fit'};
            app.ProcSideGrid.RowHeight = side_grid;

        case 'video'
            app.ProcZSlicesEditField.Value = app.video_info.nz;

            app.TrimButton.Enable = 'on';
            app.ProcTStartEditField.Enable = 'on';
            app.ProcTStopEditField.Enable = 'on';

            app.StartFrameEditField.Visible = 'on';
            app.EndFrameEditField.Visible = 'on';

            app.ProcDownsamplingGrid.RowHeight = {20, 20, 20, 20, 0, 'fit'};

            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(4) = {154};
            app.ProcSideGrid.RowHeight = side_grid;

    end
end

