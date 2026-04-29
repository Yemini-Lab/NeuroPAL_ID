function configure_processing_zsliders(app, n_slices, current_slice)
    % Configure processing-tab z sliders with integer slice ticks.

    if nargin < 2 || isempty(n_slices)
        n_slices = max(1, round(double(app.proc_zSlider.Limits(2))));
    end
    if nargin < 3 || isempty(current_slice)
        current_slice = min(max(round(double(app.proc_zSlider.Value)), 1), n_slices);
    end

    Program.Helpers.configure_slice_zslider(app.proc_zSlider, n_slices, current_slice, false);
    Program.Helpers.configure_slice_zslider(app.proc_hor_zSlider, n_slices, current_slice, false);
    Program.Helpers.configure_slice_zslider(app.proc_vert_zSlider, n_slices, current_slice, false);
    app.proc_zEditField.Value = current_slice;
    Program.Helpers.render_processing_zticklabels(app);
end
