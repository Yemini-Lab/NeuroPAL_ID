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
            'SigmagaussEditFieldLabel', ...
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
            'DropperradiusSpinner', ...
            'DropperRadiusEditFieldLabel', ...
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
            figure_size = Program.GUIHandling.constrain_app_window_position(figure_size);
            app.CELL_ID.Position = figure_size;

            Program.GUIHandling.prepare_unloaded_module_views(app);

            Program.GUIHandling.install_processing_resize_callback(app);
            Program.GUIHandling.install_main_processing_sync_callbacks(app);
            Program.GUIHandling.apply_processing_responsive_layout(app);
        end

        function prepare_unloaded_module_views(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isempty(app) || ~isvalid(app)
                return
            end

            Program.GUIHandling.hide_startup_load_buttons(app);

            if isprop(app, 'IdGridLayout') && isvalid(app.IdGridLayout)
                set(app.IdGridLayout, 'Visible', 'on');
            end
            if isprop(app, 'ProcessingGridLayout') && isvalid(app.ProcessingGridLayout)
                set(app.ProcessingGridLayout, 'Visible', 'on');
            end
            if isprop(app, 'VideoGridLayout') && isvalid(app.VideoGridLayout)
                set(app.VideoGridLayout, 'Visible', 'on');
            end
        end

        function hide_startup_load_buttons(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isempty(app) || ~isvalid(app)
                return
            end

            button_names = {'ProcessingButton', 'IdButton', 'TrackingButton'};
            for n = 1:numel(button_names)
                name = button_names{n};
                if ~isprop(app, name) || isempty(app.(name)) || ~isvalid(app.(name))
                    continue
                end

                if isprop(app.(name), 'Enable')
                    app.(name).Enable = 'off';
                end
                if isprop(app.(name), 'Visible')
                    app.(name).Visible = 'off';
                end
            end
        end

        function tf = processing_tab_rendered(app)
            tf = false;
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isempty(app) || ~isvalid(app) || ...
                    ~isprop(app, 'ImageProcessingTab') || isempty(app.ImageProcessingTab) || ...
                    ~isvalid(app.ImageProcessingTab)
                return
            end

            tf = strcmpi(char(string(app.ImageProcessingTab.Tag)), 'rendered');
        end

        function install_main_processing_sync_callbacks(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isempty(app) || ~isvalid(app)
                return
            end

            targets = { ...
                'RDropDown', 'ValueChangedFcn'; ...
                'GDropDown', 'ValueChangedFcn'; ...
                'BDropDown', 'ValueChangedFcn'; ...
                'WDropDown', 'ValueChangedFcn'; ...
                'DICDropDown', 'ValueChangedFcn'; ...
                'GFPDropDown', 'ValueChangedFcn'; ...
                'RCheckBox', 'ValueChangedFcn'; ...
                'GCheckBox', 'ValueChangedFcn'; ...
                'BCheckBox', 'ValueChangedFcn'; ...
                'WCheckBox', 'ValueChangedFcn'; ...
                'DICCheckBox', 'ValueChangedFcn'; ...
                'GFPCheckBox', 'ValueChangedFcn'; ...
                'ZSlider', 'ValueChangedFcn'; ...
                'ZAxisDropDown', 'ValueChangedFcn'; ...
                'ZCenterEditField', 'ValueChangedFcn'; ...
                'FlipZButton', 'ButtonPushedFcn'; ...
                'DownsampleImageMenu', 'MenuSelectedFcn'; ...
                'ThresholdImageMenu', 'MenuSelectedFcn'; ...
                'HistogramMatchingMenu', 'MenuSelectedFcn'; ...
                'NormalizeColorsMenu', 'MenuSelectedFcn'; ...
                'SpectralUnmixingMenu', 'MenuSelectedFcn'; ...
                'AllChannels', 'MenuSelectedFcn'; ...
                'IndividualChannels', 'MenuSelectedFcn'; ...
                'AdjustHistogramMenu', 'MenuSelectedFcn'; ...
                'RotateAllHorizontalMenu', 'MenuSelectedFcn'; ...
                'RotateAllVerticalMenu', 'MenuSelectedFcn'; ...
                'RotateAllClockwiseMenu', 'MenuSelectedFcn'; ...
                'RotateAllAntiClockwiseMenu', 'MenuSelectedFcn'; ...
                'RotateImageHorizontalMenu', 'MenuSelectedFcn'; ...
                'RotateImageVerticalMenu', 'MenuSelectedFcn'; ...
                'RotateImageClockwiseMenu', 'MenuSelectedFcn'; ...
                'RotateImageAntiClockwiseMenu', 'MenuSelectedFcn'};

            for n = 1:size(targets, 1)
                Program.GUIHandling.wrap_main_processing_sync_callback( ...
                    app, targets{n, 1}, targets{n, 2});
            end
        end

        function wrap_main_processing_sync_callback(app, component_name, callback_name)
            if ~isprop(app, component_name)
                return
            end

            component = app.(component_name);
            if isempty(component) || ~isvalid(component) || ~isprop(component, callback_name)
                return
            end

            install_key = sprintf('main_proc_sync_%s_installed', callback_name);
            legacy_key = sprintf('main_proc_sync_%s_legacy', callback_name);
            if isappdata(component, install_key) && logical(getappdata(component, install_key))
                return
            end

            setappdata(component, install_key, true);
            setappdata(component, legacy_key, component.(callback_name));
            component.(callback_name) = @(src, event) ...
                Program.GUIHandling.execute_main_processing_sync_callback( ...
                    app, component, callback_name, src, event);
        end

        function execute_main_processing_sync_callback(app, component, callback_name, src, event)
            legacy_key = sprintf('main_proc_sync_%s_legacy', callback_name);
            legacy_callback = [];
            if isappdata(component, legacy_key)
                legacy_callback = getappdata(component, legacy_key);
            end

            guard_key = 'main_proc_sync_guard';
            if isappdata(app.CELL_ID, guard_key) && logical(getappdata(app.CELL_ID, guard_key))
                Program.GUIHandling.invoke_gui_callback(legacy_callback, src, event);
                return
            end

            setappdata(app.CELL_ID, guard_key, true);
            cleanup = onCleanup(@() setappdata(app.CELL_ID, guard_key, false));

            Program.GUIHandling.invoke_gui_callback(legacy_callback, src, event);
            Program.GUIHandling.sync_processing_after_main_change(app);
        end

        function invoke_gui_callback(callback_handle, src, event)
            if isempty(callback_handle)
                return
            end

            if isa(callback_handle, 'function_handle')
                callback_handle(src, event);
                return
            end

            if iscell(callback_handle) && ~isempty(callback_handle)
                feval(callback_handle{1}, src, event, callback_handle{2:end});
                return
            end

            feval(callback_handle, src, event);
        end

        function sync_processing_after_main_change(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isempty(app) || ~isvalid(app) || isempty(app.image_data)
                return
            end

            if Program.GUIHandling.processing_tab_rendered(app) && ...
                    strcmpi(char(string(app.VolumeDropDown.Value)), 'Colormap')
                Program.GUIHandling.hide_percentile_noise_editor(app);
                Program.GUIHandling.clear_processing_preview_cache(app);
                Program.Helpers.sync_processing_from_main(app, app.image_file);
                Program.GUIHandling.update_processing_downsample_field_limits(app);
                Program.GUIHandling.update_processing_histogram_interactivity(app);
                Program.GUIHandling.update_processing_threshold_target_options(app);
                Program.Routines.Processing.render();
            end

            Program.Routines.ID.render();
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
                    Program.GUIHandling.set_descendant_enable_state(app.IdGridLayout, state);
                    Program.GUIHandling.gui_lock(app, state, 'neuron_gui');

                case 'processing_tab'
                    gui_components = Program.GUIHandling.proc_components;
                    Program.GUIHandling.set_descendant_enable_state(app.ProcessingGridLayout, state);

                    for pos=1:length(Program.GUIHandling.pos_prefixes)
                        app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos})).Enable = state;
                        app.(sprintf('%s_GammaEditField', Program.GUIHandling.pos_prefixes{pos})).Enable = state;
                    end

                    Program.GUIHandling.set_threshold_stepper_state(app, state);

                case 'video_tab'
                    gui_components = {};
                    Program.GUIHandling.set_descendant_enable_state(app.VideoGridLayout, state);

            end

            for comp=1:length(gui_components)
                app.(gui_components{comp}).Enable = state;
            end

            if strcmp(group, 'processing_tab')
                Program.GUIHandling.update_processing_histogram_interactivity(app);
            end

            if exist('event', 'var')
                event.Source.Enable = 'on';
            end
        end

        function set_descendant_enable_state(root, state)
            if nargin < 2 || isempty(root) || ~isvalid(root)
                return
            end

            try
                descendants = [root; findall(root)];
            catch
                descendants = root;
            end

            for n = 1:numel(descendants)
                component = descendants(n);
                if isempty(component) || ~isvalid(component) || ~isprop(component, 'Enable')
                    continue
                end

                try
                    component.Enable = state;
                catch
                end
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
            applied = Program.Helpers.apply_processing_preview_action(app, action);
            if ~applied
                return
            end

            Program.Routines.GUI.set_manipulation_panel('closed');
        end

        function histogram_handler(app, mode, image)
            %#ok<INUSD>
            switch lower(string(mode))
                case "reset"
                    Program.Handlers.histograms.reset();
                case "draw"
                    Program.Handlers.histograms.draw();
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
            
            x = min(max(round(app.proc_xSlider.Value), 1), app.proc_xSlider.Limits(2));
            y = min(max(round(app.proc_ySlider.Value), 1), app.proc_ySlider.Limits(2));
            z = min(max(round(app.proc_zSlider.Value), 1), app.proc_zSlider.Limits(2));
            channel_state = Program.Handlers.channels.processing_state(app);
            c_bools = channel_state.enabled_source_indices;
            c_max = channel_state.max_source_idx;
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
                    source_array = [];
                    prefs = struct();
                    if strcmp(app.VolumeDropDown.Value, 'Colormap')
                        context = Program.Helpers.processing_colormap_context(app);
                        source_array = context.volume;
                        prefs = context.prefs;
                    end

                    if app.ProcShowMIPCheckBox.Value
                        switch app.VolumeDropDown.Value
                            case 'Colormap'
                                safe_c = Program.Validation.noskip_index(c_max);
                                if isempty(source_array)
                                    slice = zeros(0, 0, 0, safe_c);
                                else
                                    c_load = c_load(c_load <= size(source_array, 4));
                                    slice = source_array(:, :, :, c_load);
                                end
                            case 'Video'
                                slice = app.retrieve_frame(package.coords(4));
                        end
                    else
                        switch app.VolumeDropDown.Value
                            case 'Colormap'
                                [~, ~, nz_data, ~] = size(source_array);
                                z_gui = Program.Helpers.gui_z_to_data_index(package.coords(3), nz_data, false);
                                z_idx = Program.Helpers.gui_z_to_data_index( ...
                                    z_gui, nz_data, ...
                                    isfield(prefs, 'is_Z_flip') && prefs.is_Z_flip);
                                c_load = c_load(c_load <= size(source_array, 4));
                                slice = source_array(:, :, z_idx, c_load);
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

                    rgb = [ ...
                        channel_state.r.source_idx, ...
                        channel_state.g.source_idx, ...
                        channel_state.b.source_idx];
                    missing_rgb = rgb(~ismember(rgb, c_load));
                    slice(:, :, :, missing_rgb) = 0;
                    slice(:, :, :, [find(~ismember(c_load, c_bools))]) = 0;
                    package.array = slice;

                case 'coords'
                    package.coords(1) = min(max(round(package.dims(1)-app.proc_ySlider.Value), 1), app.proc_ySlider.Limits(2));

            end

            Program.Handlers.loading.done();
        end

        function tf = processing_colormap_available(app)
            tf = false;

            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if ~isempty(app.image_data)
                tf = true;
                return
            end

            try
                if isa(app.proc_image, 'matlab.io.MatFile')
                    size(app.proc_image, 'data');
                    tf = true;
                    return
                end
            catch
            end

            try
                image_path = string(app.image_file);
                if strlength(image_path) > 0
                    image_path = char(image_path);
                    if isfile(image_path)
                        tf = true;
                        return
                    end

                    [filepath, name, ext] = fileparts(image_path);
                    if ~strcmpi(ext, '.mat') && isfile(fullfile(filepath, [name, '.mat']))
                        tf = true;
                        return
                    end
                end
            catch
            end

            try
                tf = isfield(app.data_flags, 'NeuroPAL_Volume') && logical(app.data_flags.('NeuroPAL_Volume'));
            catch
            end
        end

        function tf = processing_video_available(app)
            tf = false;

            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            try
                info = app.video_info;
            catch
                info = [];
            end

            if isempty(info) || ~isstruct(info)
                return
            end

            required_fields = {'nx', 'ny', 'nz', 'nt', 'nc'};
            if ~all(isfield(info, required_fields))
                return
            end

            dims = double([info.nx, info.ny, info.nz, info.nt, info.nc]);
            if any(~isfinite(dims)) || any(dims < 1)
                return
            end

            if isfield(info, 'file')
                try
                    tf = strlength(string(info.file)) > 0;
                catch
                    tf = ~isempty(info.file);
                end
            else
                tf = true;
            end
        end

        function [items, default_mode] = processing_volume_dropdown_items(app)
            has_image = Program.GUIHandling.processing_colormap_available(app);
            has_video = Program.GUIHandling.processing_video_available(app);

            items = {};
            if has_image
                items{end+1} = 'Colormap'; %#ok<AGROW>
            end

            if has_image || has_video
                items{end+1} = 'Video'; %#ok<AGROW>
            end

            if isempty(items)
                items = {'Colormap'};
            end

            if has_image
                default_mode = 'Colormap';
            elseif has_video
                default_mode = 'Video';
            else
                default_mode = items{1};
            end
        end

        function mode = refresh_processing_volume_dropdown(app, preferred_mode)
            if nargin < 2 || isempty(preferred_mode)
                try
                    preferred_mode = char(string(app.VolumeDropDown.Value));
                catch
                    preferred_mode = '';
                end
            end

            [items, default_mode] = Program.GUIHandling.processing_volume_dropdown_items(app);
            app.VolumeDropDown.Items = items;

            if any(strcmpi(preferred_mode, items))
                match_idx = find(strcmpi(preferred_mode, items), 1, 'first');
                mode = char(items{match_idx});
            else
                mode = default_mode;
            end

            app.VolumeDropDown.Value = mode;
        end

        function [mode, is_available, unavailable_message] = resolve_processing_volume_request(app, requested_mode)
            if nargin < 2 || isempty(requested_mode)
                requested_mode = 'Colormap';
            end

            requested_mode = lower(char(string(requested_mode)));
            has_image = Program.GUIHandling.processing_colormap_available(app);
            has_video = Program.GUIHandling.processing_video_available(app);

            switch requested_mode
                case 'video'
                    is_available = has_video;
                    unavailable_message = 'No video data is loaded for the current file.';
                    if has_image
                        mode = 'colormap';
                    else
                        mode = 'video';
                    end

                otherwise
                    is_available = has_image;
                    unavailable_message = 'No colormap image data is loaded for the current file.';
                    if has_image
                        mode = 'colormap';
                    elseif has_video
                        mode = 'video';
                    else
                        mode = 'colormap';
                    end
            end
        end


        function install_processing_slider_callbacks(app)
            Program.GUIHandling.install_processing_zslider_callbacks(app);
            Program.GUIHandling.install_processing_downsample_callbacks(app);
            Program.GUIHandling.update_processing_zslider_visibility(app);
        end

        function install_processing_zslider_callbacks(app)
            Program.GUIHandling.clear_processing_zslider_event_listeners(app);

            app.proc_zSlider.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_primary_zslider_change(app, event.Value, false);
            app.proc_hor_zSlider.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_horizontal_zslider_change(app, event.Value, false);
            app.proc_vert_zSlider.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_vertical_zslider_change(app, event.Value, false);

            if isprop(app.proc_zSlider, 'ValueChangingFcn')
                app.proc_zSlider.ValueChangingFcn = @(src, event) [];
            end
            if isprop(app.proc_hor_zSlider, 'ValueChangingFcn')
                app.proc_hor_zSlider.ValueChangingFcn = @(src, event) [];
            end
            if isprop(app.proc_vert_zSlider, 'ValueChangingFcn')
                app.proc_vert_zSlider.ValueChangingFcn = @(src, event) [];
            end

            listeners = struct( ...
                'primary', addlistener(app.proc_zSlider, 'ValueChanging', @(src, event) ...
                    Program.GUIHandling.handle_processing_primary_zslider_change(app, event.Value, true)), ...
                'horizontal', addlistener(app.proc_hor_zSlider, 'ValueChanging', @(src, event) ...
                    Program.GUIHandling.handle_processing_horizontal_zslider_change(app, event.Value, true)), ...
                'vertical', addlistener(app.proc_vert_zSlider, 'ValueChanging', @(src, event) ...
                    Program.GUIHandling.handle_processing_vertical_zslider_change(app, event.Value, true)));
            setappdata(app.CELL_ID, 'proc_zslider_event_listeners', listeners);
        end

        function clear_processing_zslider_event_listeners(app)
            if ~isappdata(app.CELL_ID, 'proc_zslider_event_listeners')
                return
            end

            listeners = getappdata(app.CELL_ID, 'proc_zslider_event_listeners');
            if isstruct(listeners)
                names = fieldnames(listeners);
                for n = 1:numel(names)
                    listener = listeners.(names{n});
                    if isempty(listener)
                        continue
                    end
                    try
                        delete(listener);
                    catch
                    end
                end
            end
            rmappdata(app.CELL_ID, 'proc_zslider_event_listeners');
        end

        function suspend_processing_zslider_callbacks(app, tf)
            if nargin < 2 || tf
                setappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks', true);
            elseif isappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks')
                rmappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks');
            end
        end

        function tf = processing_zslider_callbacks_suspended(app)
            tf = isappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks') && ...
                logical(getappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks'));
        end

        function handle_processing_primary_zslider_change(app, value, is_live)
            z_value = Program.GUIHandling.clamp_processing_zslider_value(app, value);
            Program.GUIHandling.handle_processing_zslider_change(app, z_value, is_live);
        end

        function handle_processing_horizontal_zslider_change(app, value, is_live)
            z_value = Program.GUIHandling.clamp_processing_zslider_value(app, value);
            Program.GUIHandling.handle_processing_zslider_change(app, z_value, is_live);
        end

        function handle_processing_vertical_zslider_change(app, value, is_live)
            value = Program.GUIHandling.clamp_processing_zslider_value(app, value);
            z_limits = double(app.proc_vert_zSlider.Limits);
            z_value = min(max(round(z_limits(2) - value), z_limits(1)), z_limits(2));
            Program.GUIHandling.handle_processing_zslider_change(app, z_value, is_live);
        end

        function z_value = clamp_processing_zslider_value(app, value)
            z_limits = double(app.proc_zSlider.Limits);
            z_value = min(max(round(double(value)), z_limits(1)), z_limits(2));
        end

        function handle_processing_zslider_change(app, z_value, is_live)
            if nargin < 3
                is_live = false;
            end

            if Program.GUIHandling.processing_zslider_callbacks_suspended(app)
                return
            end

            if is_live && isappdata(app.CELL_ID, 'proc_live_z_value')
                previous_live_z = getappdata(app.CELL_ID, 'proc_live_z_value');
                if isequal(previous_live_z, z_value)
                    return
                end
            end

            Program.GUIHandling.sync_processing_zcontrols(app, z_value);
            if ~isempty(app.image_data)
                current_z = min(max(round(z_value), 1), size(app.image_data, 3));
                Program.Helpers.configure_main_zslider(app, size(app.image_data, 3), current_z);
                app.ZSlider.Value = current_z;
                if isprop(app, 'ZSliderS') && isvalid(app.ZSliderS)
                    app.ZSliderS.Limits = [1, size(app.image_data, 3)];
                    app.ZSliderS.Value = current_z;
                end
                if ~is_live && ~isempty(app.image_view)
                    Program.Routines.ID.get_slice(app.ZSlider, app.image_view, app.XY);
                end
            end

            if is_live
                setappdata(app.CELL_ID, 'proc_live_z_value', z_value);
                Program.Routines.Processing.render_live_slice();
                drawnow limitrate nocallbacks;
            else
                if isappdata(app.CELL_ID, 'proc_live_z_value')
                    rmappdata(app.CELL_ID, 'proc_live_z_value');
                end
                Program.Routines.Processing.render();
            end
        end

        function sync_processing_zcontrols(app, z_value)
            z_limits = double(app.proc_zSlider.Limits);
            z_value = min(max(round(double(z_value)), z_limits(1)), z_limits(2));
            vert_limits = double(app.proc_vert_zSlider.Limits);
            vert_value = min(max(round(vert_limits(2) - z_value), vert_limits(1)), vert_limits(2));

            if app.proc_zSlider.Value ~= z_value
                app.proc_zSlider.Value = z_value;
            end
            if app.proc_hor_zSlider.Value ~= z_value
                app.proc_hor_zSlider.Value = z_value;
            end
            if app.proc_vert_zSlider.Value ~= vert_value
                app.proc_vert_zSlider.Value = vert_value;
            end
            if app.proc_zEditField.Value ~= z_value
                app.proc_zEditField.Value = z_value;
            end
        end

        function install_processing_downsample_callbacks(app)
            Program.GUIHandling.update_processing_downsample_field_limits(app);
            Program.GUIHandling.sanitize_processing_downsample_fields(app);

            app.ProcXYFactorUpdateButton.ButtonPushedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_downsample_update(app);
            app.ProcXYFactorEditField.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_downsample_field_changed(app);
            app.ProcZSlicesEditField.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_downsample_field_changed(app);
        end

        function handle_processing_downsample_update(app)
            drawnow;
            request = Program.GUIHandling.sanitize_processing_downsample_fields(app);
            if request.is_identity
                Program.GUIHandling.restore_identity_downsample_preview(app, request);
            else
                Program.Routines.Processing.save_prompt('ds');
            end

            Program.Routines.GUI.set_manipulation_panel('closed');
        end

        function handle_processing_downsample_field_changed(app)
            request = Program.GUIHandling.sanitize_processing_downsample_fields(app);
            Program.GUIHandling.restore_identity_downsample_preview(app, request);
        end

        function request = sanitize_processing_downsample_fields(app)
            dims3 = Program.GUIHandling.processing_source_dims(app);
            Program.GUIHandling.update_processing_downsample_field_limits(app, dims3);
            request = Methods.ChunkyMethods.proc_downsample_request(app, dims3);

            app.ProcXYFactorEditField.Value = request.xy_factor;
            app.ProcZSlicesEditField.Value = request.z_target;
        end

        function update_processing_downsample_field_limits(app, dims3)
            if nargin < 2 || isempty(dims3)
                dims3 = Program.GUIHandling.processing_source_dims(app);
            end

            min_xy_factor = 1 / max(dims3(1:2));
            app.ProcXYFactorEditField.Limits = [min_xy_factor, 1];
            app.ProcXYFactorEditField.ValueDisplayFormat = '%.4g';

            app.ProcZSlicesEditField.Limits = [1, max(1, dims3(3))];
            app.ProcZSlicesEditField.RoundFractionalValues = 'on';
            app.ProcZSlicesEditField.ValueDisplayFormat = '%.0f';
        end

        function clear_processing_preview_cache(app)
            cache_keys = { ...
                'proc_mip_cache', ...
                'proc_live_mip_cache', ...
                'proc_view_cache', ...
                'proc_render_cache', ...
                'proc_histogram_signature', ...
                'proc_render_view_dims', ...
                'proc_live_z_value'};

            for n = 1:numel(cache_keys)
                key = cache_keys{n};
                if isappdata(app.CELL_ID, key)
                    rmappdata(app.CELL_ID, key);
                end
            end
        end

        function restored = restore_identity_downsample_preview(app, request)
            if nargin < 2 || isempty(request)
                request = Program.GUIHandling.sanitize_processing_downsample_fields(app);
            end

            restored = false;
            if ~isfield(request, 'is_identity') || ~request.is_identity
                return
            end

            needs_restore = isfield(app.flags, 'ds');
            if ~needs_restore && isappdata(app.CELL_ID, 'proc_render_view_dims')
                render_dims = getappdata(app.CELL_ID, 'proc_render_view_dims');
                source_dims = Program.GUIHandling.processing_source_dims(app);
                needs_restore = numel(render_dims) >= 3 && ...
                    any(double(render_dims(1:3)) ~= double(source_dims(1:3)));
            end

            if ~needs_restore
                return
            end

            if isfield(app.flags, 'ds')
                app.flags = rmfield(app.flags, 'ds');
            end

            Program.GUIHandling.clear_processing_preview_cache(app);
            Program.Routines.Processing.render();
            drawnow limitrate nocallbacks;
            restored = true;
        end

        function dims3 = processing_source_dims(app)
            switch char(string(app.VolumeDropDown.Value))
                case 'Colormap'
                    dims = Program.Helpers.processing_colormap_context(app).dims;
                case 'Video'
                    dims = [app.video_info.ny, app.video_info.nx, app.video_info.nz];
                otherwise
                    dims = [1, 1, 1];
            end

            dims3 = max(1, round(double(dims(1:3))));
        end

        function install_processing_histogram_callbacks(app)
            app.HidezerointensitypixelsCheckBox.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_histogram_toggle(app);
            for n = 1:length(app.proc_channel_grid.RowHeight)
                cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, n);
                dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, n);
                if isprop(app, cb_handle) && isvalid(app.(cb_handle))
                    app.(cb_handle).ValueChangedFcn = @(src, event) ...
                        Program.GUIHandling.handle_processing_channel_toggle(app);
                end
                if isprop(app, dd_handle) && isvalid(app.(dd_handle))
                    app.(dd_handle).ValueChangedFcn = @(src, event) ...
                        Program.GUIHandling.handle_processing_channel_assignment_changed(app, src, event, 'pp_dd');
                end
                if n >= 4
                    ref_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, n);
                    if isprop(app, ref_handle) && isvalid(app.(ref_handle))
                        app.(ref_handle).ValueChangedFcn = @(src, event) ...
                            Program.GUIHandling.handle_processing_channel_assignment_changed(app, src, event, 'pp_ref');
                    end
                end
            end
            Program.GUIHandling.install_processing_window_controls(app);
            Program.GUIHandling.install_processing_commit_callbacks(app);
            for n = 1:length(Program.GUIHandling.pos_prefixes)
                prefix = Program.GUIHandling.pos_prefixes{n};
                slider = app.(sprintf('%s_hist_slider', prefix));
                Program.GUIHandling.configure_processing_histogram_slider(slider);
                slider.ValueChangedFcn = @(src, event) ...
                    Program.GUIHandling.handle_processing_histogram_slider(app, prefix, src.Value, true, true);
                if isprop(slider, 'ValueChangingFcn')
                    slider.ValueChangingFcn = @(src, event) ...
                        Program.GUIHandling.handle_processing_histogram_slider(app, prefix, event.Value, true, false);
                end
                Program.GUIHandling.sync_processing_window_fields(app, prefix);
            end

            Program.GUIHandling.update_processing_threshold_target_options(app);
            Program.GUIHandling.apply_processing_responsive_layout(app);
        end

        function install_processing_action_callbacks(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isprop(app, 'ProcNormalizeColorsButton') && isvalid(app.ProcNormalizeColorsButton)
                app.ProcNormalizeColorsButton.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.apply_processing_runtime_action(app, 'zscore');
            end
            if isprop(app, 'ProcHistogramMatchingButton') && isvalid(app.ProcHistogramMatchingButton)
                app.ProcHistogramMatchingButton.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.apply_processing_runtime_action(app, 'histmatch');
            end
            if isprop(app, 'ProcCropImageButton') && isvalid(app.ProcCropImageButton)
                app.ProcCropImageButton.ButtonPushedFcn = @(src, event) ...
                    Program.Routines.Processing.crop();
            end
            if isprop(app, 'ProcSaveButton') && isvalid(app.ProcSaveButton)
                app.ProcSaveButton.ButtonPushedFcn = @(src, event) ...
                    Program.Routines.Processing.save();
            end
            if isprop(app, 'ProcResetButton') && isvalid(app.ProcResetButton)
                app.ProcResetButton.ButtonPushedFcn = @(src, event) ...
                    Program.Routines.Processing.reset();
            end
            if isprop(app, 'ProcShowMIPCheckBox') && isvalid(app.ProcShowMIPCheckBox)
                app.ProcShowMIPCheckBox.ValueChangedFcn = @(src, event) ...
                    Program.GUIHandling.handle_processing_mip_toggled(app);
            end
            if isprop(app, 'VolumeDropDown') && isvalid(app.VolumeDropDown)
                app.VolumeDropDown.ValueChangedFcn = @(src, event) ...
                    Program.GUIHandling.handle_processing_volume_changed(app, event);
            end
        end

        function apply_processing_runtime_action(app, action)
            if nargin < 2 || strlength(string(action)) == 0
                return
            end

            Program.Routines.Processing.save_prompt(action);
        end

        function handle_processing_mip_toggled(app)
            Program.GUIHandling.hide_percentile_noise_editor(app);
            Program.GUIHandling.update_processing_zslider_visibility(app);
            Program.GUIHandling.clear_processing_preview_cache(app);
            Program.Routines.Processing.render();
        end

        function handle_processing_volume_changed(app, event)
            Program.Handlers.loading.start('Swapping volumes...');
            cleanup = onCleanup(@() Program.Handlers.loading.done());
            Program.GUIHandling.hide_percentile_noise_editor(app);
            Program.GUIHandling.swap_volumes(app, event);
            Program.GUIHandling.update_processing_threshold_target_options(app);
            Program.Routines.Processing.render();
        end

        function ensure_processing_color_ui(app)
            if nargin < 1
                app = Program.app;
            end

            Program.GUIHandling.install_processing_resize_callback(app);
            Program.GUIHandling.install_processing_histogram_callbacks(app);
            Program.GUIHandling.install_processing_action_callbacks(app);
            Program.GUIHandling.configure_processing_color_panel(app);
            Program.GUIHandling.configure_spectral_unmixing_controls(app);
            Program.GUIHandling.apply_processing_responsive_layout(app);
        end

        function configure_spectral_unmixing_controls(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            tooltip = ['Radius in pixels for the disk-shaped ROI averaged by the spectral eyedropper. ' ...
                'Minimum value is 1.'];

            if isprop(app, 'DropperradiusSpinner') && isvalid(app.DropperradiusSpinner)
                app.DropperradiusSpinner.Editable = 'on';
                if isprop(app.DropperradiusSpinner, 'RoundFractionalValues')
                    app.DropperradiusSpinner.RoundFractionalValues = 'on';
                end
                if isprop(app.DropperradiusSpinner, 'Limits')
                    app.DropperradiusSpinner.Limits = [1 Inf];
                end
                if ~isfinite(double(app.DropperradiusSpinner.Value)) || double(app.DropperradiusSpinner.Value) < 1
                    app.DropperradiusSpinner.Value = 1;
                end
                app.DropperradiusSpinner.Tooltip = tooltip;
            end

            if isprop(app, 'DropperRadiusEditFieldLabel') && isvalid(app.DropperRadiusEditFieldLabel)
                app.DropperRadiusEditFieldLabel.Tooltip = tooltip;
            end
        end

        function set_processing_spectral_unmixing_state(app, enabled)
            if nargin < 2
                enabled = true;
            end

            Program.GUIHandling.configure_spectral_unmixing_controls(app);

            if enabled
                desired_state = 'on';
            else
                desired_state = 'off';
            end

            if isprop(app, 'SpectralUnmixingGrid') && isvalid(app.SpectralUnmixingGrid)
                components = [app.SpectralUnmixingGrid; findall(app.SpectralUnmixingGrid)];
                for comp = 1:numel(components)
                    component = components(comp);
                    if isprop(component, 'Enable')
                        component.Enable = desired_state;
                    end
                end
            end

            if isprop(app, 'DropperradiusSpinner') && isvalid(app.DropperradiusSpinner)
                app.DropperradiusSpinner.Editable = desired_state;
            end
        end

        function handle_processing_histogram_toggle(app)
            setappdata(app.CELL_ID, 'proc_histogram_signature', ...
                Program.Helpers.processing_histogram_signature(app));
            Program.Handlers.histograms.draw();
            drawnow limitrate nocallbacks;
        end

        function handle_processing_channel_toggle(app)
            Program.GUIHandling.update_processing_histogram_interactivity(app);
            Program.GUIHandling.update_processing_threshold_target_options(app);
            Program.Helpers.sync_main_display_from_processing(app, false);
            Program.Routines.Processing.render();
            Program.Routines.ID.render();
        end

        function handle_processing_channel_assignment_changed(app, source, event, group_key)
            rendered_processing = false;
            if nargin >= 4 && ~isempty(group_key)
                Program.Helpers.dd_sync( ...
                    source, ...
                    event.PreviousValue, ...
                    event.Value, ...
                    Program.Handlers.channels.handles{group_key});
                rendered_processing = true;
            end
            Program.GUIHandling.update_processing_histogram_interactivity(app);
            Program.GUIHandling.update_processing_threshold_target_options(app);
            setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
            Program.Helpers.sync_main_display_from_processing(app, false);
            if ~rendered_processing
                Program.Routines.Processing.render();
            end
            Program.Routines.ID.render();
        end

        function handle_processing_gamma_changed(app)
            setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
            Program.Helpers.sync_main_display_from_processing(app, false);
            Program.Routines.Processing.render();
            Program.Routines.ID.render();
        end

        function install_processing_commit_callbacks(app)
            if isprop(app, 'confirm_rotation') && isvalid(app.confirm_rotation)
                app.confirm_rotation.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.confirm_processing_rotation(app);
            end
        end

        function confirm_processing_rotation(app)
            rotate_actions = {};

            if app.flip_lr.Value
                rotate_actions{end+1} = 'hori'; %#ok<AGROW>
            end
            if app.flip_ud.Value
                rotate_actions{end+1} = 'vert'; %#ok<AGROW>
            end
            if app.proc_rot_spinner.Value ~= 0
                rotate_actions{end+1} = 'rotate'; %#ok<AGROW>
            end

            if isempty(rotate_actions)
                app.proc_xyAxes.XLim(2) = app.proc_xSlider.Limits(2);
                app.proc_xyAxes.YLim(2) = app.proc_ySlider.Limits(2);
                Program.Routines.GUI.set_manipulation_panel('closed');
                return
            end

            applied = Program.Helpers.apply_processing_preview_action(app, rotate_actions);
            if ~applied
                return
            end

            Program.Routines.GUI.set_manipulation_panel('closed');
        end

        function configure_processing_histogram_slider(slider)
            if isempty(slider) || ~isvalid(slider)
                return
            end

            slider.MinorTicks = [];
            slider.MajorTicks = [];
            if isprop(slider, 'MajorTickLabels')
                slider.MajorTickLabels = {''};
            end
        end

        function install_processing_window_controls(app)
            prefixes = Program.GUIHandling.pos_prefixes;
            controls_by_prefix = struct();

            for n = 1:numel(prefixes)
                prefix = prefixes{n};
                gamma_field = app.(sprintf('%s_GammaEditField', prefix));
                gamma_field.ValueChangedFcn = @(src, event) ...
                    Program.GUIHandling.handle_processing_gamma_changed(app);
                header_grid = gamma_field.Parent;

                controls = Program.GUIHandling.processing_window_controls(app, prefix);
                if isempty(controls)
                    controls = struct();
                    controls.min_label = uilabel(header_grid, ...
                        'Text', 'Min', ...
                        'Tag', sprintf('proc_%s_min_label', prefix), ...
                        'HorizontalAlignment', 'right', ...
                        'Tooltip', 'Lower display/save bound for this channel (0-255).');
                    controls.min_field = uieditfield(header_grid, 'numeric', ...
                        'Tag', sprintf('proc_%s_min_field', prefix), ...
                        'Limits', [0 255], ...
                        'RoundFractionalValues', 'on', ...
                        'ValueDisplayFormat', '%.0f', ...
                        'Tooltip', 'Lower display/save bound for this channel (0-255).', ...
                        'ValueChangedFcn', @(src, event) ...
                            Program.GUIHandling.handle_processing_window_field_changed(app, prefix, 'min', src));
                    controls.max_label = uilabel(header_grid, ...
                        'Text', 'Max', ...
                        'Tag', sprintf('proc_%s_max_label', prefix), ...
                        'HorizontalAlignment', 'right', ...
                        'Tooltip', 'Upper display/save bound for this channel (0-255).');
                    controls.max_field = uieditfield(header_grid, 'numeric', ...
                        'Tag', sprintf('proc_%s_max_field', prefix), ...
                        'Limits', [0 255], ...
                        'RoundFractionalValues', 'on', ...
                        'ValueDisplayFormat', '%.0f', ...
                        'Tooltip', 'Upper display/save bound for this channel (0-255).', ...
                        'ValueChangedFcn', @(src, event) ...
                            Program.GUIHandling.handle_processing_window_field_changed(app, prefix, 'max', src));
                end

                controls_by_prefix.(matlab.lang.makeValidName(prefix)) = controls;
            end

            setappdata(app.CELL_ID, 'proc_window_controls', controls_by_prefix);
            Program.GUIHandling.apply_processing_responsive_layout(app);
        end

        function handle_processing_histogram_slider(app, prefix, value, redraw, sync_main)
            if nargin < 5
                sync_main = redraw;
            end

            slider = app.(sprintf('%s_hist_slider', prefix));
            value = Program.GUIHandling.clamp_processing_window_range(value);
            slider.Value = value;
            Program.GUIHandling.sync_processing_window_fields(app, prefix);
            Program.GUIHandling.sync_processing_threshold_field(app);
            if sync_main
                setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
                Program.Helpers.sync_main_display_from_processing(app, false);
            end
            if redraw
                Program.Routines.Processing.render();
                if sync_main
                    Program.Routines.ID.render();
                end
                drawnow limitrate nocallbacks;
            end
        end

        function handle_processing_window_field_changed(app, prefix, bound, src)
            slider = app.(sprintf('%s_hist_slider', prefix));
            range = Program.GUIHandling.clamp_processing_window_range(slider.Value);
            value = min(max(round(double(src.Value)), 0), 255);

            switch lower(string(bound))
                case "min"
                    range(1) = value;
                    if range(2) < value
                        range(2) = value;
                    end
                case "max"
                    range(2) = value;
                    if range(1) > value
                        range(1) = value;
                    end
            end

            slider.Value = range;
            Program.GUIHandling.sync_processing_window_fields(app, prefix);
            Program.GUIHandling.sync_processing_threshold_field(app);
            setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
            Program.Helpers.sync_main_display_from_processing(app, false);
            Program.Routines.Processing.render();
            Program.Routines.ID.render();
        end

        function sync_processing_window_fields(app, prefix)
            controls = Program.GUIHandling.processing_window_controls(app, prefix);
            if isempty(controls)
                return
            end

            slider = app.(sprintf('%s_hist_slider', prefix));
            range = Program.GUIHandling.clamp_processing_window_range(slider.Value);
            controls.min_field.Value = range(1);
            controls.max_field.Value = range(2);

            enabled_state = 'on';
            if isprop(slider, 'Enable')
                enabled_state = slider.Enable;
            end
            controls.min_field.Enable = enabled_state;
            controls.max_field.Enable = enabled_state;
            if isprop(controls.min_label, 'Enable')
                controls.min_label.Enable = enabled_state;
            end
            if isprop(controls.max_label, 'Enable')
                controls.max_label.Enable = enabled_state;
            end
        end

        function update_processing_histogram_interactivity(app)
            if nargin < 1
                app = Program.app;
            end

            state = Program.Handlers.channels.processing_state(app);
            prefixes = Program.GUIHandling.pos_prefixes;
            base_state = Program.GUIHandling.processing_control_enable_state(app);

            for n = 1:numel(prefixes)
                row_enabled = false;
                if n <= numel(state.rows)
                    row = state.rows(n);
                    row_enabled = logical(row.enabled) && row.source_idx > 0;
                end

                desired_state = 'off';
                if strcmp(base_state, 'on') && row_enabled
                    desired_state = 'on';
                end

                Program.GUIHandling.set_processing_histogram_controls_enabled( ...
                    app, prefixes{n}, desired_state);
            end
        end

        function state = processing_control_enable_state(app)
            state = 'on';
            candidates = {'ProcXYFactorEditField', 'proc_xSlider', 'ProcNormalizeColorsButton'};
            for n = 1:numel(candidates)
                name = candidates{n};
                if isprop(app, name) && isvalid(app.(name)) && isprop(app.(name), 'Enable')
                    state = char(string(app.(name).Enable));
                    return
                end
            end
        end

        function configure_processing_sidebar_layout(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            if isempty(app) || ~isvalid(app) || ...
                    ~isprop(app, 'ProcSideGrid') || isempty(app.ProcSideGrid) || ~isvalid(app.ProcSideGrid)
                return
            end

            app.ProcSavePanel.Layout.Row = 4;
            app.ProcAdvancedOptionsButton.Layout.Row = 5;
            app.SpectralUnmixingPanel.Layout.Row = 6;

            is_image_mode = strcmpi(char(string(app.VolumeDropDown.Value)), 'Colormap');
            row3_height = 72;
            try
                current_heights = app.ProcSideGrid.RowHeight;
                if numel(current_heights) >= 3
                    row3_height = current_heights{3};
                end
            catch
            end

            row5_height = 0;
            if is_image_mode
                row6_height = 212;
                app.SpectralUnmixingPanel.Visible = 'on';
            else
                row6_height = 0;
                app.SpectralUnmixingPanel.Visible = 'off';
            end

            app.ProcAdvancedOptionsButton.Visible = 'off';
            if isprop(app.ProcAdvancedOptionsButton, 'Enable')
                app.ProcAdvancedOptionsButton.Enable = 'off';
            end

            app.ProcSideGrid.RowHeight = {95, 'fit', row3_height, 93, row5_height, row6_height};
        end

        function install_processing_advanced_callback(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            app.ProcAdvancedOptionsButton.Visible = 'off';
            if isprop(app.ProcAdvancedOptionsButton, 'Enable')
                app.ProcAdvancedOptionsButton.Enable = 'off';
            end
            app.ProcAdvancedOptionsButton.ButtonPushedFcn = @(src, event) ...
                Program.GUIHandling.handle_processing_advanced_toggle(app);
        end

        function handle_processing_advanced_toggle(app)
            if nargin < 1 || isempty(app)
                app = Program.app;
            end

            Program.GUIHandling.configure_processing_sidebar_layout(app);
        end

        function set_processing_histogram_controls_enabled(app, prefix, state)
            slider = app.(sprintf('%s_hist_slider', prefix));
            gamma_field = app.(sprintf('%s_GammaEditField', prefix));
            title_label = Program.Routines.GUI.get_component('labels', prefix);
            gamma_label = Program.GUIHandling.find_processing_gamma_label(gamma_field.Parent, title_label);

            if isprop(slider, 'Enable')
                slider.Enable = state;
            end
            if isprop(gamma_field, 'Enable')
                gamma_field.Enable = state;
            end

            Program.GUIHandling.set_processing_label_state(title_label, state);
            Program.GUIHandling.set_processing_label_state(gamma_label, state);
            Program.GUIHandling.sync_processing_window_fields(app, prefix);
        end

        function set_processing_label_state(label, state)
            if isempty(label) || ~isvalid(label)
                return
            end

            if isprop(label, 'Enable')
                label.Enable = state;
            end

            if isprop(label, 'FontColor')
                if strcmp(state, 'on')
                    label.FontColor = [0 0 0];
                else
                    label.FontColor = [0.6 0.6 0.6];
                end
            end
        end

        function controls = processing_window_controls(app, prefix)
            controls = [];
            if ~isappdata(app.CELL_ID, 'proc_window_controls')
                return
            end

            controls_by_prefix = getappdata(app.CELL_ID, 'proc_window_controls');
            key = matlab.lang.makeValidName(prefix);
            if ~isstruct(controls_by_prefix) || ~isfield(controls_by_prefix, key)
                return
            end

            controls = controls_by_prefix.(key);
            required = {'min_label', 'min_field', 'max_label', 'max_field'};
            for n = 1:numel(required)
                name = required{n};
                if ~isfield(controls, name) || isempty(controls.(name)) || ~isvalid(controls.(name))
                    controls = [];
                    return
                end
            end
        end

        function gamma_label = find_processing_gamma_label(header_grid, title_label)
            gamma_label = [];
            children = header_grid.Children;
            for n = 1:numel(children)
                child = children(n);
                if isa(child, 'matlab.ui.control.Label') && child ~= title_label
                    child_tag = "";
                    if isprop(child, 'Tag')
                        child_tag = string(child.Tag);
                    end
                    if startsWith(child_tag, "proc_")
                        continue
                    end
                    gamma_label = child;
                    return
                end
            end
        end

        function install_processing_resize_callback(app)
            if isempty(app) || ~isvalid(app) || ...
                    ~isprop(app, 'CELL_ID') || isempty(app.CELL_ID) || ~isvalid(app.CELL_ID)
                return
            end

            if isappdata(app.CELL_ID, 'proc_resize_callback_installed')
                return
            end

            if isprop(app.CELL_ID, 'AutoResizeChildren')
                try
                    app.CELL_ID.AutoResizeChildren = 'off';
                catch
                end
            end

            setappdata(app.CELL_ID, 'proc_resize_callback_installed', true);
            setappdata(app.CELL_ID, 'proc_resize_legacy_callback', app.CELL_ID.SizeChangedFcn);
            app.CELL_ID.SizeChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_window_resized(app, src, event);
        end

        function handle_window_resized(app, src, event)
            if nargin >= 2 && ~isempty(src) && isvalid(src) && ...
                    isappdata(src, 'proc_resize_guard') && getappdata(src, 'proc_resize_guard')
                return
            end

            if nargin >= 1 && ~isempty(app) && isvalid(app)
                Program.GUIHandling.enforce_app_window_bounds(app);
                Program.GUIHandling.apply_processing_responsive_layout(app);
            end

            if nargin < 2 || isempty(src) || ~isvalid(src) || ...
                    ~isappdata(src, 'proc_resize_legacy_callback')
                return
            end

            legacy_callback = getappdata(src, 'proc_resize_legacy_callback');
            if isempty(legacy_callback)
                return
            end

            try
                if isa(legacy_callback, 'function_handle')
                    legacy_callback(src, event);
                else
                    feval(legacy_callback, src, event);
                end
            catch
            end
        end

        function enforce_app_window_bounds(app)
            if isempty(app) || ~isvalid(app) || ...
                    ~isprop(app, 'CELL_ID') || isempty(app.CELL_ID) || ~isvalid(app.CELL_ID)
                return
            end

            fig = app.CELL_ID;
            current_position = fig.Position;
            target_position = Program.GUIHandling.constrain_app_window_position(current_position);
            if isequal(round(target_position), round(current_position))
                return
            end

            setappdata(fig, 'proc_resize_guard', true);
            cleanup = onCleanup(@() setappdata(fig, 'proc_resize_guard', false));
            fig.Position = target_position;
        end

        function position = constrain_app_window_position(position)
            screen_rect = get(groot, 'ScreenSize');
            screen_origin = screen_rect(1:2);
            screen_extent = screen_rect(3:4);

            usable_extent = max(screen_extent - [40 110], [900 650]);
            minimum_extent = min([1500 900], usable_extent);

            position(3) = min(max(position(3), minimum_extent(1)), usable_extent(1));
            position(4) = min(max(position(4), minimum_extent(2)), usable_extent(2));

            x_max = screen_origin(1) + screen_extent(1) - position(3);
            y_max = screen_origin(2) + screen_extent(2) - position(4);
            position(1) = min(max(position(1), screen_origin(1)), x_max);
            position(2) = min(max(position(2), screen_origin(2)), y_max);
        end

        function apply_processing_responsive_layout(app)
            if isempty(app) || ~isvalid(app) || ...
                    ~isprop(app, 'ProcessingGridLayout') || isempty(app.ProcessingGridLayout) || ...
                    ~isvalid(app.ProcessingGridLayout)
                return
            end

            total_width = Program.GUIHandling.processing_container_width(app);
            side_width = Program.GUIHandling.processing_sidebar_width(total_width);
            main_width = Program.GUIHandling.processing_main_width(app, total_width, side_width);
            control_width = Program.GUIHandling.processing_control_panel_width(main_width);
            stack_threshold_panel = main_width < 880;

            histogram_width = main_width;
            if ~stack_threshold_panel
                histogram_width = max(main_width - control_width, 320);
            end
            histogram_columns = Program.GUIHandling.processing_histogram_columns(histogram_width);

            app.ProcessingGridLayout.ColumnWidth = {'1x', side_width};
            app.ProcessingGridLayout.RowHeight = ...
                Program.GUIHandling.processing_grid_row_heights(stack_threshold_panel, histogram_columns);

            if stack_threshold_panel
                app.GridLayout64.ColumnWidth = {'1x'};
                app.GridLayout64.RowHeight = {'1x', 'fit'};
                app.ProcHistogramPanel.Layout.Row = 1;
                app.ProcHistogramPanel.Layout.Column = 1;
                app.ProcThresholdPanel.Layout.Row = 2;
                app.ProcThresholdPanel.Layout.Column = 1;
            else
                app.GridLayout64.ColumnWidth = {'1x', control_width};
                app.GridLayout64.RowHeight = {'1x'};
                app.ProcHistogramPanel.Layout.Row = 1;
                app.ProcHistogramPanel.Layout.Column = 1;
                app.ProcThresholdPanel.Layout.Row = 1;
                app.ProcThresholdPanel.Layout.Column = 2;
            end

            Program.GUIHandling.layout_processing_threshold_controls(app, stack_threshold_panel);
            Program.GUIHandling.layout_processing_histogram_panels(app, histogram_columns, histogram_width);
            Program.GUIHandling.position_percentile_noise_editor(app);
        end

        function width = processing_container_width(app)
            candidates = nan(1, 4);

            try
                candidates(1) = app.ProcessingGridLayout.Position(3);
            catch
            end

            try
                candidates(2) = app.ImageProcessingTab.Position(3) - 16;
            catch
            end

            try
                candidates(3) = app.TabGroup.Position(3) - 16;
            catch
            end

            try
                candidates(4) = app.CELL_ID.Position(3) - 40;
            catch
            end

            candidates = candidates(isfinite(candidates) & candidates > 1);
            if isempty(candidates)
                width = app.CELL_ID.Position(3);
            else
                width = min(candidates);
            end
        end

        function width = processing_sidebar_width(total_width)
            width = min(304, max(292, round(total_width * 0.19)));
        end

        function width = processing_main_width(app, total_width, side_width)
            width = max(total_width - side_width - 8, 320);
        end

        function width = processing_control_panel_width(main_width)
            width = min(190, max(156, round(main_width * 0.2)));
        end

        function columns = processing_histogram_columns(histogram_width)
            if histogram_width >= 860
                columns = 3;
            elseif histogram_width >= 1
                columns = 2;
            end
        end

        function row_heights = processing_grid_row_heights(stack_threshold_panel, histogram_columns)
            if histogram_columns >= 3 && ~stack_threshold_panel
                row_heights = {'0.62x', '0.38x'};
            elseif stack_threshold_panel
                row_heights = {'0.42x', '0.58x'};
            else
                row_heights = {'0.48x', '0.52x'};
            end
        end

        function layout_processing_threshold_controls(app, compact)
            row_heights = app.ProcThresholdGrid.RowHeight;
            if numel(row_heights) >= 9
                row_heights{3} = 30;
                row_heights{4} = 30;
                row_heights{5} = 20;
                row_heights{6} = 0;
                row_heights{7} = 30;
                row_heights{8} = 30;
                row_heights{9} = 20;
            end

            if compact
                app.ProcThresholdGrid.ColumnWidth = {'1x', '1x'};
                if numel(row_heights) >= 9
                    row_heights{4} = 0;
                    row_heights{8} = 0;
                end

                app.ProcMeasureROINoiseButton.Layout.Row = 3;
                app.ProcMeasureROINoiseButton.Layout.Column = 1;
                app.ProcMeasure90pthNoiseButton.Layout.Row = 3;
                app.ProcMeasure90pthNoiseButton.Layout.Column = 2;
                app.ProcNormalizeColorsButton.Layout.Row = 7;
                app.ProcNormalizeColorsButton.Layout.Column = 1;
                app.ProcHistogramMatchingButton.Layout.Row = 7;
                app.ProcHistogramMatchingButton.Layout.Column = 2;
                app.Panel_87.Layout.Row = 9;
                app.Panel_87.Layout.Column = [1 2];
            else
                app.ProcThresholdGrid.ColumnWidth = {'1x'};
                app.ProcMeasureROINoiseButton.Layout.Row = 3;
                app.ProcMeasureROINoiseButton.Layout.Column = 1;
                app.ProcMeasure90pthNoiseButton.Layout.Row = 4;
                app.ProcMeasure90pthNoiseButton.Layout.Column = 1;
                app.ProcNormalizeColorsButton.Layout.Row = 7;
                app.ProcNormalizeColorsButton.Layout.Column = 1;
                app.ProcHistogramMatchingButton.Layout.Row = 8;
                app.ProcHistogramMatchingButton.Layout.Column = 1;
                app.Panel_87.Layout.Row = 9;
                app.Panel_87.Layout.Column = 1;
            end

            app.ProcThresholdGrid.RowHeight = row_heights;
        end

        function layout_processing_histogram_panels(app, desired_columns, histogram_width)
            state = Program.Handlers.channels.processing_state(app);
            active_rows = [state.rows([state.rows.source_idx] > 0).row];
            panel_count = max(1, numel(active_rows));
            columns = min(max(1, desired_columns), panel_count);
            row_count = max(1, ceil(panel_count / columns));

            app.ProcHistogramGrid.ColumnWidth = repmat({'1x'}, 1, columns);
            app.ProcHistogramGrid.RowHeight = repmat({'1x'}, 1, row_count);

            occupied_rows = false(1, numel(Program.GUIHandling.pos_prefixes));
            for order = 1:numel(active_rows)
                row_idx = active_rows(order);
                prefix = Program.GUIHandling.pos_prefixes{row_idx};
                panel = app.(sprintf('%s_hist_panel', prefix));
                panel.Parent = app.ProcHistogramGrid;
                panel.Layout.Row = ceil(order / columns);
                panel.Layout.Column = mod(order - 1, columns) + 1;
                occupied_rows(row_idx) = true;
            end

            for row_idx = find(~occupied_rows)
                prefix = Program.GUIHandling.pos_prefixes{row_idx};
                panel = app.(sprintf('%s_hist_panel', prefix));
                panel.Parent = app.ProcHistogramGrid;
                panel.Layout.Row = 1;
                panel.Layout.Column = 1;
            end

            card_width = max(histogram_width / columns, 240);
            compact_header = columns < 3 || card_width < 360;
            for n = 1:numel(Program.GUIHandling.pos_prefixes)
                Program.GUIHandling.layout_processing_histogram_header(app, ...
                    Program.GUIHandling.pos_prefixes{n}, compact_header);
            end
        end

        function layout_processing_histogram_header(app, prefix, compact)
            gamma_field = app.(sprintf('%s_GammaEditField', prefix));
            title_label = Program.Routines.GUI.get_component('labels', prefix);
            header_grid = gamma_field.Parent;
            gamma_label = Program.GUIHandling.find_processing_gamma_label(header_grid, title_label);
            controls = Program.GUIHandling.processing_window_controls(app, prefix);
            if isempty(controls)
                return
            end

            if isprop(header_grid, 'ColumnSpacing')
                header_grid.ColumnSpacing = 2;
            end
            if isprop(header_grid, 'RowSpacing')
                header_grid.RowSpacing = 0;
            end

            if compact
                header_grid.RowHeight = {'fit', 'fit'};
                header_grid.ColumnWidth = {2, 'fit', 44, 'fit', 44, '1x', 'fit', 46, 2};

                title_label.Layout.Row = 1;
                title_label.Layout.Column = [2 6];
                title_label.HorizontalAlignment = 'left';
                title_label.VerticalAlignment = 'center';

                if ~isempty(gamma_label)
                    gamma_label.Layout.Row = 1;
                    gamma_label.Layout.Column = 7;
                    gamma_label.HorizontalAlignment = 'right';
                    gamma_label.VerticalAlignment = 'center';
                end

                gamma_field.Layout.Row = 1;
                gamma_field.Layout.Column = 8;

                controls.min_label.Layout.Row = 2;
                controls.min_label.Layout.Column = 2;
                controls.min_field.Layout.Row = 2;
                controls.min_field.Layout.Column = 3;
                controls.max_label.Layout.Row = 2;
                controls.max_label.Layout.Column = 4;
                controls.max_field.Layout.Row = 2;
                controls.max_field.Layout.Column = 5;
            else
                header_grid.RowHeight = {'fit'};
                header_grid.ColumnWidth = {2, 'fit', '1x', 24, 44, 24, 44, 'fit', 46, 2};

                title_label.Layout.Row = 1;
                title_label.Layout.Column = 2;
                title_label.HorizontalAlignment = 'left';
                title_label.VerticalAlignment = 'center';

                if ~isempty(gamma_label)
                    gamma_label.Layout.Row = 1;
                    gamma_label.Layout.Column = 8;
                    gamma_label.HorizontalAlignment = 'right';
                    gamma_label.VerticalAlignment = 'center';
                end

                gamma_field.Layout.Row = 1;
                gamma_field.Layout.Column = 9;

                controls.min_label.Layout.Row = 1;
                controls.min_label.Layout.Column = 4;
                controls.min_field.Layout.Row = 1;
                controls.min_field.Layout.Column = 5;
                controls.max_label.Layout.Row = 1;
                controls.max_label.Layout.Column = 6;
                controls.max_field.Layout.Row = 1;
                controls.max_field.Layout.Column = 7;
            end
        end

        function range = clamp_processing_window_range(range)
            if isempty(range) || numel(range) < 2
                range = [0 255];
                return
            end

            range = round(double(range(:)'));
            range = min(max(range(1:2), 0), 255);
            if range(1) > range(2)
                range = fliplr(range);
            end
        end

        function update_processing_zslider_visibility(app)
            mip_enabled = logical(app.ProcShowMIPCheckBox.Value);
            target_enable = 'on';
            if mip_enabled
                target_enable = 'off';
            end

            if ~strcmp(app.proc_zSlider.Visible, 'on')
                app.proc_zSlider.Visible = 'on';
            end
            if isprop(app.proc_zSlider, 'Enable') && ~strcmp(app.proc_zSlider.Enable, target_enable)
                app.proc_zSlider.Enable = target_enable;
            end
            if isprop(app.proc_hor_zSlider, 'Enable') && ~strcmp(app.proc_hor_zSlider.Enable, target_enable)
                app.proc_hor_zSlider.Enable = target_enable;
            end
            if isprop(app.proc_vert_zSlider, 'Enable') && ~strcmp(app.proc_vert_zSlider.Enable, target_enable)
                app.proc_vert_zSlider.Enable = target_enable;
            end
            if isprop(app.proc_zEditField, 'Enable') && ~strcmp(app.proc_zEditField.Enable, target_enable)
                app.proc_zEditField.Enable = target_enable;
            end

            row_heights = app.ProcAxGrid.RowHeight;
            if numel(row_heights) >= 4 && ~isequal(row_heights{4}, 30)
                row_heights{4} = 30;
                app.ProcAxGrid.RowHeight = row_heights;
            end
        end

        function configure_processing_color_panel(app)
            app.Panel_57.Title = 'Adjust Colors';
            app.Panel_57.BorderType = 'line';
            app.Panel_57.FontWeight = 'bold';
            if isprop(app.Panel_57, 'TitlePosition')
                app.Panel_57.TitlePosition = 'centertop';
            end

            app.ProcHistogramManipulationLabel.Visible = 'off';
            row_heights = app.ProcThresholdGrid.RowHeight;
            if numel(row_heights) >= 9
                row_heights{1} = 20;
                row_heights{2} = 0;
                row_heights{3} = 30;
                row_heights{4} = 30;
                row_heights{5} = 20;
                row_heights{6} = 0;
                row_heights{7} = 30;
                row_heights{8} = 30;
                row_heights{9} = 20;
            end

            app.ProcThresholdGrid.RowHeight = row_heights;

            if isprop(app, 'ProcThresholdManipulationLabel') && isvalid(app.ProcThresholdManipulationLabel)
                app.ProcThresholdManipulationLabel.Visible = 'on';
                app.ProcThresholdManipulationLabel.Text = 'Threshold BG';
                app.ProcThresholdManipulationLabel.Tooltip = ...
                    'Threshold/background helpers for setting per-channel lower bounds.';
            end
            if isprop(app, 'ProcThresholdKnobPanel') && isvalid(app.ProcThresholdKnobPanel)
                app.ProcThresholdKnobPanel.Visible = 'off';
            end
            if isprop(app, 'ProcMeasureROINoiseButton') && isvalid(app.ProcMeasureROINoiseButton)
                app.ProcMeasureROINoiseButton.Visible = 'on';
                app.ProcMeasureROINoiseButton.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.measure_threshold_from_roi(app);
            end
            if isprop(app, 'ProcMeasure90pthNoiseButton') && isvalid(app.ProcMeasure90pthNoiseButton)
                app.ProcMeasure90pthNoiseButton.Visible = 'on';
                app.ProcMeasure90pthNoiseButton.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.measure_threshold_from_percentile(app);
            end

            Program.GUIHandling.update_processing_threshold_target_options(app);
            Program.GUIHandling.apply_processing_responsive_layout(app);
        end

        function set_gui_limits(app, mode, dims)
            if nargin < 2 || isempty(mode)
                mode = 'soft';
            end

            if ~exist('dims', 'var')
                active_volume = Program.GUIHandling.get_active_volume(app, 'request', 'state');
                switch active_volume.state
                    case 'colormap'
                        current_dims = Program.Helpers.processing_colormap_context(app).dims;
                        ny = current_dims(1);
                        nx = current_dims(2);
                        nz = current_dims(3);
                        nc = current_dims(4);
    
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

            app.proc_xSlider.Limits = [1, nx];
            app.proc_ySlider.Limits = [1, ny];
            app.proc_xyAxes.XLim = [1, nx];
            app.proc_xyAxes.YLim = [1, ny];
            if app.ProcPreviewZslowCheckBox.Value
                app.proc_xzAxes.XLim = [1, nx];
                app.proc_xzAxes.YLim = [1, nz];
                app.proc_yzAxes.XLim = [1, nz];
                app.proc_yzAxes.YLim = [1, ny];
            end

            if strcmp(mode, 'hard')
                x_value = round(app.proc_xSlider.Limits(2)/2);
                y_value = round(app.proc_ySlider.Limits(2)/2);
                z_value = round(nz/2);
                t_value = 1;
    
            else
                x_value = min(max(round(app.proc_xSlider.Value), 1), nx);
                y_value = min(max(round(app.proc_ySlider.Value), 1), ny);
                z_value = min(max(round(app.proc_zSlider.Value), 1), nz);
                if exist("nt", 'var')
                    t_value = min(max(round(app.proc_tSlider.Value), 1), nt);
                end
            end

            Program.GUIHandling.suspend_processing_zslider_callbacks(app, true);
            cleanup = onCleanup(@() Program.GUIHandling.suspend_processing_zslider_callbacks(app, false));

            app.proc_xSlider.Value = x_value;
            app.proc_ySlider.Value = y_value;
            app.proc_xEditField.Value = x_value;
            app.proc_yEditField.Value = y_value;

            Program.Helpers.configure_processing_zsliders(app, nz, z_value);

            if exist("nt", 'var')
                app.proc_tSlider.Value = t_value;
                app.proc_tEditField.Value = t_value;
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
                Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
                return
            end

            roi = drawrectangle(app.proc_xyAxes,'Color','black','StripeColor','m');
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');

            Program.crop_rotate_gui.draw(app, roi);
        end

        function swap_volumes(app, event)
            if ~exist('event', 'var')
                requested_mode = Program.GUIHandling.get_active_volume(app, 'request', 'state');
            else
                requested_mode = lower(char(string(event.Value)));
            end

            Program.GUIHandling.refresh_processing_volume_dropdown(app, requested_mode);
            [mode, is_available, unavailable_message] = ...
                Program.GUIHandling.resolve_processing_volume_request(app, requested_mode);
            Program.GUIHandling.refresh_processing_volume_dropdown(app, mode);

            if ~is_available
                uialert(app.CELL_ID, unavailable_message, 'Volume Unavailable');
                return
            end

            Program.GUIHandling.set_gui_limits(app, mode);

            switch mode
                case 'colormap'
                    context = Program.Helpers.processing_colormap_context(app);
                    if isempty(context.volume)
                        max_val = 255;
                    else
                        max_val = max(context.volume, [], "all");
                    end

                    chunk_prefs = context.prefs;
                    if ~isfield(chunk_prefs, 'gamma')
                        chunk_prefs.gamma = ones(length(Program.GUIHandling.pos_prefixes), 1);
                    end
                    chunk_gammas = Program.Helpers.expand_gamma( ...
                        chunk_prefs.gamma, ...
                        length(Program.GUIHandling.pos_prefixes));
                    for c=1:length(Program.GUIHandling.pos_prefixes)
                        app.(sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c})).Value = chunk_gammas(c);
                    end

                case 'video'
                    max_val = max(app.retrieve_frame(app.proc_tSlider.Value), [], "all");
                    
                    for c=1:length(Program.GUIHandling.pos_prefixes)
                        app.(sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c})).Value = 1;
                    end
            end

            Program.GUIHandling.set_thresholds(app, max(max_val, 255));
            Program.Routines.GUI.(sprintf("toggle_%s", mode));

            Program.GUIHandling.set_processing_spectral_unmixing_state( ...
                app, strcmpi(char(string(app.VolumeDropDown.Value)), 'Colormap'));

            for comp=1:length(Program.GUIHandling.cm_exclusive_gui)
                handle_name = Program.GUIHandling.cm_exclusive_gui{comp};
                if isprop(app, handle_name) && isvalid(app.(handle_name)) && isprop(app.(handle_name), 'Enable')
                    app.(handle_name).Enable = strcmp(app.VolumeDropDown.Value, 'Colormap');
                end
            end

            Program.GUIHandling.capture_processing_defaults(app, mode, false);
        end

        function set_thresholds(app, max_val)
            %#ok<INUSD>
            setappdata(app.CELL_ID, 'proc_threshold_raw_max', 255);

            threshold_limits = [0 255];
            hist_limits = [0 255];

            app.ProcNoiseThresholdKnob.Limits = threshold_limits;
            app.ProcNoiseThresholdField.Limits = threshold_limits;
            app.ProcNoiseThresholdKnob.Value = threshold_limits(1);
            app.ProcNoiseThresholdField.Value = threshold_limits(1);
            app.ProcNoiseThresholdField.ValueDisplayFormat = '%.0f';
            app.ProcNoiseThresholdKnob.MajorTicks = 0:51:255;
            app.ProcNoiseThresholdKnob.MajorTickLabels = string(app.ProcNoiseThresholdKnob.MajorTicks);
            Program.GUIHandling.shorten_knob_labels(app);

            for pos=1:length(Program.GUIHandling.pos_prefixes)
                slider = app.(sprintf('%s_hist_slider', Program.GUIHandling.pos_prefixes{pos}));
                slider.Limits = hist_limits;
                slider.Value = hist_limits;
                Program.GUIHandling.configure_processing_histogram_slider(slider);
                app.(sprintf('%s_hist_ax', Program.GUIHandling.pos_prefixes{pos})).XLim = hist_limits;
                Program.GUIHandling.sync_processing_window_fields(app, Program.GUIHandling.pos_prefixes{pos});
            end

            Program.GUIHandling.update_processing_threshold_target_options(app);
        end

        function install_threshold_stepper(app)
            grid = app.ProcThresholdKnobGrid;
            app.ProcNoiseThresholdKnob.Visible = 'off';
            app.ProcThresholdKnobPanel.Visible = 'on';
            app.ProcThresholdManipulationLabel.Text = 'Threshold BG';
            app.ProcThresholdManipulationLabel.Tooltip = ...
                'Targeted helpers for setting per-channel lower bounds on the user-facing uint8 scale (0-255).';
            grid.ColumnWidth = {46, '1x', 0, 24, 24};
            grid.RowHeight = {22, 22, 0, 0};

            controls = Program.GUIHandling.ensure_processing_threshold_target_controls(app);
            controls.target_label.Parent = grid;
            controls.target_dropdown.Parent = grid;
            controls.min_label.Parent = grid;
            controls.target_label.Layout.Row = 1;
            controls.target_label.Layout.Column = 1;
            controls.target_dropdown.Layout.Row = 1;
            controls.target_dropdown.Layout.Column = [2 5];
            controls.min_label.Layout.Row = 2;
            controls.min_label.Layout.Column = 1;

            app.ProcNoiseThresholdField.Visible = 'on';
            app.ProcNoiseThresholdField.Layout.Row = 2;
            app.ProcNoiseThresholdField.Layout.Column = 2;
            app.ProcNoiseThresholdField.ValueChangedFcn = @(src, event) ...
                Program.GUIHandling.handle_threshold_field_changed(app, src);

            handles = Program.GUIHandling.threshold_stepper_handles(app);
            if isempty(handles)
                up_button = uibutton(grid, 'push');
                up_button.Layout.Row = 2;
                up_button.Layout.Column = 4;
                up_button.FontSize = 11;
                up_button.Text = char(9650);
                up_button.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.step_proc_threshold(app, 1);

                down_button = uibutton(grid, 'push');
                down_button.Layout.Row = 2;
                down_button.Layout.Column = 5;
                down_button.FontSize = 11;
                down_button.Text = char(9660);
                down_button.ButtonPushedFcn = @(src, event) ...
                    Program.GUIHandling.step_proc_threshold(app, -1);

                handles = struct('up', up_button, 'down', down_button);
                setappdata(app.CELL_ID, 'proc_threshold_stepper', handles);
            else
                handles.up.Parent = grid;
                handles.down.Parent = grid;
                handles.up.Layout.Row = 2;
                handles.up.Layout.Column = 4;
                handles.down.Layout.Row = 2;
                handles.down.Layout.Column = 5;
                handles.up.Visible = 'on';
                handles.down.Visible = 'on';
            end

            app.ProcMeasureROINoiseButton.ButtonPushedFcn = @(src, event) ...
                Program.GUIHandling.measure_threshold_from_roi(app);
            app.ProcMeasure90pthNoiseButton.ButtonPushedFcn = @(src, event) ...
                Program.GUIHandling.measure_threshold_from_percentile(app);
            Program.GUIHandling.update_processing_threshold_button_tooltips(app);
            Program.GUIHandling.sync_processing_threshold_field(app);
            Program.GUIHandling.set_threshold_stepper_state(app, app.ProcNoiseThresholdField.Enable);
        end

        function set_threshold_stepper_state(app, state)
            if isprop(app.ProcNoiseThresholdKnob, 'Enable')
                app.ProcNoiseThresholdKnob.Enable = state;
            end

            if isprop(app.ProcNoiseThresholdField, 'Enable')
                app.ProcNoiseThresholdField.Enable = state;
            end

            controls = Program.GUIHandling.processing_threshold_target_controls(app);
            if ~isempty(controls)
                controls.target_dropdown.Enable = state;
                if isprop(controls.target_label, 'Enable')
                    controls.target_label.Enable = state;
                end
                if isprop(controls.min_label, 'Enable')
                    controls.min_label.Enable = state;
                end
            end

            handles = Program.GUIHandling.threshold_stepper_handles(app);
            if isempty(handles)
                return
            end
            handles.up.Enable = state;
            handles.down.Enable = state;
        end

        function handles = threshold_stepper_handles(app)
            handles = [];
            if ~isappdata(app.CELL_ID, 'proc_threshold_stepper')
                return
            end

            handles = getappdata(app.CELL_ID, 'proc_threshold_stepper');
            if ~isstruct(handles) || ~isfield(handles, 'up') || ~isfield(handles, 'down')
                handles = [];
                return
            end

            if ~isvalid(handles.up) || ~isvalid(handles.down)
                rmappdata(app.CELL_ID, 'proc_threshold_stepper');
                handles = [];
            end
        end

        function controls = ensure_processing_threshold_target_controls(app)
            controls = Program.GUIHandling.processing_threshold_target_controls(app);
            if ~isempty(controls)
                return
            end

            grid = app.ProcThresholdKnobGrid;
            target_label = uilabel(grid, ...
                'Text', 'Apply', ...
                'HorizontalAlignment', 'right', ...
                'Tooltip', 'Choose which mapped channel this threshold helper edits.');
            target_dropdown = uidropdown(grid, ...
                'Items', {'All mapped channels'}, ...
                'ItemsData', {'all'}, ...
                'Value', 'all', ...
                'Tooltip', 'Choose which mapped channel this threshold helper edits.', ...
                'ValueChangedFcn', @(src, event) ...
                    Program.GUIHandling.handle_processing_threshold_target_changed(app));
            min_label = uilabel(grid, ...
                'Text', 'Min', ...
                'HorizontalAlignment', 'right', ...
                'Tooltip', 'Lower display/save bound for the selected target channel(s).');

            controls = struct( ...
                'target_label', target_label, ...
                'target_dropdown', target_dropdown, ...
                'min_label', min_label);
            setappdata(app.CELL_ID, 'proc_threshold_target_controls', controls);
        end

        function controls = processing_threshold_target_controls(app)
            controls = [];
            if ~isappdata(app.CELL_ID, 'proc_threshold_target_controls')
                return
            end

            controls = getappdata(app.CELL_ID, 'proc_threshold_target_controls');
            required = {'target_label', 'target_dropdown', 'min_label'};
            for n = 1:numel(required)
                name = required{n};
                if ~isfield(controls, name) || isempty(controls.(name)) || ~isvalid(controls.(name))
                    controls = [];
                    if isappdata(app.CELL_ID, 'proc_threshold_target_controls')
                        rmappdata(app.CELL_ID, 'proc_threshold_target_controls');
                    end
                    return
                end
            end
        end

        function handle_processing_threshold_target_changed(app)
            Program.GUIHandling.sync_processing_threshold_field(app);
            Program.GUIHandling.update_processing_threshold_button_tooltips(app);
        end

        function update_processing_threshold_target_options(app)
            controls = Program.GUIHandling.processing_threshold_target_controls(app);
            if ~isempty(controls)
                if isprop(controls.target_label, 'Visible')
                    controls.target_label.Visible = 'off';
                end
                if isprop(controls.target_dropdown, 'Visible')
                    controls.target_dropdown.Visible = 'off';
                end
                if isprop(controls.min_label, 'Visible')
                    controls.min_label.Visible = 'off';
                end
            end
            Program.GUIHandling.update_processing_threshold_button_tooltips(app);
        end

        function rows = processing_threshold_target_rows(app)
            rows = Program.Handlers.channels.empty_processing_row();
            rows = rows([]);

            state = Program.Handlers.channels.processing_state(app);
            mapped_rows = state.rows([state.rows.source_idx] > 0 & [state.rows.row] <= numel(Program.GUIHandling.pos_prefixes));
            if isempty(mapped_rows)
                return
            end

            rows = mapped_rows;
        end

        function prefixes = processing_threshold_target_prefixes(app)
            rows = Program.GUIHandling.processing_threshold_target_rows(app);
            prefixes = {};
            for n = 1:numel(rows)
                row = rows(n);
                if row.row < 1 || row.row > numel(Program.GUIHandling.pos_prefixes)
                    continue
                end
                prefixes{end + 1} = Program.GUIHandling.pos_prefixes{row.row}; %#ok<AGROW>
            end
        end

        function description = processing_threshold_target_description(app)
            %#ok<INUSD>
            description = 'all mapped channels';
        end

        function set_threshold_field_display(app, value, target_label)
            value = min(max(round(double(value)), 0), 255);
            Program.GUIHandling.suspend_processing_threshold_field_callbacks(app, true);
            cleanup = onCleanup(@() Program.GUIHandling.suspend_processing_threshold_field_callbacks(app, false));
            app.ProcNoiseThresholdField.Value = value;
            app.ProcNoiseThresholdKnob.Value = value;
            if nargin < 3 || strlength(string(target_label)) == 0
                target_label = Program.GUIHandling.processing_threshold_target_description(app);
            end
            app.ProcNoiseThresholdField.Tooltip = ...
                sprintf('Lower display/save bound for %s on the user-facing uint8 scale (0-255).', target_label);
            handles = Program.GUIHandling.threshold_stepper_handles(app);
            if ~isempty(handles)
                handles.up.Tooltip = sprintf('Increase the lower bound for %s by 1 intensity unit.', target_label);
                handles.down.Tooltip = sprintf('Decrease the lower bound for %s by 1 intensity unit.', target_label);
            end
        end

        function suspend_processing_threshold_field_callbacks(app, tf)
            if nargin < 2 || tf
                setappdata(app.CELL_ID, 'proc_threshold_field_sync_guard', true);
            elseif isappdata(app.CELL_ID, 'proc_threshold_field_sync_guard')
                rmappdata(app.CELL_ID, 'proc_threshold_field_sync_guard');
            end
        end

        function tf = processing_threshold_field_callbacks_suspended(app)
            tf = isappdata(app.CELL_ID, 'proc_threshold_field_sync_guard') && ...
                logical(getappdata(app.CELL_ID, 'proc_threshold_field_sync_guard'));
        end

        function update_processing_threshold_button_tooltips(app)
            target_desc = Program.GUIHandling.processing_threshold_target_description(app);
            if isprop(app, 'ProcMeasureROINoiseButton') && isvalid(app.ProcMeasureROINoiseButton)
                app.ProcMeasureROINoiseButton.Tooltip = ...
                    sprintf('Measure an ROI on the current preview and set the Min bound for %s.', target_desc);
            end
            if isprop(app, 'ProcMeasure90pthNoiseButton') && isvalid(app.ProcMeasure90pthNoiseButton)
                app.ProcMeasure90pthNoiseButton.Tooltip = ...
                    sprintf('Measure a percentile on the current preview and set the Min bound for %s.', target_desc);
            end
        end

        function sync_processing_threshold_field(app)
            controls = Program.GUIHandling.processing_threshold_target_controls(app);
            if isempty(controls)
                return
            end

            prefixes = Program.GUIHandling.processing_threshold_target_prefixes(app);
            if isempty(prefixes)
                Program.GUIHandling.set_threshold_field_display(app, 0, 'the mapped channels');
                return
            end

            mins = zeros(1, numel(prefixes));
            for n = 1:numel(prefixes)
                slider = app.(sprintf('%s_hist_slider', prefixes{n}));
                mins(n) = double(slider.Value(1));
            end

            target_desc = Program.GUIHandling.processing_threshold_target_description(app);
            if numel(mins) > 1 && any(abs(mins - mins(1)) > 0.5)
                target_desc = sprintf('%s (currently mixed)', target_desc);
            end

            Program.GUIHandling.set_threshold_field_display(app, mins(1), target_desc);
        end

        function handle_threshold_field_changed(app, src)
            if Program.GUIHandling.processing_threshold_field_callbacks_suspended(app)
                return
            end
            Program.GUIHandling.set_proc_threshold_value(app, src.Value, true);
        end

        function step_proc_threshold(app, direction)
            Program.GUIHandling.set_proc_threshold_value( ...
                app, app.ProcNoiseThresholdField.Value + direction, true);
        end

        function set_proc_threshold_value(app, value, redraw)
            limits = app.ProcNoiseThresholdField.Limits;
            value = min(max(round(double(value)), limits(1)), limits(2));
            prefixes = Program.GUIHandling.processing_threshold_target_prefixes(app);
            Program.GUIHandling.set_threshold_field_display(app, value, ...
                Program.GUIHandling.processing_threshold_target_description(app));

            for n = 1:numel(prefixes)
                Program.GUIHandling.set_processing_channel_min(app, prefixes{n}, value);
            end

            if redraw && ~isempty(prefixes)
                setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
                Program.Helpers.sync_main_display_from_processing(app, false);
                Program.Routines.Processing.render();
                Program.Routines.ID.render();
            end
        end

        function value = proc_threshold_raw_max(app)
            if isappdata(app.CELL_ID, 'proc_threshold_raw_max')
                value = double(getappdata(app.CELL_ID, 'proc_threshold_raw_max'));
            else
                value = 1;
            end

            value = max(value, 1);
        end

        function value = proc_threshold_raw_value(app, raw_max)
            %#ok<INUSD>
            value = 0;
        end

        function measure_threshold_from_roi(app)
            channels = Program.GUIHandling.processing_measurement_frames(app);
            if isempty(channels)
                return
            end

            Program.GUIHandling.hide_percentile_noise_editor(app);

            Program.GUIHandling.gui_lock(app, 'lock', 'processing_tab');
            check = uiconfirm(app.CELL_ID, ...
                'Draw a box on the current preview to estimate noise.', ...
                'NeuroPAL_ID', 'Options', ["OK", "Cancel"]);
            if ~strcmp(check, "OK")
                Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
                return
            end

            roi = drawrectangle(app.proc_xyAxes, 'Color', 'black', 'StripeColor', 'm');
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
            mask = createMask(roi);
            delete(roi);

            updated = false;
            for n = 1:numel(channels)
                roi_values = double(channels(n).frame(mask));
                roi_values = roi_values(isfinite(roi_values));
                if isempty(roi_values)
                    continue
                end

                min_value = mean(roi_values, 'all');
                Program.GUIHandling.set_processing_channel_min(app, channels(n).prefix, min_value);
                updated = true;
            end

            if updated
                setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
                Program.Helpers.sync_main_display_from_processing(app, false);
                Program.Routines.Processing.render();
                Program.Routines.ID.render();
                drawnow limitrate nocallbacks;
            end
        end

        function measure_threshold_from_percentile(app)
            controls = Program.GUIHandling.ensure_percentile_noise_editor(app);
            if isempty(controls)
                return
            end

            if strcmp(controls.panel.Visible, 'on')
                Program.GUIHandling.hide_percentile_noise_editor(app);
                return
            end

            Program.GUIHandling.show_percentile_noise_editor(app);
        end

        function controls = ensure_percentile_noise_editor(app)
            controls = Program.GUIHandling.percentile_noise_editor(app);
            if ~isempty(controls)
                return
            end

            panel = uipanel(app.CELL_ID, ...
                'Title', 'Percentile Noise', ...
                'Visible', 'off', ...
                'Units', 'pixels', ...
                'AutoResizeChildren', 'off');
            panel.Position(3:4) = [220, 104];

            grid = uigridlayout(panel, ...
                'RowHeight', {'fit', 'fit', 'fit'}, ...
                'ColumnWidth', {'1x', 64}, ...
                'ColumnSpacing', 6, ...
                'RowSpacing', 6, ...
                'Padding', [10 8 10 8]);

            prompt = uilabel(grid, ...
                'Text', 'Percentile (0-100)', ...
                'HorizontalAlignment', 'left');
            prompt.Layout.Row = 1;
            prompt.Layout.Column = [1 2];

            field = uieditfield(grid, 'numeric', ...
                'Limits', [0 100], ...
                'ValueDisplayFormat', '%.4g', ...
                'ValueChangedFcn', @(src, event) ...
                    Program.GUIHandling.apply_percentile_noise_editor(app));
            field.Layout.Row = 2;
            field.Layout.Column = [1 2];

            apply_button = uibutton(grid, 'push', ...
                'Text', 'Apply', ...
                'ButtonPushedFcn', @(src, event) ...
                    Program.GUIHandling.apply_percentile_noise_editor(app));
            apply_button.Layout.Row = 3;
            apply_button.Layout.Column = 1;

            cancel_button = uibutton(grid, 'push', ...
                'Text', 'Cancel', ...
                'ButtonPushedFcn', @(src, event) ...
                    Program.GUIHandling.hide_percentile_noise_editor(app));
            cancel_button.Layout.Row = 3;
            cancel_button.Layout.Column = 2;

            controls = struct( ...
                'panel', panel, ...
                'grid', grid, ...
                'prompt', prompt, ...
                'field', field, ...
                'apply_button', apply_button, ...
                'cancel_button', cancel_button);
            setappdata(app.CELL_ID, 'proc_percentile_noise_editor', controls);
        end

        function controls = percentile_noise_editor(app)
            controls = [];
            if ~isappdata(app.CELL_ID, 'proc_percentile_noise_editor')
                return
            end

            controls = getappdata(app.CELL_ID, 'proc_percentile_noise_editor');
            required = {'panel', 'grid', 'prompt', 'field', 'apply_button', 'cancel_button'};
            for n = 1:numel(required)
                name = required{n};
                if ~isfield(controls, name) || isempty(controls.(name)) || ~isvalid(controls.(name))
                    controls = [];
                    if isappdata(app.CELL_ID, 'proc_percentile_noise_editor')
                        rmappdata(app.CELL_ID, 'proc_percentile_noise_editor');
                    end
                    return
                end
            end
        end

        function show_percentile_noise_editor(app)
            controls = Program.GUIHandling.ensure_percentile_noise_editor(app);
            if isempty(controls)
                return
            end

            default_value = 90;
            if isappdata(app.CELL_ID, 'proc_percentile_noise_value')
                default_value = double(getappdata(app.CELL_ID, 'proc_percentile_noise_value'));
            end
            controls.field.Value = min(max(default_value, 0), 100);
            controls.panel.Visible = 'on';
            Program.GUIHandling.position_percentile_noise_editor(app);
        end

        function hide_percentile_noise_editor(app)
            controls = Program.GUIHandling.percentile_noise_editor(app);
            if isempty(controls)
                return
            end

            controls.panel.Visible = 'off';
        end

        function position_percentile_noise_editor(app)
            controls = Program.GUIHandling.percentile_noise_editor(app);
            if isempty(controls) || ~strcmp(controls.panel.Visible, 'on') || ...
                    ~isprop(app, 'ProcMeasure90pthNoiseButton') || isempty(app.ProcMeasure90pthNoiseButton) || ...
                    ~isvalid(app.ProcMeasure90pthNoiseButton)
                return
            end

            drawnow limitrate nocallbacks;
            button_pos = getpixelposition(app.ProcMeasure90pthNoiseButton, true);
            figure_pos = app.CELL_ID.Position;
            panel_size = [220, 104];

            x = button_pos(1) - panel_size(1) - 8;
            if x < 10
                x = button_pos(1) + button_pos(3) + 8;
            end
            x = min(max(x, 10), max(10, figure_pos(3) - panel_size(1) - 10));

            y = button_pos(2) + button_pos(4) - panel_size(2);
            y = min(max(y, 10), max(10, figure_pos(4) - panel_size(2) - 10));

            controls.panel.Position = [x, y, panel_size];
        end

        function apply_percentile_noise_editor(app)
            controls = Program.GUIHandling.percentile_noise_editor(app);
            if isempty(controls)
                return
            end

            percentile_value = double(controls.field.Value);
            if ~isfinite(percentile_value)
                return
            end

            percentile_value = min(max(percentile_value, 0), 100);
            controls.field.Value = percentile_value;
            setappdata(app.CELL_ID, 'proc_percentile_noise_value', percentile_value);
            Program.GUIHandling.hide_percentile_noise_editor(app);
            Program.GUIHandling.apply_percentile_threshold_measurement(app, percentile_value);
        end

        function apply_percentile_threshold_measurement(app, percentile_value)
            channels = Program.GUIHandling.processing_measurement_frames(app);
            if isempty(channels)
                return
            end

            updated = false;
            for n = 1:numel(channels)
                values = double(channels(n).frame(:));
                values = values(isfinite(values));
                if isempty(values)
                    continue
                end

                min_value = prctile(values, percentile_value);
                Program.GUIHandling.set_processing_channel_min(app, channels(n).prefix, min_value);
                updated = true;
            end

            if updated
                setappdata(app.CELL_ID, 'proc_runtime_dirty', true);
                Program.Helpers.sync_main_display_from_processing(app, false);
                Program.Routines.Processing.render();
                Program.Routines.ID.render();
                drawnow limitrate nocallbacks;
            end
        end

        function [preview_frame, raw_max] = threshold_preview_frame(app)
            preview_frame = [];
            raw_max = 1;

            raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
            package = Program.Routines.Processing.compose_volume(app, raw);
            render_volume = double(package.render_volume);
            raw_max = max(max(render_volume, [], 'all'), 1);
            if app.ProcShowMIPCheckBox.Value
                preview_frame = squeeze(max(render_volume, [], 3));
            else
                z_idx = min(max(round(app.proc_zSlider.Value), 1), size(render_volume, 3));
                preview_frame = squeeze(render_volume(:, :, z_idx, :));
            end
        end

        function channels = processing_measurement_frames(app)
            channels = struct('prefix', {}, 'frame', {});
            raw = Program.GUIHandling.get_active_volume(app, 'request', 'array');
            rows = Program.GUIHandling.processing_threshold_target_rows(app);

            for n = 1:numel(rows)
                row = rows(n);
                if row.row < 1 || row.row > numel(Program.GUIHandling.pos_prefixes)
                    continue
                end

                channel_volume = Program.Helpers.to_user_uint8(raw.array(:, :, :, row.source_idx));
                if app.ProcShowMIPCheckBox.Value
                    frame = squeeze(max(channel_volume, [], 3));
                else
                    z_idx = min(max(round(app.proc_zSlider.Value), 1), size(channel_volume, 3));
                    frame = squeeze(channel_volume(:, :, z_idx));
                end

                channels(end + 1) = struct( ... %#ok<AGROW>
                    'prefix', Program.GUIHandling.pos_prefixes{row.row}, ...
                    'frame', double(frame));
            end
        end

        function set_processing_channel_min(app, prefix, value)
            slider = app.(sprintf('%s_hist_slider', prefix));
            range = Program.GUIHandling.clamp_processing_window_range(slider.Value);
            range(1) = min(max(round(double(value)), 0), 255);
            if range(2) < range(1)
                range(2) = range(1);
            end
            Program.GUIHandling.handle_processing_histogram_slider(app, prefix, range, false);
        end


        function capture_processing_defaults(app, mode_key, force)
            if nargin < 2 || strlength(string(mode_key)) == 0
                mode_key = lower(string(app.VolumeDropDown.Value));
            else
                mode_key = lower(string(mode_key));
            end
            if nargin < 3
                force = false;
            end

            key = char(mode_key);
            if isappdata(app.CELL_ID, 'processing_defaults')
                defaults = getappdata(app.CELL_ID, 'processing_defaults');
            else
                defaults = struct();
            end

            if ~force && isfield(defaults, matlab.lang.makeValidName(key))
                return
            end

            prefixes = Program.GUIHandling.pos_prefixes;
            gamma_values = zeros(1, numel(prefixes));
            hist_values = cell(1, numel(prefixes));
            for n = 1:numel(prefixes)
                gamma_values(n) = app.(sprintf('%s_GammaEditField', prefixes{n})).Value;
                hist_values{n} = app.(sprintf('%s_hist_slider', prefixes{n})).Value;
            end

            channel_values = cell(1, 6);
            channel_enabled = false(1, 6);
            channel_roles = cell(1, 6);
            for c = 1:6
                dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
                cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
                ref_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, c);
                channel_values{c} = app.(dd_handle).Value;
                channel_enabled(c) = logical(app.(cb_handle).Value);

                if isprop(app.(ref_handle), 'Value')
                    channel_roles{c} = app.(ref_handle).Value;
                elseif isprop(app.(ref_handle), 'Text')
                    channel_roles{c} = app.(ref_handle).Text;
                else
                    channel_roles{c} = "";
                end
            end

            snapshot = struct( ...
                'mode', string(app.VolumeDropDown.Value), ...
                'threshold', 0, ...
                'show_mip', logical(app.ProcShowMIPCheckBox.Value), ...
                'preview_zslow', logical(app.ProcPreviewZslowCheckBox.Value), ...
                'hide_zero', logical(app.HidezerointensitypixelsCheckBox.Value), ...
                'xy_factor', double(app.ProcXYFactorEditField.Value), ...
                'z_slices', double(app.ProcZSlicesEditField.Value), ...
                'gamma_values', gamma_values, ...
                'hist_values', {hist_values}, ...
                'channel_values', {channel_values}, ...
                'channel_enabled', channel_enabled, ...
                'channel_roles', {channel_roles});

            defaults.(matlab.lang.makeValidName(key)) = snapshot;
            setappdata(app.CELL_ID, 'processing_defaults', defaults);
        end

        function snapshot = get_processing_defaults(app, mode_key)
            snapshot = struct();
            if nargin < 2 || strlength(string(mode_key)) == 0
                mode_key = lower(string(app.VolumeDropDown.Value));
            else
                mode_key = lower(string(mode_key));
            end

            if ~isappdata(app.CELL_ID, 'processing_defaults')
                return
            end

            defaults = getappdata(app.CELL_ID, 'processing_defaults');
            key = matlab.lang.makeValidName(char(mode_key));
            if isfield(defaults, key)
                snapshot = defaults.(key);
            end
        end

        function restore_processing_defaults(app, snapshot)
            if nargin < 2 || isempty(fieldnames(snapshot))
                return
            end

            prefixes = Program.GUIHandling.pos_prefixes;
            for c = 1:min(6, numel(snapshot.channel_values))
                dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
                cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
                ref_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, c);

                if any(strcmp(app.(dd_handle).Items, snapshot.channel_values{c}))
                    app.(dd_handle).Value = snapshot.channel_values{c};
                end
                app.(cb_handle).Value = logical(snapshot.channel_enabled(c));

                if isprop(app.(ref_handle), 'Items') && isprop(app.(ref_handle), 'Value')
                    if any(strcmp(app.(ref_handle).Items, snapshot.channel_roles{c}))
                        app.(ref_handle).Value = snapshot.channel_roles{c};
                    end
                elseif isprop(app.(ref_handle), 'Text') && strlength(string(snapshot.channel_roles{c})) > 0
                    app.(ref_handle).Text = char(string(snapshot.channel_roles{c}));
                end
            end

            for n = 1:min(numel(prefixes), numel(snapshot.gamma_values))
                app.(sprintf('%s_GammaEditField', prefixes{n})).Value = snapshot.gamma_values(n);
                app.(sprintf('%s_hist_slider', prefixes{n})).Value = snapshot.hist_values{n};
                app.(sprintf('%s_hist_ax', prefixes{n})).XLim = snapshot.hist_values{n};
                Program.GUIHandling.sync_processing_window_fields(app, prefixes{n});
            end

            app.HidezerointensitypixelsCheckBox.Value = logical(snapshot.hide_zero);
            app.ProcShowMIPCheckBox.Value = logical(snapshot.show_mip);
            app.ProcPreviewZslowCheckBox.Value = logical(snapshot.preview_zslow);
            app.ProcXYFactorEditField.Value = snapshot.xy_factor;
            app.ProcZSlicesEditField.Value = snapshot.z_slices;
            Program.GUIHandling.sanitize_processing_downsample_fields(app);
            Program.GUIHandling.update_processing_histogram_interactivity(app);
            Program.GUIHandling.update_processing_threshold_target_options(app);
            Program.GUIHandling.update_processing_zslider_visibility(app);
        end

        function tf = processing_channel_windows_active(app)
            if nargin < 1
                app = Program.app;
            end

            state = Program.Handlers.channels.processing_state(app);
            tf = false;
            for n = 1:numel(state.rows)
                row = state.rows(n);
                if row.source_idx <= 0
                    continue
                end

                low_high = double(row.settings.low_high_in);
                if isempty(low_high)
                    continue
                end

                if numel(low_high) == 2 && any(abs(low_high(:)' - [0 1]) > (0.5 / 255))
                    tf = true;
                    return
                end
            end
        end

        function actions = processing_file_actions(app)
            if nargin < 1
                app = Program.app;
            end

            actions = fieldnames(app.flags)';
            if Program.GUIHandling.processing_channel_windows_active(app)
                actions = [{'window'}, actions];
            end
        end

        function reset_processing_runtime_state(app)
            app.flags = struct();
            Program.GUIHandling.clear_processing_zslider_event_listeners(app);
            if isappdata(app.CELL_ID, 'proc_mip_cache')
                rmappdata(app.CELL_ID, 'proc_mip_cache');
            end
            if isappdata(app.CELL_ID, 'proc_live_mip_cache')
                rmappdata(app.CELL_ID, 'proc_live_mip_cache');
            end
            if isappdata(app.CELL_ID, 'proc_view_cache')
                rmappdata(app.CELL_ID, 'proc_view_cache');
            end
            if isappdata(app.CELL_ID, 'proc_render_cache')
                rmappdata(app.CELL_ID, 'proc_render_cache');
            end
            if isappdata(app.CELL_ID, 'proc_raw_cache')
                rmappdata(app.CELL_ID, 'proc_raw_cache');
            end
            if isappdata(app.CELL_ID, 'proc_histogram_signature')
                rmappdata(app.CELL_ID, 'proc_histogram_signature');
            end
            if isappdata(app.CELL_ID, 'proc_render_view_dims')
                rmappdata(app.CELL_ID, 'proc_render_view_dims');
            end
            if isappdata(app.CELL_ID, 'proc_live_z_value')
                rmappdata(app.CELL_ID, 'proc_live_z_value');
            end
            if isappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks')
                rmappdata(app.CELL_ID, 'proc_suspend_zslider_callbacks');
            end
            Program.GUIHandling.clear_rotation_preview_cache(app);
            Program.GUIHandling.reset_rotation_controls(app);

            app.spectral_cache = Methods.ChunkyMethods.spectral_cache_template();
            spectral_prefixes = {'red', 'green', 'blue', 'background'};
            spectral_channels = {'r', 'g', 'b'};
            for i = 1:numel(spectral_prefixes)
                for j = 1:numel(spectral_channels)
                    field_name = sprintf('%s_%s', spectral_prefixes{i}, spectral_channels{j});
                    if isprop(app, field_name) && isvalid(app.(field_name))
                        app.(field_name).Value = 0;
                    end
                end
            end

            if isprop(app, 'rotation_stack')
                if isfield(app.rotation_stack, 'cache')
                    app.rotation_stack.cache = struct('Colormap', {{}}, 'Video', {{}});
                end
                if isfield(app.rotation_stack, 'gui')
                    try
                        cellfun(@delete, app.rotation_stack.gui(~cellfun('isempty', app.rotation_stack.gui)));
                    catch
                    end
                    app.rotation_stack.gui = {};
                end
                if isfield(app.rotation_stack, 'listeners')
                    try
                        cellfun(@delete, app.rotation_stack.listeners(~cellfun('isempty', app.rotation_stack.listeners)));
                    catch
                    end
                    app.rotation_stack.listeners = {};
                end
                if isfield(app.rotation_stack, 'roi')
                    try
                        if ~isempty(app.rotation_stack.roi) && isvalid(app.rotation_stack.roi)
                            delete(app.rotation_stack.roi);
                        end
                    catch
                    end
                    app.rotation_stack.roi = [];
                end
            end

            try
                Program.Routines.GUI.set_manipulation_panel('closed');
            catch
            end

            try
                Program.GUIHandling.configure_processing_sidebar_layout(app);
            catch
            end
        end

        function shorten_knob_labels(app)
            majorTicks = app.ProcNoiseThresholdKnob.MajorTicks;
            fixedLabels = cell(size(majorTicks));
            for n = 1:length(majorTicks)
                fixedLabels{n} = sprintf('%.0f', majorTicks(n));
            end

            app.ProcNoiseThresholdKnob.MajorTickLabels = fixedLabels;
        end

        function angle = canonical_rotation_angle(value)
            angle = mod(round(double(value)), 360);
            if abs(angle) < 1e-9 || abs(angle - 360) < 1e-9
                angle = 0;
            end
        end

        function clear_rotation_preview_cache(app)
            if isappdata(app.CELL_ID, 'proc_rotation_base_image')
                rmappdata(app.CELL_ID, 'proc_rotation_base_image');
            end
        end

        function cache_rotation_preview_base(app)
            current_img = getimage(app.proc_xyAxes);
            if isempty(current_img)
                return
            end
            setappdata(app.CELL_ID, 'proc_rotation_base_image', current_img);
        end

        function base_img = rotation_preview_base(app)
            if isappdata(app.CELL_ID, 'proc_rotation_base_image')
                base_img = getappdata(app.CELL_ID, 'proc_rotation_base_image');
                if ~isempty(base_img)
                    return
                end
            end

            base_img = getimage(app.proc_xyAxes);
            if ~isempty(base_img)
                setappdata(app.CELL_ID, 'proc_rotation_base_image', base_img);
            end
        end

        function set_rotation_sync_guard(app, state)
            setappdata(app.CELL_ID, 'proc_rotation_sync_guard', logical(state));
        end

        function tf = rotation_sync_guard(app)
            tf = isappdata(app.CELL_ID, 'proc_rotation_sync_guard') && ...
                logical(getappdata(app.CELL_ID, 'proc_rotation_sync_guard'));
        end

        function reset_rotation_controls(app)
            Program.GUIHandling.set_rotation_sync_guard(app, true);
            app.proc_rot_spinner.Value = 0;
            app.proc_rot_knob.Value = 0;
            app.flip_lr.Value = false;
            app.flip_ud.Value = false;
            Program.GUIHandling.set_rotation_sync_guard(app, false);
        end

        function refresh_rotation_preview(app)
            base_img = Program.GUIHandling.rotation_preview_base(app);
            if isempty(base_img)
                return
            end

            preview_img = base_img;

            if app.flip_lr.Value
                preview_img = preview_img(:, end:-1:1, :);
            end

            if app.flip_ud.Value
                preview_img = preview_img(end:-1:1, :, :);
            end

            angle = Program.GUIHandling.canonical_rotation_angle(app.proc_rot_spinner.Value);
            if angle ~= 0
                preview_img = imrotate(preview_img, angle);
            end

            image(app.proc_xyAxes, preview_img);
            app.proc_xyAxes.XLim(2) = size(preview_img, 2);
            app.proc_xyAxes.YLim(2) = size(preview_img, 1);
        end

        function handle_rotation_value_changed(app, value)
            if Program.GUIHandling.rotation_sync_guard(app)
                return
            end

            angle = Program.GUIHandling.canonical_rotation_angle(value);
            Program.GUIHandling.set_rotation_sync_guard(app, true);
            app.proc_rot_spinner.Value = angle;
            app.proc_rot_knob.Value = angle;
            Program.GUIHandling.set_rotation_sync_guard(app, false);
            Program.GUIHandling.refresh_rotation_preview(app);
        end

        function handle_rotation_flip_changed(app)
            if Program.GUIHandling.rotation_sync_guard(app)
                return
            end

            Program.GUIHandling.refresh_rotation_preview(app);
        end

        function target = dropper(message, display, image, z, radius)
            if nargin < 5 || isempty(radius) || ~isfinite(radius)
                radius = 1;
            end

            target = struct('pixels', {[]}, 'roi_pixels', {[]}, 'values', {[]});

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

                    if nargin >= 4 && ~isempty(z)
                        target.pixels = [pos(1), pos(2), z];
                    else
                        target.pixels = [pos(1), pos(2)];
                    end

                    target.roi_pixels = Program.GUIHandling.dropper_roi_pixels(image, target.pixels, radius);
                    target.values = Program.GUIHandling.dropper_roi_values(image, target.roi_pixels);

                case 'Select different slice'
                    return
            end
        end

        function roi_pixels = dropper_roi_pixels(image, pixels, radius)
            if nargin < 3 || isempty(radius) || ~isfinite(radius)
                radius = 1;
            end

            radius = max(1, round(double(radius)));
            x = min(max(round(double(pixels(1))), 1), size(image, 2));
            y = min(max(round(double(pixels(2))), 1), size(image, 1));

            if numel(pixels) >= 3
                z = min(max(round(double(pixels(3))), 1), size(image, 3));
            else
                z = [];
            end

            x_range = max(1, x - radius):min(size(image, 2), x + radius);
            y_range = max(1, y - radius):min(size(image, 1), y + radius);
            [xx, yy] = meshgrid(x_range, y_range);
            mask = (xx - x).^2 + (yy - y).^2 <= radius.^2;

            if isempty(z)
                roi_pixels = [xx(mask), yy(mask)];
            else
                roi_pixels = [xx(mask), yy(mask), repmat(z, nnz(mask), 1)];
            end
        end

        function values = dropper_roi_values(image, roi_pixels)
            if isempty(roi_pixels)
                values = [];
                return
            end

            if size(roi_pixels, 2) >= 3
                linear_idx = sub2ind(size(image, 1:3), ...
                    roi_pixels(:, 2), roi_pixels(:, 1), roi_pixels(:, 3));
                n_channels = size(image, 4);
                values = zeros(1, n_channels);

                for c = 1:n_channels
                    channel = image(:, :, :, c);
                    values(c) = mean(double(channel(linear_idx)), 'omitnan');
                end
            else
                linear_idx = sub2ind(size(image, 1:2), roi_pixels(:, 2), roi_pixels(:, 1));
                n_channels = size(image, 3);
                values = zeros(1, n_channels);

                for c = 1:n_channels
                    channel = image(:, :, c);
                    values(c) = mean(double(channel(linear_idx)), 'omitnan');
                end
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

function label = local_format_knob_tick(value)
    value = round(double(value));
    if value == 0
        label = '0';
        return
    end

    sign_prefix = '';
    if value < 0
        sign_prefix = '-';
        value = abs(value);
    end

    digits = char(string(value));
    reversed_digits = fliplr(digits);
    reversed_digits = regexprep(reversed_digits, '(\d{3})(?=\d)', '$1,');
    label = [sign_prefix, fliplr(reversed_digits)];
end
