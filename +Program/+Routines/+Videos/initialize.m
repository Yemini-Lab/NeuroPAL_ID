function initialize()
    app = Program.app;
    
    Program.GUIHandling.init_click_states(app);

    app.AdjustNeuronMarkerAlignmentPanel.Parent = app.DefaultTabGroup.Parent;
    app.AdjustNeuronMarkerAlignmentPanel.Layout = app.DefaultTabGroup.Layout;

    app.AdvancedParameterPanel.Parent = app.BasicParameterPanel.Parent;
    app.AdvancedParameterPanel.Layout = app.BasicParameterPanel.Layout;
    
    app.GridSearchPanel.Parent = app.AdvancedParameterPanel.Parent;
    app.GridSearchPanel.Layout = app.AdvancedParameterPanel.Layout;

    Program.Handlers.wrapper.set_script_directory();

    app.xyAxes.XLim = [1, app.video_info.nx];
    app.xyAxes.YLim = [1, app.video_info.ny];
    %xy_aspectRatio = app.video_info.nx / app.video_info.ny;
    %app.xyAxes.DataAspectRatio = [1, 1/xy_aspectRatio, 1];

    % Define slider limits and values based on video
    app.tSlider.Limits = [1, app.video_info.nt];
    app.ActivityAxes.XTick = 0:app.video_info.nt;
    app.ActivityAxes.XTickLabel = 0:app.video_info.nt;
    app.tSlider.MinorTicks = [];
    app.tSlider.Value = 1;

    app.vert_zSlider.Limits = [1, app.video_info.nz];
    app.vert_zSlider.Value = round(app.video_info.nz/2);

    app.hor_zSlider.Limits = [1, app.video_info.nz];
    app.hor_zSlider.Value = round(app.video_info.nz/2);

    app.xSlider.Limits = [1, app.video_info.nx];
    app.xSlider.Value = round(app.video_info.nx/2);

    app.ySlider.Limits = [1, app.video_info.ny];
    app.ySlider.Value = round(app.video_info.ny/2);

end

