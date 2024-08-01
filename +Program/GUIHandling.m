classdef GUIHandling
    % Functions responsible for handling our dynamic GUI solutions.

    %% Public variables.
    properties (Access = public)
    end

    methods (Static)

        %% Global Handlers
        function SendFocus(app, ui_element)
            %% Send focus to a UI element.
            % Hack: Matlab App Designer!!!
            focus(ui_element);
        end


        %% Mouse & Click Handlers
        function init_click_states(app)
            app.mouse_clicked.double_click_delay = 0.3;
            app.mouse_clicked.click = false;
        end

        function restore_pointer(app)
            %% Restore the mouse pointer.
            % Hack: Matlab App Designer!!!
            js_code = ['var elementToChange = document.getElementsByTagName("body")[0];' ...
                'elementToChange.style.cursor = "url(''cursor:default''), auto";'];
            hWin = mlapptools.getWebWindow(app.CELL_ID);
            hWin.executeJS(js_code);
        end

        function drag_manager(app, mode, event)
            % Manages all click & drag events.

            if app.DisplayNeuronActivityMenu.Checked == 1
                pos = get(app.CELL_ID, 'CurrentPoint');
                switch mode
                    case 'down'
                        target = app.grab_land(app.NeuroPALIDTab, pos, 'matlab.ui.container.Panel', 'side-panel', 'matlab.ui.control.ListBox', 'neuron-selector');
                        if ~isempty(target)
                            app.HoverLabel.Position = [pos(1)-app.HoverLabel.Position(3)/2 pos(2)+1 app.HoverLabel.Position(3) app.HoverLabel.Position(4)];
                            app.HoverLabel.Text = char(target.Value);
                            app.HoverLabel.Position(3) = app.HoverLabel.FontSize*size(target.Value,2);
                            app.CELL_ID.WindowButtonMotionFcn = @(src, event) app.DragManager('move', event);
                            app.HoverLabel.Visible = "on";
                        end
                    case 'move'
                        app.HoverLabel.Position = [pos(1)-app.HoverLabel.Position(3)/2 pos(2)+1 app.HoverLabel.Position(3) app.HoverLabel.Position(4)];
                    case 'up'
                        if strcmp(app.HoverLabel.Visible,'on')
                            app.CELL_ID.WindowButtonMotionFcn = @(src, event) 1+1;
                            set(app.HoverLabel, 'Visible', 'off');
    
                            target = app.grab_land(app.NeuroPALIDTab, pos, 'matlab.ui.container.Tab', 'neuron-activity-tab', 'matlab.ui.container.GridLayout', 'browser_trace');
                            if ~isempty(target)
                                target.Children(1).Units = 'pixels';
                                total_x = target.Children(1).InnerPosition;
                                num_plots = size(target.Children(1).DisplayVariables,2);
    
                                selected_plot = 0;
                                y_divs = total_x(4) / num_plots;
                                for n=1:num_plots
                                    x = total_x;
                                    y = y_divs * (n-1);
                                    x(2) = x(2) + y;
                                    x(4) = y_divs;
                                    % sprintf('Cursor y: %d\nSubplot #%d y: %.2f through %.2f', pos(2), n, x(2), x(2) + x(4))
                                    if (pos(1)>x(1)&pos(1)<(x(1)+x(3))&pos(2)>x(2)&pos(2)<(x(2)+x(4)))
                                        selected_plot = num_plots - (n-1);
                                        break
                                    end
                                end

                                % Strip all non-alphanumeric characters from HoverLabel.Text
                                cleanText = regexprep(app.HoverLabel.Text, '[^a-zA-Z0-9]', '');
                                
                                % Pass the cleaned text to updateBrowser
                                app.updateBrowser(cleanText, selected_plot);
                            end
                        end
                end
            end
        end

        function target = grab_land(app, figure, pos, parent_class, parent_tag, class, tag)
            % Check if drag & drop ended up on target component.

            try
                comp_array = findobj(figure, '-depth', inf,'-function','Position', @(x) (pos(1)>x(1)&pos(1)<(x(1)+x(3))&pos(2)>x(2)&pos(2)<(x(2)+x(4))));
                mid_idx = find(arrayfun(@(y) isa(y, parent_class)&strcmp(y.Tag, parent_tag), comp_array), 5);

                if ~isempty(mid_idx)
                    middleman = comp_array(mid_idx);
                    pos(1) = pos(1)-middleman.Position(1);
                    pos(2) = pos(2)-middleman.Position(2)-5;

                    deep_array = findobj(middleman.Children.Children, '-depth', inf,'-function','Position', @(x) (pos(1)>x(1)&pos(1)<(x(1)+x(3))&pos(2)>x(2)&pos(2)<(x(2)+x(4))));
                    target_idx = find(arrayfun(@(y) isa(y, class)&strcmp(y.Tag, tag), deep_array), 5);

                    if ~isempty(target_idx)
                        target = deep_array(target_idx);
                    else
                        target = [];
                    end
                else
                    target = [];
                end
            catch
                target = [];
            end
        end

        %% Neuronal Identification Tab

        function init_neuron_marker(app)
            %% Initialize the neuron marker GUI attributes.
            % Note: initialization is performed by startupFcn due construction issues.

            app.neuron_marker.shape = 'c';
            app.neuron_marker.color.edge = [0,0,0];
        end

        function freeze_image_gui(app, action)
            switch action
                case {1, 'unlock', 'enable'}
                    % Enable all image GUI functionality.
        
                    % Enable the menu items.
                    app.ImageMenu.Enable = 'on';
                    app.PreprocessingMenu.Enable = 'on';
        
                    % Enable the worm info.
                    app.BodyDropDown.Enable = 'on';
                    app.AgeDropDown.Enable = 'on';
                    app.SexDropDown.Enable = 'on';
                    app.StrainEditField.Enable = 'on';
                    app.NotesEditField.Enable = 'on';
        
                    % Enable the color channels.
                    app.RCheckBox.Enable = 'on';
                    app.GCheckBox.Enable = 'on';
                    app.BCheckBox.Enable = 'on';
                    app.WCheckBox.Enable = 'on';
                    app.DICCheckBox.Enable = 'on';
                    app.GFPCheckBox.Enable = 'on';
                    app.RDropDown.Enable = 'on';
                    app.GDropDown.Enable = 'on';
                    app.BDropDown.Enable = 'on';
                    app.WDropDown.Enable = 'on';
                    app.DICDropDown.Enable = 'on';
                    app.GFPDropDown.Enable = 'on';
        
                    % Enable the neuron detection info.
                    app.AutoDetectButton.Enable = 'on';
                    app.MouseClickDropDown.Enable = 'on';
        
                    % Enable the image info.
                    app.ZSlider.Enable = 'on';
                    app.ZAxisDropDown.Enable = 'on';
                    app.FlipZButton.Enable = 'on';
                    app.ZCenterEditField.Enable = 'on';
                case {0, 'lock', 'disable'}
                    % Disable all image GUI functionality.
        
                    % Disable the menu items.
                    app.ImageMenu.Enable = 'off';
                    app.PreprocessingMenu.Enable = 'off';
        
                    % Disable the worm info.
                    app.BodyDropDown.Enable = 'off';
                    app.AgeDropDown.Enable = 'off';
                    app.SexDropDown.Enable = 'off';
                    app.StrainEditField.Enable = 'off';
                    app.NotesEditField.Enable = 'off';
        
                    % Disable the color channels.
                    app.RCheckBox.Enable = 'off';
                    app.GCheckBox.Enable = 'off';
                    app.BCheckBox.Enable = 'off';
                    app.WCheckBox.Enable = 'off';
                    app.DICCheckBox.Enable = 'off';
                    app.GFPCheckBox.Enable = 'off';
                    app.RDropDown.Enable = 'off';
                    app.GDropDown.Enable = 'off';
                    app.BDropDown.Enable = 'off';
                    app.WDropDown.Enable = 'off';
                    app.DICDropDown.Enable = 'off';
                    app.GFPDropDown.Enable = 'off';
        
                    % Disable the neuron detection info.
                    app.AutoDetectButton.Enable = 'off';
                    app.MouseClickDropDown.Enable = 'off';
        
                    % Disable the image info.
                    app.ZSlider.Enable = 'off';
                    app.ZAxisDropDown.Enable = 'off';
                    app.FlipZButton.Enable = 'off';
                    app.ZCenterEditField.Enable = 'off';
        
                    % Disable the neuron info.
                    DisableNeuronGUI(app);
            end
        end

        function freeze_neuron_gui(app, action)
            switch action
                case {1, 'unlock', 'enable'}
                    % Enable all neuron GUI functionality.
        
                    % Enable the menu items.
                    app.AnalysisMenu.Enable = 'on';
                    app.RotateImageMenu.Enable = 'on';
                    app.RotateNeuronsMenu.Enable = 'on';
                    app.DeleteUserIDsMenu.Enable = 'on';
                    app.DeleteModelIDsMenu.Enable = 'on';
                    app.SaveIDImageMenu.Enable = 'on';
        
                    % Enable the neuron info.
                    app.SaveIDsButton.Enable = 'on';
                    app.AutoIDAllButton.Enable = 'on';
                    app.AutoIDButton.Enable = 'on';
                    app.UserIDButton.Enable = 'on';
                    app.ColorAtlasCheckBox.Enable = 'on';
                    app.NextNeuronDropDown.Enable = 'on';
                    app.UserNeuronIDsListBox.Enable = 'on';
                case {0, 'lock', 'disable'}
                   % Disable all neuron GUI functionality.

                    % Disable the menu items.
                    app.AnalysisMenu.Enable = 'off';
                    app.RotateImageMenu.Enable = 'off';
                    app.RotateNeuronsMenu.Enable = 'off';
                    app.DeleteUserIDsMenu.Enable = 'off';
                    app.DeleteModelIDsMenu.Enable = 'off';
                    app.SaveIDImageMenu.Enable = 'off';
        
                    % Disable the neuron info.
                    app.SaveIDsButton.Enable = 'off';
                    app.AutoIDAllButton.Enable = 'off';
                    app.AutoIDButton.Enable = 'off';
                    app.UserIDButton.Enable = 'off';
                    app.ColorAtlasCheckBox.Enable = 'off';
                    app.NextNeuronDropDown.Enable = 'off';
                    app.UserNeuronIDsListBox.Enable = 'off';
            end
        end

        function activity_format_stack(app)
            sample_neuron = keys(app.neuron_activity_by_name);
            length = max(size(app.neuron_activity_by_name(sample_neuron{1})));

            app.VolTrace.GridVisible = 'on';
            app.VolTrace.XLabel = 't';
            app.VolTrace.Layout.Row = [1, size(app.VolTraceHelperGrid.RowHeight,2)];
            app.VolTrace.Layout.Column = [1,2];

            if ~isempty(app.framerate)
                % Add a listener for changes in 'XLim' property
                stAxes = findobj(app.VolTrace.NodeChildren, 'Type','Axes');
                addlistener(stAxes, 'XLim', 'PostSet', @(src, event) updateXTicks(app, length));
                
                % Initial setup
                updateXTicks(app, app.framerate);
            end
        end

        function activity_update_x_ticks(app, framerate)
            % Get the x-axis data
            xData = app.VolTrace.XData;
        
            % Determine the type of x-axis data
            if all(xData >= 1e9) % Assuming Unix timestamps
                timeInSeconds = (xData - xData(1)) / 1000; % Convert to seconds from milliseconds
            elseif max(xData) <= length(xData) % Assuming frame counts
                timeInSeconds = xData / framerate; % Convert to seconds using framerate
            else % Assuming seconds
                timeInSeconds = xData;
            end
        
            % Convert to MM:SS format
            minutes = floor(timeInSeconds / 60);
            seconds = mod(timeInSeconds, 60);
            tickLabels = arrayfun(@(m, s) sprintf('%02d:%02d', m, s), minutes, seconds, 'UniformOutput', false);
        
            % Find the underlying axes and set the tick values and labels
            stAxes = findobj(app.VolTrace.NodeChildren, 'Type','Axes');
            set(stAxes, 'XTick', xData, 'XTickLabel', tickLabels);
        end


        %% Log Tab

        function fade_log(app, t, hLabel)
            currentColor = hLabel.FontColor;
            newColor = min(currentColor + [0.02 0.02 0.02], [0.9 0.9 0.9]);
            hLabel.FontColor = newColor;
        
            if all(newColor == [0.9 0.9 0.9])
                delete(hLabel);
                stop(t);
                delete(t);
            end
        end


        %% Processing Tab
        function freeze_processing_gui(app, action)
            switch action
                case {1, 'unlock', 'enable'}
                    set(app.tl_hist_slider, 'Enable', 'on');
                    set(app.tm_hist_slider, 'Enable', 'on');
                    set(app.tr_hist_slider, 'Enable', 'on');
                    set(app.bl_hist_slider, 'Enable', 'on');
                    set(app.bm_hist_slider, 'Enable', 'on');
                    set(app.br_hist_slider, 'Enable', 'on');

                    set(app.tl_GammaEditField, 'Enable', 'on');
                    set(app.tm_GammaEditField, 'Enable', 'on');
                    set(app.tr_GammaEditField, 'Enable', 'on');
                    set(app.bl_GammaEditField, 'Enable', 'on');
                    set(app.bm_GammaEditField, 'Enable', 'on');
                    set(app.br_GammaEditField, 'Enable', 'on');
                    
                    set(app.ProcNoiseThresholdKnob, 'Enable', 'on');
                    set(app.ProcNoiseThresholdField, 'Enable', 'on');

                    set(app.ProcNormalizeColorsButton, 'Enable', 'on');
                    set(app.ProcHistogramMatchingButton, 'Enable', 'on');

                    set(app.ProcMeasureROINoiseButton, 'Enable', 'on');
                    set(app.ProcMeasure90pthNoiseButton, 'Enable', 'on');

                    set(app.ProcMirrorImageButton, 'Enable', 'on');
                    set(app.ProcRotateClockwiseButton, 'Enable', 'on');
                    set(app.ProcRotateCounterclockwiseButton, 'Enable', 'on');

                    set(app.ProcZSlicesEditField, 'Enable', 'on');
                    set(app.ProcXYFactorEditField, 'Enable', 'on');
                    set(app.ProcXYFactorUpdateButton, 'Enable', 'on');
                    set(app.ProcZFactorUpdateButton, 'Enable', 'on');
                    set(app.ProcPreviewZslowCheckBox, 'Enable', 'on');
                case {0, 'lock', 'disable'}
                    set(app.tl_hist_slider, 'Enable', 'off');
                    set(app.tm_hist_slider, 'Enable', 'off');
                    set(app.tr_hist_slider, 'Enable', 'off');
                    set(app.bl_hist_slider, 'Enable', 'off');
                    set(app.bm_hist_slider, 'Enable', 'off');
                    set(app.br_hist_slider, 'Enable', 'off');

                    set(app.tl_GammaEditField, 'Enable', 'off');
                    set(app.tm_GammaEditField, 'Enable', 'off');
                    set(app.tr_GammaEditField, 'Enable', 'off');
                    set(app.bl_GammaEditField, 'Enable', 'off');
                    set(app.bm_GammaEditField, 'Enable', 'off');
                    set(app.br_GammaEditField, 'Enable', 'off');
                    
                    set(app.ProcNoiseThresholdKnob, 'Enable', 'off');
                    set(app.ProcNoiseThresholdField, 'Enable', 'off');

                    set(app.ProcNormalizeColorsButton, 'Enable', 'off');
                    set(app.ProcHistogramMatchingButton, 'Enable', 'off');

                    set(app.ProcMeasureROINoiseButton, 'Enable', 'off');
                    set(app.ProcMeasure90pthNoiseButton, 'Enable', 'off');

                    set(app.ProcMirrorImageButton, 'Enable', 'off');
                    set(app.ProcRotateClockwiseButton, 'Enable', 'off');
                    set(app.ProcRotateCounterclockwiseButton, 'Enable', 'off');

                    set(app.ProcZSlicesEditField, 'Enable', 'off');
                    set(app.ProcXYFactorEditField, 'Enable', 'off');
                    set(app.ProcXYFactorUpdateButton, 'Enable', 'off');
                    set(app.ProcZFactorUpdateButton, 'Enable', 'off');
                    set(app.ProcPreviewZslowCheckBox, 'Enable', 'off');
            end
        end

        function set_thresholds(app, max_val)
            app.ProcNoiseThresholdKnob.Limits = [1 max_val];
            app.ProcNoiseThresholdField.Limits = app.ProcNoiseThresholdKnob.Limits;

            app.tl_hist_slider.Limits = app.ProcNoiseThresholdKnob.Limits;
            app.tm_hist_slider.Limits = app.ProcNoiseThresholdKnob.Limits;
            app.tr_hist_slider.Limits = app.ProcNoiseThresholdKnob.Limits;
            app.bl_hist_slider.Limits = app.ProcNoiseThresholdKnob.Limits;
            app.bm_hist_slider.Limits = app.ProcNoiseThresholdKnob.Limits;
            app.br_hist_slider.Limits = app.ProcNoiseThresholdKnob.Limits;

            app.tl_hist_slider.Value = app.ProcNoiseThresholdKnob.Limits;
            app.tm_hist_slider.Value = app.ProcNoiseThresholdKnob.Limits;
            app.tr_hist_slider.Value = app.ProcNoiseThresholdKnob.Limits;
            app.bl_hist_slider.Value = app.ProcNoiseThresholdKnob.Limits;
            app.bm_hist_slider.Value = app.ProcNoiseThresholdKnob.Limits;
            app.br_hist_slider.Value = app.ProcNoiseThresholdKnob.Limits; 

            app.tl_hist_ax.XLim = app.ProcNoiseThresholdKnob.Limits;
            app.tm_hist_ax.XLim = app.ProcNoiseThresholdKnob.Limits;
            app.tr_hist_ax.XLim = app.ProcNoiseThresholdKnob.Limits;
            app.bl_hist_ax.XLim = app.ProcNoiseThresholdKnob.Limits;
            app.bm_hist_ax.XLim = app.ProcNoiseThresholdKnob.Limits;
            app.br_hist_ax.XLim = app.ProcNoiseThresholdKnob.Limits;
        end

        function shorten_knob_labels(app)
            fixedLabels = cell(size(app.ProcNoiseThresholdKnob.MajorTickLabels));
            for n = 1:length(app.ProcNoiseThresholdKnob.MajorTickLabels)
                currentTick = app.ProcNoiseThresholdKnob.MajorTickLabels{n};
                currentTickNumeric = str2double(currentTick);
                
                if length(currentTick) > 3
                    exponent = floor(log10(currentTickNumeric));
                    base = currentTickNumeric / 10^exponent;
                    currentTick = [num2str(base, '%.1f') 'e' num2str(exponent)];
                end
                
                fixedLabels{n} = currentTick;
            end
        
            app.ProcNoiseThresholdKnob.MajorTickLabels = fixedLabels;
        end

    end
end