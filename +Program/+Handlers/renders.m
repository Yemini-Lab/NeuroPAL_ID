classdef renders
    
    properties
    end
    
    methods (Static)
        function draw_z(view, ax)
            % Draw the neurons in this z-slice.

            app = Program.app;

            % Sanity check the Z slice value.
            z = round(app.ZSlider.Value);
            app.logEvent('Main',sprintf('Drawing slice %s...', string(z)), 0);
            app.ZSlider.Value = z;

            % Is there an image?
            if isempty(app.image_data)
                return;
            end

            % Flip the Z-axis.
            z_num = z;
            if app.image_prefs.is_Z_flip
                z = size(app.image_data,3) - z + 1;
            end

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
            xy = squeeze(view(:,:,z,:,:));
            % Display the current slice in the XY axis.
            gui_image = image(xy, 'Parent', ax); hold(ax, 'on');

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

                % Since z (which is found by MP) can be a continuous value
                % to find all the neurons in the current slice we find the
                % ones that lie in the interval [z-z_dot_view, z+z_dot_view]. Finally we
                % change the x and y dimension to fix the inconsistent
                % behavior of Matlab figures for scatter and image function.
                z_dot_view = 1.5;
                current_z_indices = neuron_locations(:,3)>z-z_dot_view & neuron_locations(:,3)<z+z_dot_view;
                positions = neuron_locations(current_z_indices, 1:2);

                % Draw the neuron markers.
                neuron_marker_plot = scatter(ax, positions(:, 2), positions(:, 1), ...
                    neuron_marker_sizes(current_z_indices), ...
                    neuron_marker_colors(current_z_indices, :), ...
                    'filled', 'MarkerEdgeColor', app.neuron_marker.color.edge, ...
                    'LineWidth', neuron_line_size);

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
    end
end

