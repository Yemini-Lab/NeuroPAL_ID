function load(mode, path)
    [app, window] = Program.ctx;
    Program.dlg.add_task('Initializing processing tab');

    Program.dlg.step('Building volume');
    Program.dlg.set_value(1/5);
    volume = Program.volume(path);

    app.state.set('interface', 'Image Processing');
    app.state.set('active_volume', volume);
    
    app.flags = struct();
    app.rotation_stack.cache = struct('Colormap', {{}}, 'Video', {{}});

    if volume.is_video
        Program.GUI.enable_video();
        app.ProcAxGrid.RowHeight{end+1} = 'fit';
        app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
        app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
        app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
        app.VolumeDropDown.Value = 'Video';
        app.data_flags.('Video_Volume') = 1;
        set(app.PlaceholderProcTimeline, 'Visible', 'on');
        Program.GUI.Toggles.video;
    else
        Program.GUI.enable_cstack();
        app.VolumeDropDown.Value = 'Colormap';
        app.data_flags.('NeuroPAL_Volume') = 1;
        Program.GUI.Toggles.colorstack;
    end
    
    Program.dlg.step('Setting threshold');
    Program.dlg.set_value(2/5);
    Program.GUI.Settings.thresholds(volume.dtype_max);
    Program.GUI.histogram_editor.update(volume);
    
    Program.dlg.step('Mapping channels');
    Program.dlg.set_value(3/5);
    app.channel_editor.populate(volume);
    volume.update_channels();
    %Program.Routines.Processing.set_channels_from_file(channel.names, channel.idx);
    
    Program.dlg.step('Configuring view');
    Program.dlg.set_value(4/5);
    daspect(app.proc_xyAxes, [1 1 1]);
    
    if volume.nc < 4
        app.ProcHistogramGrid.RowHeight = {'1x'};
    end
    
    Program.GUI.Settings.bounds('volume', volume, 'is_initializing', 1);
    app.ProcXYFactorEditField.Enable = 'on';
    app.ProcZSlicesEditField.Enable = 'on';
    app.proc_xEditField.Enable = 'off';
    app.proc_yEditField.Enable = 'off';
    
    Program.GUI.set_gammas(volume);
    
    Program.dlg.step('Rendering volume');
    Program.dlg.set_value(5/5);
    Program.render();
    
    app.ImageProcessingTab.Tag = 'rendered';
    set(app.ProcessingButton, 'Visible', 'off');
    set(app.ProcessingGridLayout, 'Visible', 'on');
    
    app.TabGroup.SelectedTab = app.ImageProcessingTab;
    Program.dlg.resolve();
    
    check = uiconfirm(window, "We recommend starting by cropping your image " + ...
        "to ensure that there is no superfluous space taking up memory. " + ...
        "Do you want to do so now?", "NeuroPAL_ID", ...
        "Options", ["Yes", "No, skip cropping."]);

    switch check
        case "Yes"
            Program.Routines.Processing.volume_crop(volume);
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
        case "No, skip cropping."
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
    end
    
    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
end

