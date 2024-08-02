classdef GUIHandling
    % Functions responsible for handling our dynamic GUI solutions.

    %% Public variables.
    properties (Constant, Access = public)
        pos_prefixes = {'tl', 'tm', 'tr', 'bl', 'bm', 'br'};

        % NWB components
        device_lists = {
            'Npal', ...
            'Video'};

        optical_fields = {
            'Fluorophore', ...
            'Filter', ...
            'ExLambda', ...
            'ExFilterLow', ...
            'ExFilterHigh', ...
            'EmLambda', ...
            'EmFilterLow', ...
            'EmFilterHigh'};

        activity_components = {
            'DisplayNeuronActivityMenu'};

        id_components = {
            'ImageMenu', ...
            'PreprocessingMenu', ...
            'BodyDropDown', ...
            'AgeDropDown', ...
            'SexDropDown', ...
            'StrainEditField', ...
            'NotesEditField', ...
            'RCheckBox', ...
            'GCheckBox', ...
            'BCheckBox', ...
            'WCheckBox', ...
            'DICCheckBox', ...
            'GFPCheckBox', ...
            'RDropDown', ...
            'GDropDown', ...
            'BDropDown', ...
            'WDropDown', ...
            'DICDropDown', ...
            'GFPDropDown', ...
            'AutoDetectButton', ...
            'MouseClickDropDown', ...
            'ZSlider', ...
            'ZAxisDropDown', ...
            'FlipZButton', ...
            'ZCenterEditField'};

        neuron_components = {
            'AnalysisMenu', ...
            'RotateImageMenu', ...
            'RotateNeuronsMenu', ...
            'DeleteUserIDsMenu', ...
            'DeleteModelIDsMenu', ...
            'SaveIDImageMenu', ...
            'SaveIDsButton', ...
            'AutoIDAllButton', ...
            'AutoIDButton', ...
            'UserIDButton', ...
            'ColorAtlasCheckBox', ...
            'NextNeuronDropDown', ...
            'UserNeuronIDsListBox'};

        proc_components = {
            'ProcNoiseThresholdKnob', ...
            'ProcNoiseThresholdField', ...
            'ProcNormalizeColorsButton', ...
            'ProcHistogramMatchingButton', ...
            'ProcMeasureROINoiseButton', ...
            'ProcMeasure90pthNoiseButton', ...
            'ProcMirrorImageButton', ...
            'ProcRotateClockwiseButton', ...
            'ProcRotateCounterclockwiseButton', ...
            'ProcZSlicesEditField', ...
            'ProcXYFactorEditField', ...
            'ProcXYFactorUpdateButton', ...
            'ProcZFactorUpdateButton', ...
            'ProcPreviewZslowCheckBox'};
    end

    methods (Static)

        %% Global Handlers
        function gui_init(app)
            % Resize the figure to fit most of the screen size.
            screen_size = get(groot, 'ScreenSize');
            screen_size = screen_size(3:4);
            screen_margin = floor(screen_size .* [0.07,0.05]);
            figure_size(1:2) = screen_margin / 2;
            figure_size(3) = screen_size(1) - screen_margin(1);
            figure_size(4) = screen_size(2) - 2*screen_margin(2);
            app.CELL_ID.Position = figure_size;

            % Set up placeholder buttons
            button_locations = figure_size;
            
            if any(button_locations <= 0)
                button_locations = figure_size;
            end

            button_locations(1:2) = [1 1];
            
            app.ProcessingButton.Parent = app.ProcessingGridLayout.Parent;
            app.ProcessingButton.Position = button_locations;
            set(app.ProcessingButton, 'Visible', 'on');

            app.IdButton.Parent = app.IdGridLayout.Parent;
            app.IdButton.Position = button_locations;
            set(app.IdButton, 'Visible', 'on');

            app.TrackingButton.Parent = app.VideoGridLayout.Parent;
            app.TrackingButton.Position = button_locations;
            set(app.TrackingButton, 'Visible', 'on');
        end

        function gui_lock(app, action, group)
            switch action
                case {1, 'unlock', 'enable', 'on'}
                    state = 'on';
                case {0, 'lock', 'disable', 'off'}
                    state = 'off';
            end

            switch group
                case 'neuron_gui'
                    gui_components = Program.GUIHandling.neuron_components;

                case 'activity_gui'
                    gui_components = Program.GUIHandling.activity_components;

                case 'identification_tab'
                    gui_components = Program.GUIHandling.id_components;
                    Program.GUIHandling.gui_lock(app, state, 'neuron_gui');

                case 'processing_tab'
                    gui_components = Program.GUIHandling.proc_components;

                    for pos=1:length(Program.GUIHandling.pos_prefixes)
                        app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos})).Enable = state;
                        app.(sprintf('%s_GammaEditField', Program.GUIHandling.pos_prefixes{pos})).Enable = state;
                    end
            end

            for comp=1:length(gui_components)
                app.(gui_components{comp}).Enable = state;
            end
        end

        function mutually_exclusive(event, counterparts, property)
            % Ensures that the GUI component that triggered this function
            % call always expresses the opposite boolean property of all
            % GUI components in the counterparts cell array.

            for comp=1:length(counterparts)
                counterparts{comp}.(property) = ~event.Source.(property);
            end
        end

        function send_focus(ui_element)
            % Send focus to a UI element.
            % Hack: Matlab App Designer!!!
            focus(ui_element);
        end


        %% Mouse & Click Handlers
        function init_click_states(app)
            % Initialize the mouse click states (a hack to detect double clicks).
            % Note: initialization is performed by startupFcn due construction issues.

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
            % Initialize the neuron marker GUI attributes.
            % Note: initialization is performed by startupFcn due construction issues.

            app.neuron_marker.shape = 'c';
            app.neuron_marker.color.edge = [0,0,0];
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

        function fade_log(t, hLabel)
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
        function set_thresholds(app, max_val)
            new_limits = [1 max_val];

            app.ProcNoiseThresholdKnob.Limits = new_limits;
            app.ProcNoiseThresholdField.Limits = new_limits;

            for pos=1:length(Program.GUIHandling.pos_prefixes)
                app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos})).Limits = new_limits;
                app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos})).Value = new_limits;
                app.(sprintf('%s_hist_ax', Program.GUIHandling.pos_prefixes{pos})).XLim = new_limits;
            end
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


        %% Saving GUI
        
        function device_handler(app, action, device)
            device_table = app.DeviceUITable.Data;

            switch action
                case 'add'
                    for comp=1:length(Program.GUIHandling.device_lists)
                        app.(sprintf('%sHardwareDeviceDropDown', Program.GUIHandling.device_lists{comp})).Items{end+1} = device.name;
                        app.(sprintf('%sHardwareDeviceDropDown', Program.GUIHandling.device_lists{comp})).ItemsData{end+1} = device.name;
                    end

                    app.NameEditField.Value = '';
                    app.ManufacturerEditField.Value = '';
                    app.HardwareDescriptionTextArea.Value = '';

                    app.DeviceUITable.Data = [device_table; {device.name, device.manu, device.desc}];

                case 'edit'
                    logged_device = struct(...
                        'name', char(device_table(device, 1)), ...
                        'manu', char(device_table(device, 2)), ...
                        'desc', char(device_table(device, 3)));

                    app.NameEditField.Value = logged_device.name;
                    app.ManufacturerEditField.Value = logged_device.manu;
                    app.HardwareDescriptionTextArea.Value = logged_device.desc;
                    
                    Program.GUIHandling.device_handler(app, 'remove', device);

                case 'remove'
                    app.DeviceUITable.Data(device, :) = [];

                    for comp=1:length(Program.GUIHandling.device_lists)
                        app.(sprintf('%sHardwareDeviceDropDown', Program.GUIHandling.device_lists{comp})).Items(device) = [];
                        app.(sprintf('%sHardwareDeviceDropDown', Program.GUIHandling.device_lists{comp})).ItemsData(device) = [];
                    end

            end

        end
        
        function channel_handler(app, action, channel)
            channel_table = app.OpticalUITable.Data;

            switch action
                case 'add'
                    columns = fieldnames(channel);

                    new_row = {};
                    for comp=1:length(columns)
                        new_row{end+1} = channel.(columns.(comp));
                    end

                    app.OpticalUITable.Data = [channel_table; new_row];

                    for comp=1:length(Program.GUIHandling.optical_fields)
                        clear(app.(Program.GUIHandling.optical_fields{comp}).Value); 
                    end
                case 'edit'
                    for comp=1:length(Program.GUIHandling.optical_fields)
                        app.(Program.GUIHandling.optical_fields{comp}).Value = channel_table(channel, comp); 
                    end
                    
                    Program.GUIHandling.device_handler(app, 'remove', channel);
                case 'remove'
                    app.OpticalUITable.Data(device, :) = [];
            end

        end

    end
end