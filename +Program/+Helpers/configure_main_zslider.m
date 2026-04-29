function configure_main_zslider(app, n_slices, current_slice)
    % Configure the main z slider with integer-only slice labels.

    if nargin < 2 || isempty(n_slices)
        n_slices = size(app.image_data, 3);
    end
    if nargin < 3 || isempty(current_slice)
        current_slice = round((n_slices + 1) / 2);
    end

    Program.Helpers.configure_slice_zslider(app.ZSlider, n_slices, current_slice, true);
end
