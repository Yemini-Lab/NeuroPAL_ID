classdef channels
    %CHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        max_nc = 6;
        
        channel_options = {'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP', 'N/A'};

        up_signs = {"-1", "up", "⮝"};
        down_signs = {"1", "down", "⮟"};

        dd_string = "proc_c%.f_dropdown";
        cb_string = "proc_c%.f_checkbox";
        rep_string = "proc_c%.f_rep";
        grid_string = "EditChannelsGrid";
        button_string = "EditChannelsButton";

        label_colors = {'#000', '#000', '#fff', '#000', '#fff', '#000'};
        channel_colors = {'#ff0000', '#00d100', '#0000ff', '#fff', '#6b6b6b', '#ffff00'};

        fluorophore_mapping = dictionary( ...
            'red', {{'neptune', 'nep', 'n2.5', 'n25'}}, ...
            'green', {{'cyofp1', 'cyofp', 'cyo'}}, ...
            'blue', {'bfp'}, ...
            'white', {{'rfp', 'tagrfp', 'tagrfp1'}}, ...
            'dic', {{'dic', 'dia', 'nomarski', 'phase'}}, ...
            'gfp', {{'gfp', 'gcamp'}});
    end
    
    methods (Static, Access = public)
        function initialize(input)
            app = Program.GUI.app;
            [grid, ~] = Program.Handlers.channels.get_gui(app);

            if isfile(input) || ischar(input) || isstring(input)
                [nc, names] = Program.Handlers.channels.channels_from_file(input);
            else
                names = input;
                nc = length(names);
            end

            [names, ~] = Program.Handlers.channels.autosort(names);

            n_rows = length(grid.RowHeight);

            % Create any missing grid rows.
            for row=n_rows:nc
                Program.Handlers.channels.create_channel();
            end

            % Delete any excess grid rows.
            for row=n_rows:-1:nc+1
                Program.Handlers.channels.delete_channel(row, 1, 0);
            end

            % Populate gui components.
            for c=1:nc
                if isprop(app, sprintf(Program.Handlers.channels.dd_string, c))
                    dd = app.(sprintf(Program.Handlers.channels.dd_string, c));
                else
                    target = Program.Handlers.channels.get_channel(app, c);
                    dd = target.gui.dd;
                end

                dd.Items = names;
                dd.Value = names{c};
            end
            
            % Style non-rgb gui components.
            Program.Handlers.channels.load_styles();
        end

        function idx_struct = indices(reset_flag)
            persistent channel_indices

            if isempty(channel_indices) || nargin > 0
                metadata = DataHandling.Lazy.file.metadata;

                RGBWDG_active = Program.GUIHandling.active_channels;
                RGBWDG_idx = Program.GUIHandling.ordered_channels;

                channels_in_file = metadata.channels.order(metadata.channels.order~=metadata.channels.null_channels);
                full_load = Program.Debugging.Validation.render_indices(channels_in_file);

                lazy_load = channels_in_file(RGBWDG_active);
                lazy_load_permutation = ismember(lazy_load, RGBWDG_idx(RGBWDG_active));

                [~, render_permutation] = ismember(channels_in_file, RGBWDG_idx);
                render_permutation(render_permutation==0) = find(render_permutation==0);

                unrendered_RGB = find(~RGBWDG_active(1:3));

                channel_indices = struct( ...
                    'in_file', channels_in_file, ...
                    'full_load', full_load, ...
                    'lazy_load', channels_in_file(Program.GUIHandling.active_channels), ...
                    'lazy_load_permutation', lazy_load_permutation, ...
                    'render_permutation', render_permutation, ...
                    'unrendered_RGB', unrendered_RGB);
            end
            
            idx_struct = channel_indices;
        end

        function handles = create_channel()
            [grid, ~] = Program.Handlers.channels.get_gui();
            grid.RowHeight(end+1) = grid.RowHeight(end);

            handles = struct( ...
                'cb', {Program.GUI.channel.create_checkbox}, ...
                'dd', {Program.GUI.channel.create_dropdown}, ...
                'label', {Program.GUI.channel.create_label}, ...
                'move_up', {Program.GUI.channel.create_button('up')}, ...
                'move_down', {Program.GUI.channel.create_button('down')}, ...
                'delete', {Program.GUI.channel.create_button('delete')});
        end

        function update_channel(event)
            app = Program.GUIHandling.app;

            newValue = event.Value;
            oldValue = event.PreviousValue;
            
            dropdowns = [];
            switch event.Source.Layout.Column
                case 3
                    for dd=4:length(event.Source.Items)+3
                        component = app.(sprintf(Program.Handlers.channels.rep_string, dd));
                        if isgraphics(component)
                            dropdowns = [dropdowns, component];
                        end
                    end
                    
                case 4
                    for dd=1:length(event.Source.Parent.RowHeight)
                        target = Program.Handlers.channels.get_channel(app, dd);
                        dropdowns = [dropdowns, target.gui.dd];
                    end
            end
            
            otherDropdowns = setdiff(dropdowns, event.Source);
            for k = 1:length(otherDropdowns)
                if strcmp(otherDropdowns(k).Value, newValue)
                    otherDropdowns(k).Value = oldValue;
                    break;
                end
            end
        end

        function channel = get_channel(target)
            app = Program.GUIHandling.app;
            dd_name = sprintf(Program.Handlers.channels.dd_string, target);
            cb_name = sprintf(Program.Handlers.channels.cb_string, target);
            components = struct('dd', {{}}, 'cb', {{}});

            if isprop(app, dd_name)
                components.dd = app.(dd_name);
                components.cb = app.(cb_name);
    
                channel = struct( ...
                    'idx', target, ...
                    'gui', {components}, ...
                    'cached_values', {struct('dd', {components.dd.Value}, 'cb', {components.cb.Value})});

            else
                [grid, ~] = Program.Handlers.channels.get_gui;
                for n=1:length(grid.Children)
                    child = grid.Children(n);
                    if child.Layout.Row==target && isa(child, 'matlab.ui.control.CheckBox')
                        components.cb = child;
                    elseif child.Layout.Row==target && isa(child, 'matlab.ui.control.DropDown')
                        components.dd = child;
                    end
                end
    
                channel = struct( ...
                    'idx', target, ...
                    'gui', {components}, ...
                    'cached_value', {struct('dd', {components.dd.Value}, 'cb', {components.cb.Value})});
            end
        end
        
        function move_channel(channel, direction)
            direction = -1+2*(any(ismember(direction, [Program.Handlers.channels.down_signs{:}])));
            target = Program.Handlers.channels.get_channel(channel);

            if Program.Handlers.channels.can_move(target.gui.dd, direction)
                neighbor = Program.Handlers.channels.get_channel(channel + direction);

                target.gui.dd.Value = neighbor.cached_values.dd;
                neighbor.gui.dd.Value = target.cached_values.dd;

                target.gui.cb.Value = neighbor.cached_values.cb;
                neighbor.gui.cb.Value = target.cached_values.cb;
            end

            Program.Handlers.histograms.update;
        end

        function delete_channel(app, channel, permanence_flag, from_file)
            target = Program.Handlers.channels.get_channel(app, channel);

            if permanence_flag
                grid = target.gui.dd.Parent;

                for n=numel(grid.Children):-1:1
                    child = grid.Children(n);
                    if child.Layout.Row == channel
                        delete(child)
                    end
                end

                temp_rows = grid.RowHeight;
                temp_rows(channel) = [];
                grid.RowHeight = temp_rows;
            else
                %target.gui.dd.Value = "N/A";
                target.gui.dd.Enable = "off";
    
                target.gui.cb.Value = 0;
                target.gui.cb.Enable = "off";

                app.(sprintf(Program.Handlers.channels.up_string, channel)).Enable = "off";
                app.(sprintf(Program.Handlers.channels.down_string, channel)).Enable = "off";
                app.(sprintf(Program.Handlers.channels.del_string, channel)).Enable = "off";
            end

            if from_file
                Methods.ChunkyMethods.delete_channel(channel);
            end

            Program.Handlers.histograms.update;
        end

        function g_value = gamma(channel)
            component_name = sprintf("%s_GammaEditField", ...
                Program.Handlers.handles.ch_pfx{channel});
            g_value = app.(component_name).Value;
        end

        function idx = rgb()
            app = Program.GUI.app;
            idx = [ ...
                str2num(app.ProcRDropDown.Value),  ...
                str2num(app.ProcGDropDown.Value),  ...
                str2num(app.ProcBDropDown.Value)];
        end

        function set_idx(order)
            if nargin > 0
                order = [1 2 3 4 5 6];
            end

            Program.GUI.indices('red', order(1));
            Program.GUI.indices('green', order(2));
            Program.GUI.indices('blue', order(3));
            Program.GUI.indices('white', order(4));
            Program.GUI.indices('dic', order(5));
            Program.GUI.indices('gfp', order(6));
        end

        function set_gammas(gammas)
            if nargin > 0
                gammas = [1 1 1 1 1 1];
            end

            Program.GUI.gammas(gammas);
        end
    end

    methods (Static, Access = private)
        function [grid, edit_button] = get_gui()
            persistent handles

            if isempty(handles) || any(~isgraphics(handles))
                app = Program.GUIHandling.app;
                handles = struct( ...
                    'grid', {app.(Program.Handlers.channels.grid_string)}, ...
                    'button', {app.(Program.Handlers.channels.button_string)});
            end

            grid = handles.grid;
            edit_button = handles.button;
        end

        function has_space = can_move(channel, direction)
            switch num2str(direction)
                case Program.Handlers.channels.up_signs
                    has_space = channel.Layout.Row > 1;
                case Program.Handlers.channels.down_signs
                    has_space = channel.Layout.Row < length(channel.Parent.RowHeight);
            end
        end

        function handle = create_checkbox()
            [grid, ~] = Program.Handlers.channels.get_gui;

            handle = uicheckbox(grid);
            handle.Text = '';
            handle.Layout.Row = length(grid.RowHeight);
            handle.Layout.Column = 1;
        end

        function handle = create_dropdown()
            [grid, ~] = Program.Handlers.channels.get_gui;

            handle = uidropdown(grid);
            handle.Items = Program.GUI.channel.channel_options;
            handle.Value = 'Red';
            handle.Layout.Column = [3 4];
        end

        function handle = create_label()
            [grid, ~] = Program.Handlers.channels.get_gui;
            
            handle = uilabel(grid);
            handle.BackgroundColor = [0.902 0.902 0.902];
            handle.HorizontalAlignment = 'center';
            handle.FontWeight = 'bold';
            handle.Text = num2str(handle.Layout.Row);
        end

        function handle = create_button(label)
            [grid, ~] = Program.Handlers.channels.get_gui;

            handle = uibutton(grid, 'push');
            handle.ButtonPushedFcn = @app.proc_c1_move_upPushed2;
            handle.Text = label;

            if strcmp(label, '🗑')
                handle.BackgroundColor = [1 0.2784 0.2784];
                handle.FontWeight = 'bold';
            end
        end

        function load_styles()
            app = Program.GUI.app;

            non_rgb = keys(Program.Handlers.channels.fluorophore_mapping);
            non_rgb = non_rgb(4:end);

            for c=1:length(non_rgb)
                component = app.(sprintf(Program.Handlers.channels.rep_string, c+3));

                if ~isgraphics(component)
                    continue
                end

                for item=1:length(component.Items)
                    style_idx = item+3;
                    rep_style = uistyle( ...
                        "FontColor", Program.Handlers.channels.label_colors{style_idx}, ...
                        "FontWeight", "bold", ...
                        "BackgroundColor", Program.Handlers.channels.channel_colors{style_idx});
                    addStyle(component, rep_style, "item", item);

                end
            end
        end
    end
end

