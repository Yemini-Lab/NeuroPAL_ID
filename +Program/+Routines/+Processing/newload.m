function newload(mode, path)
    app = Program.app;
    window = Program.window;

    d = uiprogressdlg(window, "Title", "NeuroPAL ID", ...
        "Message", "Initializing Processing Tab...", ...
        'Indeterminate', 'off');    
    
    app.flags = struct();
    app.rotation_stack.cache = struct('Colormap', {{}}, 'Video', {{}});

    d.Value = 1 / 5;
    d.Message = sprintf('Creating volume object...');
    pv = Program.Routines.load_volume(path);
    pv.is_video = strcmp(mode, 'video');
    if ~pv.is_video
        Program.GUI.enable_cstack();
        app.VolumeDropDown.Value = 'Colormap';
        app.data_flags.('NeuroPAL_Volume') = 1;
        Program.Routines.GUI.toggle_colormap();
    else
        Program.GUI.enable_video();
        app.VolumeDropDown.Value = 'Video';
        app.data_flags.('Video_Volume') = 1;

        app.ProcAxGrid.RowHeight{end+1} = 'fit';
        app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
        app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
        app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
        set(app.PlaceholderProcTimeline, 'Visible', 'on');

        Program.Routines.GUI.toggle_video();
    end
    
    d.Value = 2 / 5;
    d.Message = sprintf('Calculating threshold...');
    Program.GUIHandling.set_thresholds(app, pv.datatype_max);
    
    d.Value = 3 / 5;
    d.Message = sprintf('Mapping channels...');
    Program.Routines.Processing.set_channels_from_file(pv.channels);
    
    d.Value = 4 / 5;
    d.Message = sprintf('Configuring GUI...');
    daspect(app.proc_xyAxes, [1 1 1]);
    
    if nc < 4
        app.ProcHistogramGrid.RowHeight = {'1x'};
    end
    
    Program.GUI.set_processing_bounds( ...
        'nx', pv.nx, 'ny', pv.ny, 'nz', pv.nz, 'nt', pv.nt);
    app.ProcXYFactorEditField.Enable = 'on';
    app.ProcZSlicesEditField.Enable = 'on';
    app.proc_xEditField.Enable = 'off';
    app.proc_yEditField.Enable = 'off';
    
    Program.GUI.set_gammas(channel.gammas);
    
    d.Value = 5 / 5;
    d.Message = sprintf('Drawing image...');
    Program.Routines.Processing.render();
    
    app.ImageProcessingTab.Tag = 'rendered';
    set(app.ProcessingButton, 'Visible', 'off');
    set(app.ProcessingGridLayout, 'Visible', 'on');
    
    app.TabGroup.SelectedTab = app.ImageProcessingTab;
    close(d)
    
    check = uiconfirm(window, "We recommend starting by cropping your image " + ...
        "to ensure that there is no superfluous space taking up memory. " + ...
        "Do you want to do so now?", "NeuroPAL_ID", ...
        "Options", ["Yes", "No, skip cropping."]);

    switch check
        case "Yes"
            app.ProcCropImageButtonPushed([]);
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
        case "No, skip cropping."
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
    end
    
    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
end