function load(file)
    app = Program.app;
    app.video_path = file;

    d = uiprogressdlg(app.CELL_ID,'Title','Loading video...','Indeterminate','on');

    if ~isdeployed
        app.script_dir = fullfile(pwd, '/+Wrapper/');
        app.script_ext = '.py';
    else
        if ispc
            app.script_dir = fullfile(pwd, '\lib\bin\windows\');
            app.script_ext = '.exe';
        elseif ismac
            ctfroot_path = ctfroot;
            for i = 1:4
                ctfroot_path = fileparts(ctfroot_path);
            end
            app.script_dir = fullfile(ctfroot_path, 'lib/bin/macos/');
            app.script_ext = '';
        end
    end

    %% GUI Initialization

    % Click Handler
    Program.GUIHandling.init_click_states(app);

    app.AdjustNeuronMarkerAlignmentPanel.Parent = app.DefaultTabGroup.Parent;
    app.AdjustNeuronMarkerAlignmentPanel.Layout = app.DefaultTabGroup.Layout;

    app.AdvancedParameterPanel.Parent = app.BasicParameterPanel.Parent;
    app.AdvancedParameterPanel.Layout = app.BasicParameterPanel.Layout;
    
    app.GridSearchPanel.Parent = app.AdvancedParameterPanel.Parent;
    app.GridSearchPanel.Layout = app.AdvancedParameterPanel.Layout;

    %% Load Video

    % Isolate file format
    [~, ~, format] = fileparts(app.video_path);

    % Select loading function based on file format
    switch format
        case '.h5'
            app.load_h5(app.video_path);
        case '.nwb'
            app.load_nwb(app.video_path);
        case '.nd2'
            app.load_nd2(app.video_path);
        case '.tif'
            app.load_tif(app.video_path);
    end

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

    tx = round(app.video_info.nx/2);
    ty = round(app.video_info.ny/2);
    tz = round(app.video_info.nz/2);

    % Render Frame 1
    app.visual_composer(1, tz, ty, tx);
    app.data_flags.('Video_Volume') = 1;
    
    set(app.TrackingButton, 'Visible', 'off');

    if ~any(ismember(app.VolumeDropDown.Items, 'Video'))
        app.VolumeDropDown.Items{end+1} = 'Video';
    end

    app.VolumeDropDown.Value = 'Video';

    set(app.VideoGridLayout, 'Visible', 'on');
    close(d);
end

