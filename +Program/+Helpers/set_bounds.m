function set_bounds()
    app = Program.app;
    pfx = Program.Handlers.histograms.prefixes;

    switch lower(app.VolumeDropDown.Value)
        case 'colormap'
            frame = Program.Helpers.read_processing_colormap(app, 'z', 1, 'mip', false);
        case 'video'
            frame = [];
    end

    setappdata(app.CELL_ID, 'proc_threshold_raw_max', 255);
    for p=1:length(pfx)
        handle = sprintf('%s_hist_slider', pfx{p});
        app.(handle).Limits(2) = 255;
    end
end
