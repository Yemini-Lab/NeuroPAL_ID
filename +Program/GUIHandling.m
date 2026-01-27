classdef GUIHandling
    % Functions responsible for handling our dynamic GUI solutions.

    %% Public variables.
    properties (Constant, Access = public)
        channel_names = {'r', 'g', 'b', 'w', 'dic', 'gfp', ...
            'red', 'green', 'blue', 'white', 'DIC', 'GFP'};

        channel_map = containers.Map( ...
            {'r', 'g', 'b', 'w', 'dic', 'gfp', ...
            'red', 'green', 'blue', 'white', 'DIC', 'GFP'}, ...
            [1, 2, 3, 4, 5, 6, ...
            1, 2, 3, 4, 5, 6]);

        % Processing components
        pos_prefixes = {'tl', 'tm', 'tr', 'bl', 'bm', 'br'};

        proc_components = {
            'ProcNoiseThresholdKnob', ...
            'ProcNoiseThresholdField', ...
            'ProcNormalizeColorsButton', ...
            'ProcHistogramMatchingButton', ...
            'ProcMeasureROINoiseButton', ...
            'ProcMeasure90pthNoiseButton', ...
            'ProcZSlicesEditField', ...
            'ProcXYFactorEditField', ...
            'ProcXYFactorUpdateButton', ...
            'ProcPreviewZslowCheckBox', ...
            'proc_zSlider', ...
            'proc_xSlider', ...
            'proc_ySlider', ...
            'proc_vert_zSlider', ...
            'proc_hor_zSlider', ...
            'proc_tSlider'};
        
        cm_exclusive_gui = {
            'red_measure', ...
            'green_measure', ...
            'blue_measure', ...
            'background_measure', ...
            'SigmagaussEditField', ...
            'red_r', ...
            'red_g', ...
            'red_b', ...
            'green_r', ...
            'green_g', ...
            'green_b', ...
            'blue_r', ...
            'blue_g', ...
            'blue_b', ...
            'background_r', ...
            'background_g', ...
            'background_b', ...
            'ProcWCheckBox', ...
            'ProcWDropDown', ...
            'ProcDICCheckBox', ...
            'ProcDICDropDown', ...
            'ProcGFPCheckBox', ...
            'ProcGFPDropDown', ...
            };

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
            'SubjectNotesTextArea', ...
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

        function gui_lock(app, action, group, event)
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
                    app.data_flags.('Neuronal_Activity') = 1;

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

            if exist('event', 'var')
                event.Source.Enable = 'on';
            end
        end

        function handle = window_fig()
            persistent window_handle

            if any(isempty(window_handle)) || any(~isgraphics(window_handle))
                window_handle = findall(groot, 'Name','NeuroPAL ID');
            end
            
            handle = window_handle;
        end

        function handle = app()
            persistent app_handle

            if any(isempty(app_handle)) || any(isa(app_handle, "handle")) && any(~isvalid(app_handle))
                window_handle = Program.ProgramInfo.window();
                app_handle = window_handle.RunningAppInstance;
            end

            handle = app_handle;
        end

        function sync_channels(event)
            app = Program.ProgramInfo.app;
            previous_value = event.PreviousValue;
            new_value = event.Value;
            channels = {app.ProcRDropDown, app.ProcGDropDown, app.ProcBDropDown, app.ProcWDropDown, app.ProcGFPDropDown, app.DICDropDown};
            for c=1:length(channels)
                channel = channels{c};
                if channel ~= event.Source && channel.Value == new_value
                    channel.Value = previous_value;
                end
            end
        end

        function package = global_grab(window, var)
            % Fulfills requests for local variables across AppDesigner apps.

            global_figures = findall(groot, 'Type','figure');
            scope = Program.GUIHandling.get_parent_app(global_figures(strcmp({global_figures.Name}, window)));

            if ~isempty(scope)
                package = scope.(var);
            else
                package = [];
            end
        end

        function loaded_files = loaded_file_check(app, tree)
            % Checks which of the files that NeuroPAL_ID can load have been
            % loaded and checks their associated nodes in the passed uitree.

            files_to_check = fieldnames(app.data_flags);
            loaded_files = [];

            if app.image_neurons.num_neurons > 1
                app.data_flags.('Neurons') = 1;
            end

            if app.image_neurons.is_any_annotated
                app.data_flags.('Neuronal_Identities') = 1;
            end

            for data=1:length(files_to_check)
                data_file = files_to_check{data};
                if app.data_flags.(data_file)
                    if exist('tree', 'var')
                        tree_app = Program.GUIHandling.get_parent_app(tree);
                        loaded_files = [loaded_files tree_app.(sprintf('%sNode', strrep(data_file, '_', '')))];
                    else
                        loaded_files = [loaded_files {strrep(data_file, '_', '')}];
                    end
                end
            end  

            if exist('tree', 'var')
                tree.CheckedNodes = loaded_files;
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

        function output = get_child_properties(component, property)
            % Get the value of the given property for all children of a component.
            output = struct();

            for comp=1:length(component.Children)
                child = component.Children(comp);

                if any(ismember(properties(child), char(property)))
                    output.(child.Tag) = child.(property);
                end
            end
        end

        function app = get_parent_app(component)
            % Get the application a given component belongs to.

            if ~isempty(component)
                if any(ismember(properties(component), 'RunningAppInstance'))
                    app = component.RunningAppInstance;
                else
                    app = Program.GUIHandling.get_parent_app(component.Parent);
                end
            else
                app = [];
            end
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

        function t = current_frame()
            app = Program.app;
            if app.TabGroup.SelectedTab == app.VideoTrackingTab
                t = app.tEditField.Value;
            else
                t = app.proc_tEditField.Value;
            end
        end

        function mouse_poll(app, click_state)
            app.mouse.pos = get(app.CELL_ID, 'CurrentPoint');
            clicked = exist('click_state', 'var');

            if clicked
                app.mouse.state = click_state;
                app.mouse.drag = struct( ...
                    'origin', {app.mouse.pos}, ...
                    'delta', {[0 0]}, ...
                    'debt', {[0 0]});

            elseif app.mouse.state
                app.mouse.drag.delta = app.mouse.pos - app.mouse.drag.origin + app.mouse.drag.debt;
                app.mouse.drag.debt = app.mouse.drag.debt - app.mouse.drag.delta;

            elseif ~isempty(app.mouse.drag)
                app.mouse.drag.debt = [0 0];
            end
        end

        function event_struct = event2struct(varargin)
            fields = properties(varargin{:});
            
            for i = 1:length(fields)
                fieldName = fields{i};
                event_struct.(fieldName) = varargin{:}.(fieldName);
            end
        end

        function drag_manager(app, mode, event)
            % Manages all click & drag events.

            if app.DisplayNeuronActivityMenu.Checked == 1W
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
            if ~isvalid(hLabel) || ~isvalid(t)
                try
                    if isvalid(t)
                        stop(t);
                        delete(t);
                    end
                catch
                end
                return
            end

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
        function time_string = get_time_string(start_time, count, total)
            time_diff = convertTo(datetime("now"), 'epochtime', 'Epoch', start_time);
            second_diff = double(time_diff) / count;
            
            if second_diff < 0.1
                time_diff = (time_diff*60)/count;
                time_unit = 'ms';
                c_exp = 2;
            else
                time_diff = second_diff;
                time_unit = 'sec';
                c_exp = 1;
            end

            if ~exist('total', 'var')
                time_string = sprintf("(%.2f %s/ea)", time_diff, time_unit);
            else
                time_left = (time_diff/(60^c_exp)) * (total-count);
                time_string = sprintf("(%.2f %s/ea, ~%.f min left)", time_diff, time_unit, time_left);
            end
        end

        function checked_channels = check_channels(app)
            channels = {
                'ProcRCheckBox', ...
                'ProcGCheckBox', ...
                'ProcBCheckBox', ...
                'ProcWCheckBox', ...
                'ProcDICCheckBox', ...
                'ProcGFPCheckBox'};

            checked_channels = [];
            for c=1:length(channels)
                if app.(channels{c}).Value
                    checked_channels = [checked_channels c];
                end
            end
        end

        function proc_save_prompt(app, action)
            check = uiconfirm(app.CELL_ID, "Do you want to save this operation to the file?", "NeuroPAL_ID", "Options", ["Yes", "No, stick with preview"]);
            if strcmp(check, "Yes")
                app.proc_apply_processing(action);
                if isfield(app.flags, action)
                    app.flags = rmfield(app.flags, action);
                end
            else
                app.flags.(action) = 1;
            end
        end

        function histogram_handler(app, mode, image)
            raw = Program.GUIHandling.get_active_volume(app, 'request', 'array');
            nc = size(raw.array, 4);

            if nc < 4
                app.bl_hist_panel.Parent = app.CELL_ID;
                app.bm_hist_panel.Parent = app.CELL_ID;
                app.br_hist_panel.Parent = app.CELL_ID;

                app.bl_hist_panel.Visible = 'off';
                app.bm_hist_panel.Visible = 'off';
                app.br_hist_panel.Visible = 'off';

                app.ProcHistogramGrid.RowHeight = {'1x'};
            else
                app.ProcHistogramGrid.RowHeight = {'1x', '1x'};
            end

            for c=1:nc
                prefix = Program.GUIHandling.pos_prefixes{c};

                switch mode
                    case 'reset'
                        app.(sprintf("%s_hist_panel", prefix)).Visible = 'off';
                        cla(app.(sprintf("%s_hist_ax", prefix)))

                    case 'draw'

                        chan_hist = raw.array(:, :, :, c);

                        if app.HidezerointensitypixelsCheckBox.Value
                            chan_hist = chan_hist(chan_hist>0);
                        end

                        if max(chan_hist, [], 'all') <= 1
                            chan_hist = chan_hist * app.ProcNoiseThresholdKnob.Limits(2);
                        end
                        
                        if any(ismember(app.nameMap.keys(), num2str(c)))
                            h_panel = sprintf("%s_hist_panel", Program.GUIHandling.pos_prefixes{c});
                            h_label = sprintf("%s_Label", Program.GUIHandling.pos_prefixes{c});
                            h_axes = sprintf("%s_hist_ax", Program.GUIHandling.pos_prefixes{c});

                            app.(h_panel).Visible = 'on';
                            app.(h_label).Text = sprintf("%s Channel", app.nameMap(num2str(c)));
                            histogram(app.(h_axes), chan_hist, 'FaceColor', app.shortMap(num2str(c)), 'EdgeColor', app.shortMap(num2str(c)));
                            app.(h_axes).XLim = [app.HidezerointensitypixelsCheckBox.Value, app.(h_axes).XLim(2)];
       
                            if c >= 4
                                app.(h_panel).Parent = app.ProcHistogramGrid;
                                app.(h_panel).Layout.Row = 2;
                                app.(h_panel).Layout.Column = c-3;
                            end
                        end
                end
            end
        end

        function package = get_active_volume(app, varargin)
            Program.Handlers.loading.start('Chunk loading selection...');
            package = struct('state', {{}}, 'dims', {[]}, 'array', {[]}, 'coords', {[]});
            
            p = inputParser;
            addRequired(p, 'app');
            addOptional(p, 'request', 'state');
            addOptional(p, 'coords', []);
            addOptional(p, 'package', package);
            parse(p, app, varargin{:});

            package = p.Results.package;
            
            x = app.proc_xSlider.Value;
            y = min(max(round(app.proc_xSlider.Value), 1), app.proc_xSlider.Limits(2));
            z = min(max(round(app.proc_zSlider.Value), 1), app.proc_zSlider.Limits(2));
            c_bools = Program.Handlers.channels.get_bools('array');
            c_max = Program.Handlers.channels.get_max_idx();
            c_load = 1:c_max;
            t = app.proc_tSlider.Value;

            if isempty(p.Results.coords)
                package.coords = [x y z t];
            elseif length(p.Results.coords) < 3
                package.coords = [p.Results.coords t];
            else
                package.coords = p.Results.coords;
            end

            switch p.Results.request
                case 'all'
                    all_keys = {'state', 'dims', 'array', 'coords'};
                    for k = 1:length(all_keys)
                        t_pack = Program.GUIHandling.get_active_volume(app, 'request', all_keys{k}, 'coords', package.coords, 'package', package);
                        package.(all_keys{k}) = t_pack.(all_keys{k});
                    end

                case 'state'
                    package.state = lower(app.VolumeDropDown.Value);

                case 'dims'
                    if isempty(package.array)
                        package.array = Program.GUIHandling.get_active_volume(app, 'request', 'array', 'coords', package.coords).array;
                    end

                    package.dims = size(package.array);

                case 'array'
                    if app.ProcShowMIPCheckBox.Value
                        switch app.VolumeDropDown.Value
                            case 'Colormap'
                                safe_c = Program.Validation.noskip_index(c_max);
                                slice = app.proc_image.data(:, :, :, c_load);
                            case 'Video'
                                slice = app.retrieve_frame(package.coords(4));
                        end
                    else
                        switch app.VolumeDropDown.Value
                            case 'Colormap'
                                safe_c = Program.Validation.noskip_index(c_max);
                                [~, ~, nz_data, ~] = size(app.proc_image, 'data');
                                z_idx = min(package.coords(3), nz_data);
                                slice = app.proc_image.data(:, :, z_idx, c_load);
                                if ndims(slice) == 3
                                    slice = reshape(slice, size(slice,1), size(slice,2), 1, size(slice,3));
                                end
                            case 'Video'
                                slice = app.retrieve_frame(package.coords(4));
                                slice = slice(:, :, package.coords(3), :);
                                if ndims(slice) == 3
                                    slice = reshape(slice, size(slice,1), size(slice,2), 1, size(slice,3));
                                end
                        end
                    end

                    rgb = Program.GUIHandling.get_rgb;
                    missing_rgb = rgb(~ismember(rgb, c_load));
                    slice(:, :, :, missing_rgb) = 0;
                    slice(:, :, :, [find(~ismember(c_load, c_bools))]) = 0;
                    package.array = slice;

                case 'coords'
                    package.coords(1) = min(max(round(package.dims(1)-app.proc_ySlider.Value), 1), app.proc_ySlider.Limits(2));

            end

            Program.Handlers.loading.done();
        end

        function rgb = get_rgb()
            app = Program.ProgramInfo.app;
            rgb = [ ...
                find(ismember(app.proc_c1_dropdown.Items, app.proc_c1_dropdown.Value)) ...
                find(ismember(app.proc_c2_dropdown.Items, app.proc_c2_dropdown.Value)) ...
                find(ismember(app.proc_c3_dropdown.Items, app.proc_c3_dropdown.Value))];
        end

        function set_gui_limits(app, mode, dims)
            if ~exist('dims', 'var')
                active_volume = Program.GUIHandling.get_active_volume(app, 'request', 'state');
                switch active_volume.state
                    case 'colormap'
                        [ny, nx, nz, nc] = size(app.proc_image, 'data');
    
                    case 'video'
                        nx = app.video_info.nx;
                        ny = app.video_info.ny;
                        nz = app.video_info.nz;
                        nc = app.video_info.nc;
                        nt = app.video_info.nt;
                end

            else
                ny = dims(1);
                nx = dims(2);
                nz = dims(3);
                nc = dims(4);

                if length(dims) > 4
                    nt = dims(5);
                end
            end

            if exist("nt", 'var')
                app.proc_tSlider.Limits = [1, nt];
                app.proc_tSlider.MinorTicks = [];
            end

            app.proc_xyAxes.XLim = [1, nx];
            app.proc_xyAxes.YLim = [1, ny];
            if app.ProcPreviewZslowCheckBox.Value
                app.proc_xzAxes.XLim = [1, nx];
                app.proc_xzAxes.YLim = [1, nz];
                app.proc_yzAxes.XLim = [1, nz];
                app.proc_yzAxes.YLim = [1, ny];
            end

            if strcmp(mode, 'hard')
                app.proc_xSlider.Limits = [1, nx];
                app.proc_ySlider.Limits = [1, ny];
                app.proc_zSlider.Limits = [1, nz];
                app.proc_hor_zSlider.Limits = [1, nz];
                app.proc_vert_zSlider.Limits = [1, nz];

                app.proc_xSlider.Value = round(app.proc_xSlider.Limits(2)/2);
                app.proc_ySlider.Value = round(app.proc_ySlider.Limits(2)/2);
                app.proc_zSlider.Value = round(app.proc_zSlider.Limits(2)/2);
                app.proc_tSlider.Value = 1;
    
                app.proc_xEditField.Value = app.proc_xSlider.Value;
                app.proc_yEditField.Value = app.proc_ySlider.Value;
                app.proc_zEditField.Value = app.proc_zSlider.Value;
                app.proc_tEditField.Value = app.proc_tSlider.Value;
    
                app.proc_hor_zSlider.Value = round(app.proc_hor_zSlider.Limits(2)/2);
                app.proc_vert_zSlider.Value = round(app.proc_vert_zSlider.Limits(2)/2);
            end
        end

        function crop_routine(app)
            mip_flag = 0;

            if ~app.ProcShowMIPCheckBox.Value
                app.ProcShowMIPCheckBox.Value = 1;
            end

            frame = Methods.ChunkyMethods.load_proc_image(app);
            image(frame.xy, 'Parent', app.proc_xyAxes);
            
            if app.ProcPreviewZslowCheckBox.Value
                image(flipud(rot90(frame.yz)), 'Parent', app.proc_xzAxes);
                image(frame.xz, 'Parent', app.proc_yzAxes);
            end

            drawnow;

            Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab');
            check = uiconfirm(app.CELL_ID, "Draw a bounding box on the volume to crop the image.", "NeuroPAL_ID", "Options", ["OK", "Cancel"]);
            if ~strcmp(check, "OK")
                return
            end

            roi = drawrectangle(app.proc_xyAxes,'Color','black','StripeColor','m');
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');

            Program.rotation_gui.draw(app, roi);
        end

        function swap_volumes(app, event)
            if ~exist('event', 'var')
                mode = Program.GUIHandling.get_active_volume(app, 'request', 'state');
            else
                mode = lower(event.Value);
            end

            Program.GUIHandling.set_gui_limits(app, mode);

            switch mode
                case 'colormap'
                    max_val = max(app.proc_image.data, [], "all");

                    chunk_prefs = app.proc_image.prefs;
                    for c=1:app.video_info.nc
                        app.(sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c})).Value = chunk_prefs.gamma(c);
                    end

                case 'video'
                    max_val = max(app.retrieve_frame(app.proc_tSlider.Value), [], "all");
                    
                    for c=1:app.video_info.nc
                        app.(sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c})).Value = 1;
                    end
            end

            Program.GUIHandling.set_thresholds(app, max(max_val, 255));
            Program.Routines.GUI.(sprintf("toggle_%s", mode));

            spectral_unmixing_gui = app.SpectralUnmixingGrid.Children;
            for comp=1:length(spectral_unmixing_gui)
                component = spectral_unmixing_gui(comp);
                if ismember(properties(component), 'Enable')
                    component.Enable = ~component.Enable;
                end
            end

            for comp=1:length(Program.GUIHandling.cm_exclusive_gui)
                app.(Program.GUIHandling.cm_exclusive_gui{comp}).Enable = strcmp(app.VolumeDropDown.Value, 'Colormap');
            end
            app.ProcessingGridLayout.ColumnWidth = {'1x', 282};
        end

        function set_thresholds(app, max_val)
            max_val = cast(max_val, 'double');
            
            if max_val <= 1.0
                new_limits = [0 1];
                tick_step = 0.2;
                start_tick = 0;
            else
                new_limits = [1 max(2, max_val)];
                tick_step = max(1, round(max_val/5));
                start_tick = 1;
            end

            app.ProcNoiseThresholdKnob.Limits = new_limits;
            app.ProcNoiseThresholdField.Limits = new_limits;
            app.ProcNoiseThresholdKnob.MajorTicks = unique([start_tick:tick_step:new_limits(2), new_limits(2)]);
            app.ProcNoiseThresholdKnob.MajorTickLabels = string(app.ProcNoiseThresholdKnob.MajorTicks);
            Program.GUIHandling.shorten_knob_labels(app);

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

        function target = dropper(message, display, image, z)
            target = struct('pixels', {[]}, 'values', {[]});

            app = Program.GUIHandling.get_parent_app(display);
            child_fig = properties(Program.GUIHandling.get_parent_app(display));
            child_fig = app.(child_fig{1});

            check = uiconfirm(child_fig, message, ...
                'Confirmation','Options',{'OK', 'Select different slice'}, ...
                'DefaultOption','OK');

            switch check
                case 'OK'
                    color_roi = drawpoint(display);
                    pos = round(color_roi.Position);
                    delete(color_roi);

                    if exist('z', 'var')
                        target.pixels = [pos(1), pos(2), z];
                        target.values = zeros([1, size(image, 4)]);

                        for c=1:size(image, 4)
                            target.values(c) = unique(impixel(image(:, :, z, c), pos(1), pos(2)));
                        end

                    else
                        target.pixels = [pos(1), pos(2)];
                        target.values = zeros([1, size(image, 3)]);

                        for c=1:size(image, 3)
                            target.values(c) = unique(impixel(image(:, :, c), pos(1), pos(2)));
                        end

                    end

                case 'Select different slice'
                    return
            end
        end


        %% Saving GUI

        function nwb_init(app)          
            Program.GUIHandling.loaded_file_check(app.parent_app, app.Tree)
            worm_properties = {
                'AgeDropDown', ...
                'BodyDropDown', ...
                'SexDropDown', ...
                'StrainEditField', ...
                'SubjectNotesTextArea'};

            for node=1:length(app.Tree.CheckedNodes)
                file = app.Tree.CheckedNodes(node).Text;
                
                switch file
                    case 'NeuroPAL Volume'
                        allow_save = 1;
                        for child=1:length(app.NPALVolumeGrid)
                            app.NPALVolumeGrid.Children(child).Enable = 'on';
                        end

                    case 'Neuronal Identities'
                        app.NeuroPALIDsDescription.Enable = 'on';

                    case {'Video Volume', 'Tracking ROIs'}
                        allow_save = 1;
                        for child=1:length(app.VideoVolumeGrid)
                            app.VideoVolumeGrid.Children(child).Enable = 'on';
                        end

                    case {'Neuronal Activity', 'Stimulus File'}
                        app.NeuronalActivityDescription.Enable = 'on';
                        app.StimulusFileSelect.Enable = 'on';

                        if strcmp(file, 'Stimulus File')
                            stim_file = Program.GUIHandling.global_grab('NeuroPAL ID', 'LoadStimuliButton').Tag;
                            app.StimulusFileSelect.Items{end+1} = stim_file;
                            app.StimulusFileSelect.ItemsData{end+1} = stim_file;
                        end
                end
            end

            if allow_save
                app.SaveButton.Enable = 'on';

                for prop=1:length(worm_properties)
                    app.(worm_properties{prop}).Value = app.parent_app.(worm_properties{prop}).Value;
                end

            else
                uiconfirm(app.parent_app.CELLID, "You need to load a volume before you can save to an NWB file.", "Error!");
                delete(app);
            end
        end
        
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
                        new_row{end+1} = channel.(columns{comp});
                    end

                    app.OpticalUITable.Data = [channel_table; new_row];

                    for comp=1:length(Program.GUIHandling.optical_fields)
                        try
                            app.(sprintf('%sEditField', Program.GUIHandling.optical_fields{comp})).Value = ''; 
                        catch 
                            app.(sprintf('%sEditField', Program.GUIHandling.optical_fields{comp})).Value = 0; 
                        end
                    end
                case 'edit'
                    for comp=1:length(Program.GUIHandling.optical_fields)
                        app.(Program.GUIHandling.optical_fields{comp}).Value = channel_table(channel, comp); 
                    end
                    
                    Program.GUIHandling.device_handler(app, 'remove', channel);
                case 'remove'
                    app.OpticalUITable.Data(channel, :) = [];
            end

        end


        function freehand_roi = rect_to_freehand(roi)
            %RECT_TO_FREEHAND This function converts rectangle ROIs to
            % freehand ROIs. This is useful in cases where rectangle ROIs
            % require rotating, which MATLAB does not support outside of a
            % certain workarounds (e.g. rotate, hgtransform) which all come
            % with various trade-offs.
            %
            %   Inputs:
            %   - roi: Rectangle ROI.
            %
            %   Outputs:
            %   - freehand_roi: Freehand roi.

            % Confirm that the input is not a freehand ROI.
            if ~isa(roi, 'images.roi.Freehand')
                % Get the dimensions of the rectangle.
                xmin = roi.Position(1);
                ymin = roi.Position(2);
                width = roi.Position(3);
                height = roi.Position(4);
                
                % Calculate the four coordinates to pass to the freehand
                % ROI.
                tr = [xmin + width, ymin];
                tl = [xmin, ymin];
                bl = [xmin, ymin + height];
                br = [xmin + width, ymin + height];
    
                % Assemble position array.
                fh_pos = [tr; tl; bl; br];
            else
                fh_pos = roi.Position;
            end

            % Create the freehand roi.
            freehand_roi = images.roi.Freehand(roi.Parent, ...
                'Position', fh_pos, ...
                'FaceAlpha', 0.4, 'Color', [0.1 0.1 0.1], ...
                'StripeColor', 'm', 'InteractionsAllowed', 'translate', ...
                'Tag', 'rot_roi');

            % Delete the original roi.
            delete(roi)
        end


        function [package, device_table, optical_table] = read_gui(app)
            worm = Program.GUIHandling.get_child_properties(app.WormGrid, 'Value');
            author = Program.GUIHandling.get_child_properties(app.AuthorGrid, 'Value');
            colormap = Program.GUIHandling.get_child_properties(app.NPALVolumeGrid, 'Value');
            video = Program.GUIHandling.get_child_properties(app.VideoVolumeGrid, 'Value');
            neurons = Program.GUIHandling.get_child_properties(app.NeuronDataGrid, 'Value');

            device_table = app.DeviceUITable.Data;
            optical_table = app.OpticalUITable.Data;

            colormap.grid_spacing = struct( ...
                'values', [colormap.grid_x, colormap.grid_y, colormap.grid_z], ...
                'unit', colormap.grid_unit);
            video.grid_spacing = colormap.grid_spacing;
            colormap.prefs = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_prefs');

            package = struct( ...
                'worm', worm, ...
                'author', author, ...
                'colormap', colormap, ...
                'video', video, ...
                'neurons', neurons);
        end

        function rot_pos = flat_rotate(pos, theta, offset)
            if ~exist('offset', 'var') || max(offset, [], 'all') == 0
                offset = zeros(size(pos));
            end

            R = [cosd(theta), -sind(theta); sind(theta), cosd(theta)];

            if iscell(pos)
                rot_pos = cellfun(@(x) Program.GUIHandling.flat_rotate(x, theta, offset), pos, 'UniformOutput', false);
            else
                c_spec_dim = size(offset, 2);
                if size(pos, 2) > c_spec_dim
                    pos(1:2) = ((pos(1:2) - offset) * R') + offset;
                    rot_pos = pos;
                else
                    rot_pos = ((pos - offset) * R') + offset;
                end
            end
        end


        function package = cache(mode, label, contents)
            label = string(label);

            if isfile('cache.mat')
                cache = load('cache.mat');
            else
                cache = struct('init', {[]});
                save('cache.mat', '-struct', 'cache');
            end

            switch mode
                case 'save'
                    cache.(label) = contents;
                    save('cache.mat', '-struct', 'cache');

                case 'load'
                    package = cache.(label);

                case 'check'
                    if isfield(cache, label)
                        package = 1;
                    else
                        package = 0;
                    end

            end
        end

    end
end
