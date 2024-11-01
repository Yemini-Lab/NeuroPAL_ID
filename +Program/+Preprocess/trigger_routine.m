function trigger_routine(path)
    app = Program.GUIHandling.app();
    d = uiprogressdlg(app.CELL_ID,"Title","NeuroPAL ID","Message","Initializing Processing Tab...",'Indeterminate','off');    
    app.flags = struct();
    app.rotation_stack.cache = struct('Colormap', {{}}, 'Video', {{}});
    
    [filepath, ~, ext] = fileparts(path);

    if app.TabGroup.SelectedTab == app.VideoTrackingTab
        Program.GUIHandling.enable_volume('Video');
        app.video_path = path;

        if strcmp(ext, '.h5')
            app.load_h5(path);
        elseif strcmp(ext, '.nwb')
            app.load_nwb(path);
        elseif strcmp(ext, '.nd2')
            app.load_nd2(path);
        end
        
        nx = app.video_info.nx;
        ny = app.video_info.ny;
        nz = app.video_info.nz;
        nc = app.video_info.nc;

        chan_order = [];
        gammas = [];

        test_frame = app.retrieve_frame(3);
        max_val = double(intmax(class(test_frame)));

        d.Message = "Configuring processing GUI...";
        app.ProcTStartEditField.Value = 1;
        app.ProcTStopEditField.Value = app.video_info.nt;
        app.proc_tSlider.Limits = [1 app.video_info.nt];
        app.proc_tSlider.Value = 1;

        app.ProcAxGrid.RowHeight{end+1} = 'fit';
        app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
        app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
        app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
        
        app.VolumeDropDown.Value = 'Video';
        app.data_flags.('Video_Volume') = 1;

        set(app.PlaceholderProcTimeline, 'Visible', 'on');

    else
        Program.GUIHandling.enable_volume('Colormap');

        if ~strcmp(ext, '.mat')
            DataHandling.Lazy.file.is_lazy(1);
            DataHandling.Lazy.file.read(path);
            [filepath, ~] = DataHandling.Lazy.file.create_cache();
        elseif isfile(strrep(path, ext, '.mat'))
            filepath = strrep(path, ext, '.mat');
        end

        app.proc_image = matfile(filepath);
        prefs = app.proc_image.prefs;

        if ~isempty(prefs.RGBW)
            chan_order = string(prefs.RGBW);
        else
            chan_order = ['1',  '2', '3', '4', '5', '6'];
        end
        
        if size(prefs.gamma) < 3 
            gammas = [1 1 1 1 1 1];
        else
            gammas = prefs.gamma;
        end
    
        vol_size = size(app.proc_image, 'data');
    
        nx = vol_size(2);
        ny = vol_size(1);
        nz = vol_size(3);
        nc = vol_size(4);
    
        % Using intmax is faster as it avoids
        % loading the entire variable, but it also
        % distorts the histograms.
        % max_val = double(intmax(class(app.proc_image.data(1, 1, 1, 1))));
        max_val = double(max(app.proc_image.data, [], 'all'));
    
        app.VolumeDropDown.Value = 'Colormap';
        app.data_flags.('NeuroPAL_Volume') = 1;
    end
    
    d.Value = 1 / 5;
    d.Message = sprintf('Creating backups...');
    app.create_backup();
    
    d.Value = 2 / 5;
    d.Message = sprintf('Calculating threshold...');
    Program.GUIHandling.set_thresholds(app, max_val);
    
    d.Value = 3 / 5;
    d.Message = sprintf('Mapping channels...');
    if isempty(chan_order)
        app.ProcRDropDown.Value = '1';
        app.ProcGDropDown.Value = '2';
        app.ProcBDropDown.Value = '3';
        app.ProcWDropDown.Value = '4';
        app.ProcDICDropDown.Value = '5';
        app.ProcGFPDropDown.Value = '6';
    else
        for n=1:nc
            switch n
                case 1
                    try
                        app.ProcRDropDown.Value = chan_order(1);
                    catch 
                        app.ProcRDropDown.Value = '-';
                    end
                case 2
                    try
                        app.ProcGDropDown.Value = chan_order(2);
                    catch 
                        app.ProcGDropDown.Value = '-';
                    end
                case 3
                    try
                        app.ProcBDropDown.Value = chan_order(3);
                    catch 
                        app.ProcBDropDown.Value = '-';
                    end
                case 4
                    try
                        app.ProcWDropDown.Value = chan_order(4);
                    catch 
                        app.ProcWDropDown.Value = '-';
                    end
                case 5
                    try
                        app.ProcDICDropDown.Value = chan_order(5);
                    catch 
                        app.ProcDICDropDown.Value = '-';
                    end
                case 6
                    try
                        app.ProcGFPDropDown.Value = chan_order(6);
                    catch 
                        app.ProcGFPDropDown.Value = '-';
                    end
            end
        end
    end
    
    app.nameMap = containers.Map( ...
        {app.ProcRDropDown.Value, app.ProcGDropDown.Value, app.ProcBDropDown.Value, ...
         app.ProcWDropDown.Value, app.ProcDICDropDown.Value, app.ProcGFPDropDown.Value}, ...
        {'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'} ...
    );
    
    app.shortMap = containers.Map( ...
        {app.ProcRDropDown.Value, app.ProcGDropDown.Value, app.ProcBDropDown.Value, ...
         app.ProcWDropDown.Value, app.ProcDICDropDown.Value, app.ProcGFPDropDown.Value}, ...
        {'r', 'g', 'b', 'k', 'k', 'y'} ...
    );
    
    d.Value = 4 / 5;
    d.Message = sprintf('Configuring GUI...');
    daspect(app.proc_xyAxes, [1 1 1]);
    
    if nc < 4
        app.ProcHistogramGrid.RowHeight = {'1x'};
    end
    
    app.proc_xSlider.Limits = [1 nx];
    app.proc_ySlider.Limits = [1 ny];
    app.proc_zSlider.Limits = [1 nz];
    app.proc_hor_zSlider.Limits = app.proc_zSlider.Limits;
    app.proc_vert_zSlider.Limits = app.proc_zSlider.Limits;
    
    app.proc_xSlider.Value = round(app.proc_xSlider.Limits(2)/2);
    app.proc_ySlider.Value = round(app.proc_ySlider.Limits(2)/2);
    app.proc_zSlider.Value = round(app.proc_zSlider.Limits(2)/2);
    app.proc_hor_zSlider.Value = app.proc_zSlider.Value;
    app.proc_vert_zSlider.Value = app.proc_zSlider.Value;
    app.proc_zEditField.Value = round(app.proc_zSlider.Value);
    app.proc_tEditField.Value = round(app.proc_tSlider.Value);
    
    app.ProcZSlicesEditField.Value = app.proc_zSlider.Value;
    app.ProcXYFactorEditField.Enable = 'on';
    app.ProcZSlicesEditField.Enable = 'on';
    
    set(app.proc_xEditField, 'Enable', 'off');
    set(app.proc_yEditField, 'Enable', 'off');
    
    if isempty(gammas)
        app.tl_GammaEditField.Value = 1;
        app.tm_GammaEditField.Value = 1;
        app.tr_GammaEditField.Value = 1;
        app.bl_GammaEditField.Value = 1;
        app.bm_GammaEditField.Value = 1;
        app.br_GammaEditField.Value = 1;
    else
        for n=1:size(gammas, 2)
            switch n
                case 1
                    app.tl_GammaEditField.Value = gammas(1);
                case 2
                    app.tm_GammaEditField.Value = gammas(2);
                case 3
                    app.tr_GammaEditField.Value = gammas(3);
                case 4
                    app.bl_GammaEditField.Value = gammas(4);
                case 5
                    app.bm_GammaEditField.Value = gammas(5);
                case 6
                    app.br_GammaEditField.Value = gammas(6);
            end
        end
    end
    
    d.Value = 5 / 5;
    d.Message = sprintf('Drawing image...');
    Methods.ChunkyMethods.load_proc_image(app);
    
    app.ImageProcessingTab.Tag = 'rendered';
    set(app.ProcessingButton, 'Visible', 'off');
    set(app.ProcessingGridLayout, 'Visible', 'on');
    
    app.TabGroup.SelectedTab = app.ImageProcessingTab;
    close(d)
    
    check = uiconfirm(app.CELL_ID, "We recommend starting by cropping your image to ensure that there is no superfluous space taking up memory. Do you want to do so now?", "NeuroPAL_ID", "Options", ["Yes", "No, skip cropping."]);
    switch check
        case "Yes"
            app.ProcCropImageButtonPushed([]);
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
        case "No, skip cropping."
            Methods.ChunkyMethods.load_proc_image(app);
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
    end
    
    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
end