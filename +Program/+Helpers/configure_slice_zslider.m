function configure_slice_zslider(slider, n_slices, current_slice, show_labels)
    % Configure a z slider with integer slice ticks.

    if nargin < 4 || isempty(show_labels)
        show_labels = true;
    end

    n_slices = max(1, round(double(n_slices)));
    current_slice = min(max(round(double(current_slice)), 1), n_slices);

    if n_slices <= 8
        major_ticks = 1:n_slices;
    else
        max_labels = 8;
        step = max(1, ceil((n_slices - 1) / (max_labels - 1)));
        major_ticks = unique([1:step:n_slices, current_slice, n_slices]);
    end

    minor_ticks = setdiff(1:n_slices, major_ticks);

    slider.Limits = [1, n_slices];
    slider.MajorTicks = major_ticks;
    slider.MinorTicks = minor_ticks;
    slider.Value = current_slice;

    if isprop(slider, 'MajorTickLabels')
        if show_labels
            slider.MajorTickLabels = arrayfun(@(z) sprintf('%d', z), major_ticks, ...
                'UniformOutput', false);
        else
            slider.MajorTickLabels = repmat({''}, 1, numel(major_ticks));
        end
    end
end
