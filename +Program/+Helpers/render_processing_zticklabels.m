function render_processing_zticklabels(app)
    % Render processing z-slider labels above the slider to avoid overlap.

    delete(findall(app.ProcAxPanel, 'Tag', 'proc_z_tick_label'));

    if ~isvalid(app.proc_zSlider)
        return;
    end

    drawnow limitrate nocallbacks;

    try
        slider_pos = getpixelposition(app.proc_zSlider, true);
        panel_pos = getpixelposition(app.ProcAxPanel, true);
    catch
        return;
    end

    if numel(slider_pos) < 4 || numel(panel_pos) < 4 || slider_pos(3) <= 20 || slider_pos(4) <= 10
        return;
    end

    ticks = double(app.proc_zSlider.MajorTicks);
    if isempty(ticks)
        return;
    end

    n_slices = max(1, round(double(app.proc_zSlider.Limits(2))));
    rel_x = slider_pos(1) - panel_pos(1);
    rel_y = slider_pos(2) - panel_pos(2);
    label_y = max(1, rel_y + slider_pos(4) - 16);
    label_w = 28;
    label_h = 14;
    usable_width = max(1, slider_pos(3) - 16);
    left_pad = rel_x + 8;

    for idx = 1:numel(ticks)
        tick = min(max(round(ticks(idx)), 1), n_slices);
        if n_slices == 1
            frac = 0.5;
        else
            frac = (tick - 1) / (n_slices - 1);
        end
        x_center = left_pad + frac * usable_width;
        uilabel(app.ProcAxPanel, ...
            'Text', sprintf('%d', tick), ...
            'Tag', 'proc_z_tick_label', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10, ...
            'BackgroundColor', app.ProcAxPanel.BackgroundColor, ...
            'Position', [x_center - (label_w / 2), label_y, label_w, label_h]);
    end
end
