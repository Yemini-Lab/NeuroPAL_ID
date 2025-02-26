function thresholds(new_maximum)
    app = Program.app;
    new_maximum = cast(new_maximum, 'double');
    new_limits = [1 max(2, new_maximum)];

    app.ProcNoiseThresholdKnob.Limits = new_limits;
    app.ProcNoiseThresholdField.Limits = new_limits;
    app.ProcNoiseThresholdKnob.MajorTicks = [1:round(new_maximum/5):new_maximum, new_maximum];
    app.ProcNoiseThresholdKnob.MajorTickLabels = string(app.ProcNoiseThresholdKnob.MajorTicks);
    Program.GUIHandling.shorten_knob_labels(app);

    for pos=1:length(Program.GUIHandling.pos_prefixes)
        app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos})).Limits = new_limits;
        app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos})).Value = new_limits;
        app.(sprintf('%s_hist_ax', Program.GUIHandling.pos_prefixes{pos})).XLim = new_limits;
    end
end

