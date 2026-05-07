function get_slice(slider, view, ax)
    %% Draw the neurons in this z-slice.

    app = Program.app;

    % Sanity check the Z slice value.
    z = Program.Helpers.gui_z_to_data_index(app.ZSlider.Value, size(app.image_data, 3), false);
    app.logEvent('Main',sprintf('Drawing slice %s...', string(z)), 0);
    app.ZSlider.Value = z;

    % Is there an image?
    if isempty(app.image_data)
        return;
    end

    % Flip the Z-axis.
    z_num = z;
    z = Program.Helpers.gui_z_to_data_index(z_num, size(app.image_data, 3), app.image_prefs.is_Z_flip);
    Program.Helpers.debug_event('IDSlice', ...
        'z_gui=%d z_data=%d is_Z_flip=%d z_center=%d', ...
        z_num, z, app.image_prefs.is_Z_flip, app.image_prefs.z_center);

    % Where are we in Z?
    background_color = [0.94,0.94,0.94];
    LD_color = [0,1,1]; % left or dorsal color
    RV_color = [1,0,1]; % right or ventral color
    z_center_thresh = 1; % center +/- 1 slice
    z_center = app.image_prefs.z_center;
    if z_num >= z_center - z_center_thresh && z_num <= z_center + z_center_thresh
        app.XYPanel.BackgroundColor = background_color;
        app.ZLeftLabel.BackgroundColor = background_color;
        app.ZRightLabel.BackgroundColor = background_color;
    elseif z_num < z_center - z_center_thresh
        app.XYPanel.BackgroundColor = LD_color;
        app.ZLeftLabel.BackgroundColor = LD_color;
        app.ZRightLabel.BackgroundColor = background_color;
    else % if z > z_center + z_center_thresh
        app.XYPanel.BackgroundColor = RV_color;
        app.ZLeftLabel.BackgroundColor = background_color;
        app.ZRightLabel.BackgroundColor = RV_color;
    end

    % Clear the contents of the axis to draw the new Z-slice.
    cla(ax);
    % Create the slice at z for displaying in the axis.
    [xy, ~, z] = Program.Helpers.get_current_display_slice(app, 'main', view);
    Program.Helpers.debug_array_summary('IDSlice', 'xy_slice', xy);
    % Display the current slice in the XY axis.
    gui_image = image(xy, 'Parent', ax); hold(ax, 'on');
    local_draw_cellpose_mask_overlay(app, ax, z);

    if strcmp(app.TabGroup.SelectedTab.Title, 'Image Processing') & strcmp(app.VolumeDropDown.Value, 'Colormap')
        image(xy, 'Parent', app.proc_xyAxes);
    end

    % Add the AddNeuron function as mouse click listener.
    gui_image.ButtonDownFcn = {@app.ImageClicked};

    % Redraw the neurons in this z slice.
    if ~isempty(app.image_neurons) && ~isempty(app.image_neurons.neurons)

        % Which neurons belong in this z-slice?
        neuron_locations = app.image_neurons.get_positions();
        neuron_marker_colors = app.image_neurons.get_marker_colors();
        neuron_marker_sizes = app.image_neurons.get_marker_sizes();
        neuron_line_size = Program.GUIPreferences.instance().neuron_dot.line;
        [marker_size_scale, marker_line_scale] = ...
            Program.GUIPreferences.neuron_marker_display_scales();

        % Since z (which is found by MP) can be a continuous value
        % to find all the neurons in the current slice we find the
        % ones that lie in the interval [z-z_dot_view, z+z_dot_view]. Finally we
        % change the x and y dimension to fix the inconsistent
        % behavior of Matlab figures for scatter and image function.
        % Red centroid visibility should be independent of mask overlay toggles.
        z_dot_view = 1.5;
        current_z_indices = neuron_locations(:,3)>z-z_dot_view & neuron_locations(:,3)<z+z_dot_view;
        positions = neuron_locations(current_z_indices, 1:2);

        % Draw the neuron markers.
        neuron_marker_plot = scatter(ax, positions(:, 2), positions(:, 1), ...
            neuron_marker_sizes(current_z_indices) * marker_size_scale, ...
            neuron_marker_colors(current_z_indices, :), ...
            'filled', 'MarkerEdgeColor', app.neuron_marker.color.edge, ...
            'LineWidth', neuron_line_size * marker_line_scale);

        % Are we showing the neuron annotations?
        if app.show_labels

            % Get the labels.
            labels = app.image_neurons.get_annotations();
            labels = labels(current_z_indices);

            % Get the ON/OFF annotations.
            is_on = app.image_neurons.get_is_annotations_on();
            is_on = is_on(current_z_indices);

            % Get the confidences.
            confidences = app.image_neurons.get_annotation_confidences();
            confidences = confidences(current_z_indices);

            % Get the emphasized neurons.
            is_emphasized = app.image_neurons.get_is_emphasized();
            is_emphasized = is_emphasized(current_z_indices);

            % Remove empty labels.
            is_label = ~cellfun('isempty', labels);
            labels = labels(is_label);
            is_on = is_on(is_label);
            confidences = confidences(is_label);
            is_emphasized = is_emphasized(is_label);

            % Add ON/OFF & confidence to the labels.
            for i = 1:length(confidences)

                % Is the neuron ON/OFF.
                switch is_on(i)
                    case false
                        labels{i} = [labels{i} '-OFF'];
                    case true
                        labels{i} = [labels{i} '-ON'];
                end

                % Is the user uncertain about the ID?
                if confidences(i) <= 0.5
                    labels{i} = [labels{i} '?'];
                end

                % Is the neuron emphasized?
                if is_emphasized(i)
                    labels{i} = [labels{i} '!'];
                end
            end

            % Draw the labels.
            DrawImageLabels(app, positions(is_label,:), labels);
        end

        % Setup the mouse-click callback.
        neuron_marker_plot.ButtonDownFcn = {@app.NeuronClicked};
    end

    % Draw the color atlas.
    if app.ColorAtlasCheckBox.Value

        % Do we have the atlas info?
        if isempty(app.image_neurons.get_aligned_xyzRGBs())

            % Uncheck the atlas.
            app.ColorAtlasCheckBox.Value = false;

            % Warn the user.
            uialert(app.CELL_ID, ...
                'Please press "Auto-ID All" to create the neuron ID atlas!', ...
                'No Atlas', 'Icon', 'warning');

            % Draw the neuron ID atlas.
        else
            Methods.AutoId.instance().visualize(...
                app.image_neurons, app.worm, 'ax', app.XY, 'z', z);
        end
    end
end

function local_draw_cellpose_mask_overlay(app, ax, z_data)
if ~local_cellpose_overlay_enabled(app)
    return
end

mask_volume = local_get_cellpose_mask_volume(app);
if isempty(mask_volume)
    return
end

if z_data < 1 || z_data > size(mask_volume, 3)
    return
end

mask_slice_labels = mask_volume(:, :, z_data);
mask_slice = mask_slice_labels > 0;
if ~any(mask_slice(:))
    text(ax, 8, 14, sprintf('Cellpose mask empty at z=%d', z_data), ...
        'Color', [1, 1, 0], 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0, 0, 0], 'Margin', 2, 'HitTest', 'off');
    return
end

overlay_color = cat(3, ...
    1.0 * ones(size(mask_slice)), ...
    zeros(size(mask_slice)), ...
    1.0 * ones(size(mask_slice)));
overlay_image = image(overlay_color, 'Parent', ax);
overlay_image.AlphaData = 0.14 * double(mask_slice);
overlay_image.HitTest = 'off';

boundary = local_mask_boundary(mask_slice);
if any(boundary(:))
    % Draw edges in image pixel space (1 cell wide). plot(...,'.') uses screen
    % points so outlines stay visually thick in uiaxes; image + AlphaData matches
    % the slice grid and stays thin when zoomed with the data.
    ny = size(mask_slice, 1);
    nx = size(mask_slice, 2);
    yellow_edge = zeros(ny, nx, 3);
    yellow_edge(:, :, 1) = double(boundary);
    yellow_edge(:, :, 2) = double(boundary);
    edge_im = image(ax, yellow_edge);
    edge_im.AlphaData = double(boundary);
    edge_im.HitTest = 'off';
end

end

function boundary = local_mask_boundary(mask_slice)
neighbor_count = conv2(double(mask_slice), ones(3), 'same');
boundary = mask_slice & (neighbor_count < 9);
end

function mask_volume = local_get_cellpose_mask_volume(app)
mask_volume = [];

mp_params = local_resolve_mp_params(app);
if isempty(mp_params)
    return
end
if ~isfield(mp_params, 'masks_mat_path') || isempty(mp_params.masks_mat_path)
    return
end

mask_path = char(string(mp_params.masks_mat_path));
if ~isfile(mask_path)
    return
end

cache_path_key = 'cellpose_mask_cache_path';
cache_data_key = 'cellpose_mask_cache_volume';
if isappdata(app.CELL_ID, cache_path_key) && isappdata(app.CELL_ID, cache_data_key)
    cached_path = getappdata(app.CELL_ID, cache_path_key);
    if strcmp(cached_path, mask_path)
        mask_volume = getappdata(app.CELL_ID, cache_data_key);
        return
    end
end

mask_source = "masks_stitched";
if isfield(mp_params, 'mask_source')
    source_value = lower(char(string(mp_params.mask_source)));
    if strcmp(source_value, 'masks_3d')
        mask_source = "masks_3D";
    end
end

try
    payload = load(mask_path);
catch
    return
end

if isfield(payload, char(mask_source))
    raw_mask = payload.(char(mask_source));
elseif isfield(payload, 'masks_stitched')
    raw_mask = payload.masks_stitched;
elseif isfield(payload, 'masks_3D')
    raw_mask = payload.masks_3D;
else
    return
end

mask_volume = local_align_mask_to_image(raw_mask, size(app.image_data, 1:3));
if isempty(mask_volume)
    return
end

setappdata(app.CELL_ID, cache_path_key, mask_path);
setappdata(app.CELL_ID, cache_data_key, mask_volume);
end

function mp_params = local_resolve_mp_params(app)
mp_params = [];

if isprop(app, 'mp_params') && ~isempty(app.mp_params) && isstruct(app.mp_params)
    mp_params = app.mp_params;
end

needs_fallback = isempty(mp_params) || ...
    ~isfield(mp_params, 'masks_mat_path') || isempty(mp_params.masks_mat_path);
if ~needs_fallback
    return
end

if ~isprop(app, 'id_file') || isempty(app.id_file) || ~isfile(app.id_file)
    return
end

try
    id_payload = load(app.id_file, 'mp_params');
catch
    return
end

if isfield(id_payload, 'mp_params') && isstruct(id_payload.mp_params)
    mp_params = id_payload.mp_params;
end
end

function tf = local_cellpose_overlay_enabled(app)
key = 'show_cellpose_mask_overlay';

if isappdata(app.CELL_ID, key)
    tf = logical(getappdata(app.CELL_ID, key));
else
    tf = false;
    setappdata(app.CELL_ID, key, tf);
end
end

function tf = local_cellpose_slice_centroids_enabled(app)
tf = false;
end

function [rows, cols] = local_label_slice_centroids(label_slice)
rows = [];
cols = [];
label_ids = unique(label_slice(:));
label_ids = label_ids(label_ids > 0);
if isempty(label_ids)
    return
end

rows = nan(numel(label_ids), 1);
cols = nan(numel(label_ids), 1);
for i = 1:numel(label_ids)
    [r, c] = find(label_slice == label_ids(i));
    if isempty(r)
        continue
    end
    rows(i) = mean(r);
    cols(i) = mean(c);
end

keep = isfinite(rows) & isfinite(cols);
rows = rows(keep);
cols = cols(keep);
end

function aligned_mask = local_align_mask_to_image(mask_data, image_shape_xyz)
aligned_mask = [];
mask_data = squeeze(mask_data);
if ndims(mask_data) ~= 3
    return
end

mask_shape = size(mask_data);
if isequal(mask_shape, image_shape_xyz)
    aligned_mask = mask_data;
    return
end

all_perms = perms(1:3);
for i = 1:size(all_perms, 1)
    candidate = permute(mask_data, all_perms(i, :));
    if isequal(size(candidate), image_shape_xyz)
        aligned_mask = candidate;
        return
    end
end
end
