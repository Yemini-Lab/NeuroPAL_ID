function load(mode, path)
    app = Program.app;
    window = Program.window;
    volume = Program.volume(path);
    Program.states.set('active_volume', volume);

    d = uiprogressdlg(window, "Title", "NeuroPAL ID", ...
        "Message", "Initializing Processing Tab...", ...
        'Indeterminate', 'off');    
    
    app.flags = struct();
    app.rotation_stack.cache = struct('Colormap', {{}}, 'Video', {{}});
    [filepath, name, ~] = fileparts(path);

    if volume.is_video
        app.video_path = path;
        Program.GUI.enable_video();

        if strcmp(volume.fmt, '.h5')
            app.load_h5(path);
        elseif strcmp(volume.fmt, '.nwb')
            app.load_nwb(path);
        elseif strcmp(volume.fmt, '.nd2')
            app.load_nd2(path);
        end

        Program.states.now("Configuring processing GUI...");
        app.ProcAxGrid.RowHeight{end+1} = 'fit';
        app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
        app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
        app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
        
        app.VolumeDropDown.Value = 'Video';
        app.data_flags.('Video_Volume') = 1;

        set(app.PlaceholderProcTimeline, 'Visible', 'on');
        Program.Routines.GUI.toggle_video();

    else
        Program.GUI.enable_cstack();

        if ~isfile(strrep(volume.path, volume.fmt, 'mat'))
            volume.convert('npal');
            [app.image_data, app.image_info, app.image_prefs, ~, ~, ~, ~, ~] = DataHandling.NeuroPALImage.open(path);
        end

        app.proc_image = matfile(mat_file);

        % Using intmax is faster as it avoids
        % loading the entire variable, but it also
        % distorts the histograms.
        % max_val = double(intmax(class(app.proc_image.data(1, 1, 1, 1))));
        max_val = double(max(app.proc_image.data, [], 'all'));

        app.VolumeDropDown.Value = 'Colormap';
        app.data_flags.('NeuroPAL_Volume') = 1;
        Program.Routines.GUI.toggle_colormap();
    end
    
    d.Value = 2 / 5;
    d.Message = sprintf('Calculating threshold...');
    Program.GUIHandling.set_thresholds(app, volume.datatype_max);
    
    d.Value = 3 / 5;
    d.Message = sprintf('Mapping channels...');
    Program.GUI.channel_editor.populate(volume);
    %Program.Routines.Processing.set_channels_from_file(channel.names, channel.idx);
    
    d.Value = 4 / 5;
    d.Message = sprintf('Configuring GUI...');
    daspect(app.proc_xyAxes, [1 1 1]);
    
    if volume.nc < 4
        app.ProcHistogramGrid.RowHeight = {'1x'};
    end
    
    Program.GUI.set_processing_bounds('volume', volume);
    app.ProcXYFactorEditField.Enable = 'on';
    app.ProcZSlicesEditField.Enable = 'on';
    app.proc_xEditField.Enable = 'off';
    app.proc_yEditField.Enable = 'off';
    
    Program.GUI.set_gammas(volume);
    
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

