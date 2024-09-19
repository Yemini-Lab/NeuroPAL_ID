classdef GUIHandling
    % Functions responsible for handling our dynamic GUI solutions.

    %% Public variables.
    properties (Constant, Access = public)
        channel_names = {'r', 'g', 'b', 'w', 'dic', 'gfp', ...
            'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'};

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
            'ProcMirrorImageButton', ...
            'ProcRotateClockwiseButton', ...
            'ProcRotateCounterclockwiseButton', ...
            'ProcZSlicesEditField', ...
            'ProcXYFactorEditField', ...
            'ProcXYFactorUpdateButton', ...
            'ProcZFactorUpdateButton', ...
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
            };

        proc_channel_strings = struct( ...
            'dd', {"proc_c%.f_dropdown"}, ...
            'up', {"proc_c%.f_up"}, ...
            'down', {"proc_c%.f_down"}, ...
            'del', {"proc_c%.f_delete"});

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
            if any(button_locations <= 0) % This is a workaround to avoid a MATLAB bug that pops up on slower systems. DO NOT REMOVE.
                button_locations = figure_size;
            end
            button_locations(1:2) = [1 1];

            Program.GUIHandling.gui_overlap(app.ProcToggleChannelsPanel, app.EditColorChannelsPanel);
            Program.GUIHandling.gui_overlap(app.ProcessingGridLayout, app.ProcessingButton, 'Position', button_locations);
            Program.GUIHandling.gui_overlap(app.VideoGridLayout, app.TrackingButton, 'Position', button_locations);
            Program.GUIHandling.gui_overlap(app.IdGridLayout, app.IdButton, 'Position', button_locations);
            set(app.ProcessingButton, 'Visible', 'on');
            set(app.TrackingButton, 'Visible', 'on');
            set(app.IdButton, 'Visible', 'on');
        end

        
        function gui_overlap(default_component, hotswap_component, varargin)
            p = inputParser;
            addRequired(p, 'default_component');
            addRequired(p, 'hotswap_component');
            addOptional(p, 'Parent', default_component.Parent);
            addOptional(p, 'Position', default_component.Position);
            addOptional(p, 'Layout', default_component.Layout);
            parse(p, default_component, hotswap_component, varargin{:});
        
            positional_properties = {'Parent', 'Position', 'Layout'};
            
            for k = 1:length(positional_properties)
                 prop = positional_properties{k};
        
                 if isprop(default_component, prop) && isprop(hotswap_component, prop) && ~isempty(p.Results.(prop))
                     hotswap_component.(prop) = p.Results.(prop);
                 end
            end
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


        function mouse_poll(app, state)
            app.mouse.pos = get(app.UIFigure, 'CurrentPoint');

            if exist('state', 'var')
                app.mouse.state = state;
            end
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
            channels = Program.GUIHandling.get_channels(app);
            nc = length(channels.all);

            % If all checked channels are in the top row, hide the bottom
            % row of the histogram grid layout.
            if all(ismember(channels.ordered(channels.checked), channels.ordered(1:3)))
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
                    case 'draw'
                        if channels.checked(c)
                            if channels.checked(1)
                                chan_hist = raw.array(:, :, :, c);
                            else
                                chan_hist = raw.array(:, :, :, c-min(channels.all(channels.checked))+1);
                            end
    
                            if app.HidezerointensitypixelsCheckBox.Value
                                chan_hist = chan_hist(chan_hist>0);
                            end
    
                            if max(chan_hist, [], 'all') <= 1
                                chan_hist = chan_hist * app.ProcNoiseThresholdKnob.Limits(2);
                            end
                            
                            h_panel = sprintf("%s_hist_panel", Program.GUIHandling.pos_prefixes{c});
                            h_label = sprintf("%s_Label", Program.GUIHandling.pos_prefixes{c});
                            h_axes = sprintf("%s_hist_ax", Program.GUIHandling.pos_prefixes{c});
                            target_dropdown = app.(sprintf("proc_c%.f_dropdown", c));

                            app.(h_panel).Visible = 'on';
                            app.(h_label).Text = sprintf("%s Channel", target_dropdown.Value);
                            histogram(app.(h_axes), chan_hist, 'FaceColor', app.shortMap(target_dropdown.Value), 'EdgeColor', app.shortMap(target_dropdown.Value));
                            app.(h_axes).XLim = [app.HidezerointensitypixelsCheckBox.Value, app.(h_axes).XLim(2)];
       
                            if c >= 4
                                app.(h_panel).Parent = app.ProcHistogramGrid;
                                app.(h_panel).Layout.Row = 2;
                                app.(h_panel).Layout.Column = c-3;
                            end
                        end

                    case 'reset'
                        app.(sprintf("%s_hist_panel", prefix)).Visible = 'off';
                        cla(app.(sprintf("%s_hist_ax", prefix)))
                end
            end
        end

        function package = get_active_volume(app, varargin)
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
            c_idx = Program.GUIHandling.get_channels(app).all;
            c = Program.GUIHandling.get_channels(app).checked;
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
                                if all(diff(c_idx(c)) == 1)
                                    slice = app.proc_image.data(:, :, :, c_idx(c));
                                else
                                    slice = app.proc_image.data(:, :, :, 1:max(c_idx(c)));
                                end
                            case 'Video'
                                slice = app.retrieve_frame(package.coords(4));
                                slice = slice(:, :, :, c_idx(c));
                        end
                    else
                        switch app.VolumeDropDown.Value
                            case 'Colormap'
                                if all(diff(c_idx(c)) == 1)
                                    slice = app.proc_image.data(:, :, package.coords(3), c_idx(c));
                                else
                                    slice = app.proc_image.data(:, :, package.coords(3), 1:max(c_idx(c)));
                                end
                            case 'Video'
                                slice = app.retrieve_frame(package.coords(4));
                                slice = slice(:, :, package.coords(3), c_idx(c));
                        end
                    end

                    package.array = slice;

                case 'coords'
                    package.coords(1) = min(max(round(package.dims(1)-app.proc_ySlider.Value), 1), app.proc_ySlider.Limits(2));

            end
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

        function channels = get_channels(app, specific_channel)
            nc = length(app.proc_channel_grid.RowHeight)-2;
            dd_string = "proc_c%.f_dropdown";
            cb_string = "proc_c%.f_checkbox";
            
            if exist('specific_channel', 'var') % If we want the index of some number of specific channels, grab just that.
                channels = find(strcmp(cellfun(@(c) app.(sprintf(dd_string, c)).Value, num2cell(1:nc), 'UniformOutput', false), specific_channel));
                return
            end
            
            channels = struct( ...
                'rgbw' , {[]}, 'all', {[]}, ...                             % Arrays of channel indices
                'ordered', {[]}, ...                                        % Channel names ordered by indices
                'render', {[]}, ...                                         % Render order of channels to render
                'checked', {[]}, ...                                        % Logical array of channels to render
                'gui', {[]}, ...                                            % Channel GUI components
                'hasGFP', {[]}, 'hasDIC', {[]}, 'hasWhite', {[]});          % Whether volume has a given special channel

            channels.ordered = cellfun(@(c) app.(sprintf(dd_string, c)).Value, num2cell(1:nc), 'UniformOutput', false);
            channels.checked = cellfun(@(c) app.(sprintf(cb_string, c)).Value, num2cell(1:nc), 'UniformOutput', false);
            channels.checked = [channels.checked{:}];
            channels.gui = cellfun(@(c) app.(sprintf(dd_string, c)), num2cell(1:nc), 'UniformOutput', false);

            red = find(strcmp(channels.ordered, "Red"));
            green = find(strcmp(channels.ordered, "Green"));
            blue = find(strcmp(channels.ordered, "Blue"));
            white = find(strcmp(channels.ordered, "White"));
            DIC = find(strcmp(channels.ordered, "DIC"));
            GFP = find(strcmp(channels.ordered, "GFP"));

            channels.rgbw = [red green blue white];
            channels.all = [red green blue white DIC GFP];
            channels.render = tiedrank(channels.all);

            channels.hasWhite = ~isempty(white);
            channels.hasDIC = ~isempty(DIC);
            channels.hasGFP = ~isempty(GFP);
        end

        function edit_channels(app, varargin)
            p = inputParser;

            addRequired(p, 'app');      % App handle
            addOptional(p, 'mode', 'gui');  % Called by event or gui?
            addOptional(p, 'source', []);   % If event, source component
            addOptional(p, 'target', []);   % Index of target channel
            addOptional(p, 'action', 'none');   % Action to be taken

            % Initialization arguments
            addOptional(p, 'order', []);    % Channel order
            addOptional(p, 'count', 0);     % # of channels
            parse(p, app, varargin{:}); action = p.Results.action;
            gui_strings = Program.GUIHandling.proc_channel_strings;

            if ~isempty(p.Results.source)
                source = p.Results.source;
                mode = 'event';
                action = source.Text;
                target = str2double(source.Tag);
            else
                mode = 'gui';
            end

            if ~isempty(p.Results.target)
                target = p.Results.target;
            end

            if exist('target', 'var')
                target_dd = app.(sprintf(gui_strings.dd, target));
                grid = target_dd.Parent;
            else
                grid = app.(sprintf(gui_strings.dd, 1)).Parent;
            end

            switch action
                case {'⮝', 'up'}
                    if target_dd.Layout.Row > 1
                        old_value = target_dd.Value;
                        new_value = app.(sprintf(gui_strings.dd, target-1)).Value;

                        target_dd.Value = new_value;
                        app.(sprintf(gui_strings.dd, target-1)).Value = old_value;
                    end

                case {'⮟', 'down'}
                    if target_dd.Layout.Row < length(grid.RowHeight)-2
                        old_value = target_dd.Value;
                        new_value = app.(sprintf(gui_strings.dd, target+1)).Value;

                        target_dd.Value = new_value;
                        app.(sprintf(gui_strings.dd, target+1)).Value = old_value;
                    end
                    
                case {'🗑', 'delete'}
                    switch mode
                        case 'gui'
                            grid.RowHeight(target) = [];
                            target_dd.Value = "N/A";
                            target_dd.Enable = "off";
                            app.(sprintf(gui_strings.up, context.target)).Enable = "off";
                            app.(sprintf(gui_strings.down, context.target)).Enable = "off";
                            app.(sprintf(gui_strings.del, context.target)).Enable = "off";
                        case 'event'
                            check = uiconfirm(app.CELL_ID, sprintf("Are you sure you want to delete Channel #%.f (%s) from your file?", target, target_dd.Value), "NeuroPAL_ID", "Options",["Yes", "No"]);
        
                            switch check
                                case "Yes"
                                    target_dd.Value = "N/A";
                                    values = cellfun(@(d) app.(sprintf(gui_strings.dd, d)).Value, num2cell(1:6), 'UniformOutput', false);
                                    nonEmptyValues = values(~strcmp(values, "N/A"));
                                    emptyValues = values(strcmp(values, "N/A"));
                                    newOrder = [nonEmptyValues, emptyValues];
                                    
                                    for dd=1:6
                                        app.(sprintf(dd_string, dd)).Value = newOrder{dd};
        
                                        if strcmp(newOrder{dd}, "N/A")
                                            Program.GUIHandling.edit_channels(app, 'mode', 'gui', 'action', 'delete', 'target', dd);
                                        end
                                    end
        
                                    app.proc_apply_processing("delete_channel");
                                case "No"
                                    return
                            end
                    end

                case 'init'
                    if ~isempty(order)
                        channel_names = {Program.GUIHandling.channel_names{end/2+1:end}};
                        null_pad = 0;
                        for c=1:length(order)
                            if order(c) ~= 0 && isnan(order(c))
                                app.(sprintf(gui_strings.dd, c-null_pad)).Value = channel_names{c};
                            else
                                null_pad = null_pad + 1;
                            end
                        end

                        for n=1:length(null_pad)
                            Program.GUIHandling.edit_channels(app, 'mode', 'gui', 'action', 'delete', 'target', length(grid.RowHeight));
                        end
                    else
                        for c=1:count
                            app.(sprintf(gui_strings.dd, c)).Value = app.(sprintf(gui_strings.dd, c)).Items{c};
                        end
                    end
        
                    if count < 6
                        for dd=length(grid.RowHeight)-2:-1:count+1
                            Program.GUIHandling.edit_channels(app, 'mode', 'gui', 'action', 'delete', 'target', dd);
                        end
                    end
            end

            Program.GUIHandling.histogram_handler(app, 'draw');
        end

        function swap_volumes(app, event)
            if ~exist('event', 'var')
                mode = Program.GUIHandling.get_active_volume(app, 'request', 'state');
            else
                mode = lower(event.Value);
            end

            switch mode
                case 'colormap'
                    Program.GUIHandling.set_gui_limits(app, 'colormap');
                    Program.GUIHandling.set_thresholds(app, max(app.proc_image.data, [], "all"));

                    chunk_prefs = app.proc_image.prefs;
                    for c=1:app.video_info.nc
                        app.(sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c})).Value = chunk_prefs.gamma(c);
                    end
    
                    app.PlaceholderProcTimeline.Parent = app.CELL_ID;
                    app.PlaceholderProcTimeline.Visible = ~app.PlaceholderProcTimeline.Visible;
                    app.ProcAxGrid.RowHeight(end) = [];
                    app.ProcSideGrid.RowHeight = {148, 'fit', 175, 'fit', 212, '1x', 93};

                    app.ProcTStartEditField.Enable = 'off';
                    app.ProcTStopEditField.Enable = 'off';
                    app.TrimButton.Enable = 'off';
                    app.ProcDownsamplingGrid.RowHeight = {22, 22, 0, 18};

                case 'video'
                    Program.GUIHandling.set_gui_limits(app, 'video');
                    Program.GUIHandling.set_thresholds(app, max(app.retrieve_frame(app.proc_tSlider.Value), [], "all"));
                    
                    for c=1:app.video_info.nc
                        app.(sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c})).Value = 1;
                    end
                    
                    app.ProcAxGrid.RowHeight{end+1} = 'fit';
                    app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
                    app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
                    app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
                    app.PlaceholderProcTimeline.Visible = ~app.PlaceholderProcTimeline.Visible;

                    app.ProcSideGrid.RowHeight = {148, 'fit', 175, 'fit', 0, '1x', 93};

                    if app.ProcTStartEditField.Value == 0 || app.ProcTStopEditField.Value == 0
                        app.ProcTStartEditField.Value = app.proc_tSlider.Limits(1);
                        app.ProcTStopEditField.Value = app.proc_tSlider.Limits(2);
                    end

                    app.ProcTStartEditField.Enable = 'on';
                    app.ProcTStopEditField.Enable = 'on';
                    app.TrimButton.Enable = 'on';
                    app.ProcDownsamplingGrid.RowHeight = {22, 22, 22, 18};
            end

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
            app.ProcessingGridLayout.ColumnWidth = {'1x', 190};
        end

        function set_thresholds(app, max_val)
            new_limits = [1 max(2, max_val)];

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


        function draw_rotation_gui(app, roi)
            if ~isa(roi, 'images.roi.Freehand')
                roi = Program.GUIHandling.rect_to_freehand(roi);
            end

            symbols = {'↺', '⦝', '⦬', '☑'};
            sym_count = length(symbols);

            font_size = 20;
            stroke_size = 4;
            vertical_offset = 14;
            box_padding = [5 5];
            gap = [0, font_size + font_size/3];
            character_width = font_size + gap(1);

            if ~exist('flag', 'var')
                % ...delete previous rotation gui.
                for n = 1:length(app.rotation_stack)
                    delete(app.rotation_stack{n});
                end
                app.rotation_stack = {roi};
            end

            [~, tr_idx] = max(roi.Position(:,1) + roi.Position(:,2) * 1e-6);
            tr = roi.Position(tr_idx, :);
            
            bg_width = character_width * sym_count + stroke_size + box_padding(1);
            bg_height = font_size + stroke_size + box_padding(2);
            bg_xmin = tr(1) - bg_width;
            bg_ymin = min(roi.Position(:, 2)) - font_size - stroke_size/2 - vertical_offset;

            bg_pos = [
                [bg_xmin+bg_width, bg_ymin];
                [bg_xmin, bg_ymin];
                [bg_xmin, bg_ymin+bg_height];
                [bg_xmin+bg_width, bg_ymin+bg_height]];
            app.rotation_stack{end+1} = images.roi.Freehand(roi.Parent, 'Position', bg_pos, 'Color', [0.1 0.1 0.1], 'FaceAlpha', 0.7, ...
                'InteractionsAllowed', 'none', 'MarkerSize', 1e-99, 'LineWidth', 1e-99);

            for n = 1:sym_count
                symbol = symbols{n};
                symbol_x = bg_xmin + (character_width + stroke_size/2) * (n - 1) + box_padding(1) / 2;
                symbol_y = bg_ymin + character_width/2 + box_padding(2);

                app.rotation_stack{end+1} = text(roi.Parent, symbol_x, symbol_y, symbol, ...
                    'Color', 'white', ...
                    'FontName', 'MonoSpace', 'FontSize', font_size, 'FontWeight', 'bold', ...
                    'ButtonDownFcn', @(src, event) proc_rot(app, struct('obj', Program.GUIHandling.rotation_stack{end}, 'symbol', {symbol}, 'roi', {roi})));
            end

            addlistener(roi, 'MovingROI', @(src, event)Program.GUIHandling.update_rotation_gui(event));
        end


        function freehand_roi = rect_to_freehand(roi)
            xmin = roi.Position(1);
            ymin = roi.Position(2);
            width = roi.Position(3);
            height = roi.Position(4);

            tr = [xmin + width, ymin];
            tl = [xmin, ymin];
            bl = [xmin, ymin + height];
            br = [xmin + width, ymin + height];

            freehand_roi = images.roi.Freehand(roi.Parent, 'Position', [tr; tl; bl; br], ...
                'FaceAlpha', 0.4, 'Color', [0.1 0.1 0.1], 'StripeColor', 'm', 'InteractionsAllowed', 'translate', 'Tag', 'rot_roi');
            delete(roi)
        end

        function update_rotation_gui(app, event)
            [~, tr_idx] = max(event.PreviousPosition(:,1) + event.PreviousPosition(:,2) * 1e-6);
            old_tr = event.PreviousPosition(tr_idx, :);

            [~, tr_idx] = max(event.CurrentPosition(:,1) + event.CurrentPosition(:,2) * 1e-6);
            new_tr = event.CurrentPosition(tr_idx, :);

            xy_diff = old_tr - new_tr;

            for n = 1:length(app.rotation_stack)
                if ~strcmp(app.rotation_stack{n}.Tag, 'rot_roi')
                    app.rotation_stack{n}.Position(1:2) = app.rotation_stack{n}.Position(1:2) - xy_diff;
                end
            end
            
            %{
            xy_diff = event.PreviousPosition(1:2) - event.CurrentPosition(1:2);
            sz_diff = event.PreviousPosition(3:4) - event.CurrentPosition(3:4);

            if sz_diff(1) ~= 0 && xy_diff(1) == 0
                xy_diff(1) = sz_diff(1);
            elseif sz_diff(1) ~= 0 && xy_diff(1) ~= 0
                xy_diff(1) = 0;
            end

            for n = 1:length(app.rotation_stack)
                if ~contains(class(app.rotation_stack{n}), 'roi')
                    app.rotation_stack{n}.Position(1:2) = app.rotation_stack{n}.Position(1:2) - xy_diff;
                end
            end
            %}
        end


        function proc_rot(app, event)
            origin = app.mouse.pos(1);
            delta_debt = 0;
            cct = 1;

            while cct
                c_diff = app.mouse.pos(1) - origin + delta_debt;
                %fprintf("mouse pos: [%f %f] \norigin: [%f %f] \ndelta debt: [%f %f] \nc diff: [%f %f] \n\n", app.mouse.pos, origin, delta_debt, c_diff)
                delta_debt = delta_debt - c_diff;

                if c_diff ~=0 | ~strcmp(event.symbol, '↺')
                    switch event.symbol
                        case '↺'
                            theta = c_diff/4;
                        case '⦝'
                            theta = 90;
                        case '⦬'
                            theta = 45;
                        case '☑'
                            Program.GUIHandling.apply_routine(app, event.roi, event.roi.Parent);
                            return
                    end


                    roi_center = mean(event.roi.Position, 1);
                    R = [cosd(theta), -sind(theta); sind(theta), cosd(theta)];
                    for n = 1:length(app.rotation_stack)
                        if size(app.rotation_stack{n}.Position, 2) == 3
                            translated_position = app.rotation_stack{n}.Position(1:2) - roi_center;
                            app.rotation_stack{n}.Position(1:2) = (translated_position * R') + roi_center;
                            set(app.rotation_stack{n}, 'Rotation', theta);

                        else
                            translated_position = app.rotation_stack{n}.Position - roi_center;
                            app.rotation_stack{n}.Position = (translated_position * R') + roi_center;
                        end
                    end
                end

                drawnow;

                if strcmp(event.symbol, '↺') & app.mouse.state
                    cct = 1;
                else
                    cct = 0;
                end
            end
        end


        function apply_routine(app, roi, ax)
            % Get the current image from the axes
            imgHandle = findobj(ax, 'Type', 'image');
            img = imgHandle.CData;
            imgXData = imgHandle.XData;
            imgYData = imgHandle.YData;
        
            % Get the ROI corners (top-right, top-left, bottom-right, bottom-left)
            corners = roi.Position;
        
            % Calculate the angle of the top and bottom lines to detect rotation
            topLine = corners(1, :) - corners(2, :);
            bottomLine = corners(3, :) - corners(4, :);
        
            % Average of the angles of both lines (we assume ROI should be axis-aligned)
            angleTop = atan2(topLine(2), topLine(1));
            angleBottom = atan2(bottomLine(2), bottomLine(1));
            avgAngle = (angleTop + angleBottom) / 2;
        
            % Compute the center of the ROI for rotation reference
            centerX = mean(corners(:, 1));
            centerY = mean(corners(:, 2));
            rotationAngle = -avgAngle * 180 / pi; % Convert radians to degrees for imrotate
        
            % Rotate the image around the center of the ROI
            rotatedImg = imrotate(img, rotationAngle, 'bilinear', 'crop');
        
            % Rotate the ROI corners
            rotMatrix = [cos(avgAngle), -sin(avgAngle); sin(avgAngle), cos(avgAngle)];
            rotatedCorners = (corners - [centerX, centerY]) * rotMatrix' + [centerX, centerY];
        
            % Define the bounding box for the rotated ROI (axis-aligned)
            xMin = max(min(rotatedCorners(:, 1)), imgXData(1));
            xMax = min(max(rotatedCorners(:, 1)), imgXData(2));
            yMin = max(min(rotatedCorners(:, 2)), imgYData(1));
            yMax = min(max(rotatedCorners(:, 2)), imgYData(2));
        
            % Crop the rotated image to the bounding box
            croppedImg = rotatedImg(round(yMin:yMax), round(xMin:xMax), :);
        
            % Update the image data on the axes
            set(imgHandle, 'CData', croppedImg);
            set(imgHandle, 'XData', [xMin, xMax]);
            set(imgHandle, 'YData', [yMin, yMax]);
        
            % Adjust the axes limits to zoom into the cropped image
            xlim(ax, [xMin, xMax]);
            ylim(ax, [yMin, yMax]);
            set(ax, 'DataAspectRatio', [1, 1, 1]);

            for n = 1:length(app.rotation_stack)
                delete(app.rotation_stack{n});
            end
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