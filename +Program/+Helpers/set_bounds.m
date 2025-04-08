function set_bounds()
    app = Program.app;
    pfx = Program.Handlers.histograms.prefixes;

    switch lower(app.VolumeDropDown.Value)
        case 'colormap'
            frame = app.proc_image.data(:, :, 1, :);
        case 'video'
            frame = app.retrieve_frame(1);
    end

    frame_class = class(frame);
    if ismember(frame_class, {'double', 'single'})
        new_max = max(frame, [], 'all');
    else
        new_max = intmax(frame_class);
    end

    app.ProcNoiseThresholdKnob.Limits(2) = new_max;
    for p=1:length(pfx)
        handle = sprintf('%s_hist_slider', pfx{p});
        app.(handle).Limits(2) = new_max;
    end
end

