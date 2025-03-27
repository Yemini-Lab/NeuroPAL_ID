function thresholds(new_maximum)
    app = Program.app;
    new_maximum = cast(new_maximum, 'double');
    new_limits = [1 max(2, new_maximum)];

    app.ProcNoiseThresholdKnob.Limits = new_limits;
    app.ProcNoiseThresholdField.Limits = new_limits;
    app.ProcNoiseThresholdKnob.MajorTicks = [1:round(new_maximum/5):new_maximum, new_maximum];
    app.ProcNoiseThresholdKnob.MajorTickLabels = string(app.ProcNoiseThresholdKnob.MajorTicks);
    Program.GUIHandling.shorten_knob_labels(app);

    Program.GUI.Panels.histograms.set_limits(new_limits);
end

