classdef channel_handler
    %CHANNEL_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Access=public)
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
    
    methods (Static)
        function [f_nc, f_ch_names, f_ch_order] = channels_from_file(file)
            [~, ~, fmt] = fileparts(file);

            switch fmt
                case '.nd2'
                    f_data = bfopen(file);
                    f_metadata = f_data{cellfun(@(x)isa(x,'java.util.Hashtable'), f_data)};
                    f_metadata_keys = string(f_metadata.keySet.toArray);
                    f_ch_idx = contains(f_metadata_keys, 'Global Name #');
                    f_ch_str = string({f_metadata_keys{f_ch_idx}});
                    f_ch_order = string({f_ch_str{end:-1:1}});
                    f_ch_names = string(cellfun(@(x)f_metadata.get(x), f_ch_order, 'UniformOutput', false));
                    f_ch_names = f_ch_names(f_ch_names~="NA");
                    f_nc = length(f_ch_names);

                    fprintf("File %s contains %.f channels in this order:\n%s\n%s.", file, f_nc, join(f_ch_order, ', '), join(f_ch_names, ', '))

                case '.nwb'
                case '.mat'
            end
        end

        function [sorted_names, permute_record] = autosort(channels)
            channels = string(channels(:));
            n_names = numel(channels);
        
            f_ch_names_lower = lower(channels);
        
            labels_order = keys(Program.channel_handler.fluorophore_mapping);
        
            labels = strings(n_names, 1);
        
            for j = 1:numel(labels_order)
                key = labels_order{j};
                synonyms = Program.channel_handler.fluorophore_mapping(key);
                synonyms_lower = lower(string(synonyms{1}));
        
                is_match = ismember(f_ch_names_lower, synonyms_lower);
                labels(is_match) = key;
            end
        
            sorted_names = strings(0, 1);
            permute_record = [];
        
            for j = 1:numel(labels_order)
                key = labels_order{j};

                idx = find(labels == key);

                sorted_names = [sorted_names; channels(idx)];
                permute_record = [permute_record; idx];
            end
        
            unmatched_idx = find(labels == "");
            if ~isempty(unmatched_idx)
                sorted_names = [sorted_names; channels(unmatched_idx)];
                permute_record = [permute_record; unmatched_idx];
            end

        end

        function initialize(app, input)
            [ch_grid, ~] = Program.channel_handler.get_gui(app);
            n_rows = length(ch_grid.RowHeight);

            if isfile(input) || ischar(input) || isstring(input)
                [nc, names] = Program.channel_handler.channels_from_file(input);
            else
                names = input;
                nc = length(names);
            end

            [names, ~] = Program.channel_handler.autosort(names);

            % Create any missing grid rows.
            for row=n_rows:nc
                Program.channel_handler.create_channel(app, ch_grid);
            end

            % Delete any excess grid rows.
            for row=n_rows:-1:nc+1
                Program.channel_handler.delete_channel(app, row, 1, 0);
            end

            % Populate gui components.
            for c=1:nc
                if isprop(app, sprintf(Program.channel_handler.dd_string, c))
                    dd = app.(sprintf(Program.channel_handler.dd_string, c));
                else
                    target = Program.channel_handler.get_channel(app, c);
                    dd = target.gui.dd;
                end

                dd.Items = names;
                dd.Value = names{c};
            end
            
            % Style non-rgb gui components.
            non_rgb = keys(Program.channel_handler.fluorophore_mapping);
            non_rgb = non_rgb(4:end);
            for c=1:length(non_rgb)
                component = app.(sprintf(Program.channel_handler.rep_string, c+3));
                if isgraphics(component)
                    for item=1:length(component.Items)
                        style_idx = item+3;
                        rep_style = uistyle( ...
                            "FontColor", Program.channel_handler.label_colors{style_idx}, ...
                            "FontWeight", "bold", ...
                            "BackgroundColor", Program.channel_handler.channel_colors{style_idx});
                        addStyle(component, rep_style, "item", item);
                    end
                end
            end
        end

        function update_channel(app, event)
            % Get the new and old values from the event data
            newValue = event.Value;
            oldValue = event.PreviousValue;
            
            % Get handles to all the dropdowns (replace with your actual dropdown names)
            dropdowns = [];
            switch event.Source.Layout.Column
                case 3
                    for dd=4:length(event.Source.Items)+3
                        component = app.(sprintf(Program.channel_handler.rep_string, dd));
                        if isgraphics(component)
                            dropdowns = [dropdowns, component];
                        end
                    end
                    
                case 4
                    for dd=1:length(event.Source.Parent.RowHeight)
                        target = Program.channel_handler.get_channel(app, dd);
                        dropdowns = [dropdowns, target.gui.dd];
                    end
            end
            
            % Exclude the dropdown that was just changed
            otherDropdowns = setdiff(dropdowns, event.Source);
            
            % Loop over the other dropdowns to find any that have the new value
            for k = 1:length(otherDropdowns)
                if strcmp(otherDropdowns(k).Value, newValue)
                    % Found a duplicate
                    % Change the conflicting dropdown's value to the old value
                    otherDropdowns(k).Value = oldValue;
                    break; % Exit loop after handling the first duplicate
                end
            end
        end

        function handles = create_channel(app, ch_grid)
            if ~exist('grid', 'var') || ~exist('button', 'var')
                [ch_grid, ~] = Program.channel_handler.get_gui(app);
            end

            ch_grid.RowHeight(end+1) = ch_grid.RowHeight(end);

            handles = struct('cb', {{}});

            handles.cb = uicheckbox(ch_grid);
            handles.cb.Text = '';
            handles.cb.Layout.Row = length(ch_grid.RowHeight);
            handles.cb.Layout.Column = 1;

            handles.num = uilabel(ch_grid);
            handles.num.BackgroundColor = [0.902 0.902 0.902];
            handles.num.HorizontalAlignment = 'center';
            handles.num.FontWeight = 'bold';
            handles.num.Text = num2str(handles.cb.Layout.Row);

            handles.dd = uidropdown(ch_grid);
            handles.dd.Items = {'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP', 'N/A'};
            handles.dd.Value = 'Red';
            handles.cb.Layout.Column = [3 4];

            handles.move_up = uibutton(ch_grid, 'push');
            handles.move_up.ButtonPushedFcn = @app.proc_c1_move_upPushed2;
            handles.move_up.Text = '⮝';

            handles.move_down = uibutton(ch_grid, 'push');
            handles.move_down.ButtonPushedFcn = @app.proc_c1_move_upPushed2;
            handles.move_down.Text = '⮟';

            handles.delete = uibutton(ch_grid, 'push');
            handles.delete.ButtonPushedFcn = @app.proc_c1_move_upPushed2;
            handles.delete.BackgroundColor = [1 0.2784 0.2784];
            handles.delete.FontWeight = 'bold';
            handles.delete.Text = '🗑';
        end

        function channel = get_channel(app, target)
            dd_name = sprintf(Program.channel_handler.dd_string, target);
            cb_name = sprintf(Program.channel_handler.cb_string, target);
            components = struct('dd', {{}}, 'cb', {{}});

            if isprop(app, dd_name)
                components.dd = app.(dd_name);
                components.cb = app.(cb_name);
    
                channel = struct( ...
                    'idx', target, ...
                    'gui', {components}, ...
                    'cached_values', {struct('dd', {components.dd.Value}, 'cb', {components.cb.Value})});
            else
                [ch_grid, ~] = Program.channel_handler.get_gui(app);
                for n=1:length(ch_grid.Children)
                    child = ch_grid.Children(n);
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

        function has_space = can_move(channel, direction)
            switch num2str(direction)
                case Program.channel_handler.up_signs
                    has_space = channel.Layout.Row > 1;
                case Program.channel_handler.down_signs
                    has_space = channel.Layout.Row < length(channel.Parent.RowHeight);
            end
        end
        
        function move_channel(app, channel, direction)
            direction = -1+2*(any(ismember(direction, [Program.channel_handler.down_signs{:}])));
            target = Program.channel_handler.get_channel(app, channel);

            if Program.channel_handler.can_move(target.gui.dd, direction)
                neighbor = Program.channel_handler.get_channel(app, channel + direction);

                target.gui.dd.Value = neighbor.cached_values.dd;
                neighbor.gui.dd.Value = target.cached_values.dd;

                target.gui.cb.Value = neighbor.cached_values.cb;
                neighbor.gui.cb.Value = target.cached_values.cb;
            end

            %Program.GUIHandling.histogram_handler(app, 'draw');
        end
        
        function delete_channel(app, channel, permanence_flag, from_file)
            target = Program.channel_handler.get_channel(app, channel);

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

                app.(sprintf(Program.channel_handler.up_string, channel)).Enable = "off";
                app.(sprintf(Program.channel_handler.down_string, channel)).Enable = "off";
                app.(sprintf(Program.channel_handler.del_string, channel)).Enable = "off";
            end

            if from_file
                Methods.ChunkyMethods.delete_channel(channel);
            end

            %Program.GUIHandling.histogram_handler(app, 'draw');
        end

        function [grid, edit_button] = get_gui(app)
            grid = app.(Program.channel_handler.grid_string);
            edit_button = app.(Program.channel_handler.button_string);
        end
    end
end

