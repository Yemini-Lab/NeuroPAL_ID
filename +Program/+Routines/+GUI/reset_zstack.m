function reset_zstack(arr, scale, center)
    app = Program.app;
    window = Program.window;
    nz = size(arr, 3);

    if ~exist('scale', 'var')
        scale = app.image_um_scale(3);
    end

    if ~exist('center', 'var')
        center = app.image_prefs.z_center;
    end

    z_slices = 1:nz;

    if nz <= 1
        uialert(window, 'The image is not a volume!', ...
            'Image Not a Volume', 'Icon', 'error');
        return;

    else
        z_labels = arrayfun(@(z) num2str(z, '%.1f'), ...
            (z_slices-1) * scale, 'UniformOutput', false);
    end

    app.ZSlider.Limits = [1, nz];
    app.ZSlider.MajorTicks = z_slices;
    app.ZSlider.MajorTickLabels = z_labels;

    % Setup the z-axis orientation.
    app.ZCenterEditField.Value = round((center - 1) * scale, 1);

    if app.image_prefs.is_Z_LR
        app.ZAxisDropDown.Value = 'L/R';
        app.ZLeftLabel.Text = 'LEFT';
        app.ZRightLabel.Text = 'RIGHT';

    else
        app.ZAxisDropDown.Value = 'D/V';
        app.ZLeftLabel.Text = 'DORSAL';
        app.ZRightLabel.Text = 'VENTRAL';

    end
end

