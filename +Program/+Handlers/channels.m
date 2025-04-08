classdef channels
    
    properties (Constant)

        % Dictionary of string patterns for each type of channel component.
        handles = dictionary( ...
            'id_pfx', {{'R', 'G', 'B', 'W', 'DIC', 'GFP'}}, ...             % Handle prefixes in the legacy components present in the ID tab.
            'pp_ef', {'proc_c%.f_editfield'}, ...                           % Edit fields.
            'pp_dd', {'proc_c%.f_dropdown'}, ...                            % Dropdowns.
            'pp_cb', {'proc_c%.f_checkbox'}, ...                            % Checkboxes.
            'pp_ref', {'proc_c%.f_ref'}, ...                                % Reference dropdowns.
            'pp_grid', {'EditChannelsGrid'}, ...                            % Grid.
            'pp_button', {'EditChannelsButton'}, ...                        % Edit channel button.
            'pp_down', {{'1', 'down', '⮟'}}, ...                           % Buttons that move channels up in the grid.
            'pp_up', {{'-1', 'up', '⮝'}});                                 % Buttons that move channels down in the grid.

        % Dictionary of channel colors and their respective fluorophores.
        fluorophore_map = dictionary( ...
            'red', {{'neptune', 'nep', 'n2.5', 'n25'}}, ...
            'green', {{'cyofp1', 'cyofp', 'cyo'}}, ...
            'blue', {{'bfp'}}, ...
            'white', {{'rfp', 'tagrfp', 'tagrfp1'}}, ...
            'dic', {{'dic', 'dia', 'nomarski', 'phase', 'dic1', 'dic2'}}, ...
            'gfp', {{'gfp', 'gcamp'}});

        % Dictionary of various channel name formats.
        names = dictionary( ...
            'short', {{'r', 'g', 'b', 'w', 'dic', 'gfp'}}, ...
            'color', {{'red', 'green', 'blue'}}, ...
            'long', {{'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'}}, ...
            'histogram_grid', {{'tl', 'tm', 'tr', 'bl', 'bm', 'br'}});

        % Dictionary containing various settings.
        config = dictionary( ...
            'default_gamma', {0.8}, ...                                     % Default gamma to be used if no gamma is specified for a channel.
            'max_channels', {6}, ...                                        % Maximum number of channels our GUI supports on initial load.
            'label_colors', {{ ...                                          % Colors of text labels for each color...
                '#000', ...                                                 %   Red     -> Black
                '#000', ...                                                 %   Green   -> Black
                '#fff', ...                                                 %   Blue    -> White (Black is too dark to be legible on blue backgrounds)
                '#000', ...                                                 %   White   -> Black
                '#fff', ...                                                 %   DIC     -> White (Black is too dark to be legible on grey backgrounds)
                '#000'}}, ...                                               %   GFP     -> Black
            'channel_colors', {{ ...                                        % Background colors for UI components associated with a given color...
                '#ff0000', ...                                              %   Red     -> Red
                '#00d100', ...                                              %   Green   -> Green
                '#0000ff', ...                                              %   Blue    -> Blue
                '#fff', ...                                                 %   White   -> White
                '#6b6b6b', ...                                              %   DIC     -> Grey
                '#ffff00'}});                                               %   GFP     -> Yellow
    end
    
    methods (Static)        
        function set_references(info)
            %  set_references   Updates item properties of reference dropdowns.
            % ┌─────────────────────────────────────────────────────────────┐
            % │ Description:                                                │
            % │     This function sets the item property of every reference │
            % │     related dropdown component in accordance with the info  │
            % │     struct that was loaded from a given NeuroPAL file.      │
            % │                                                             │
            % │ ----------------------------------------------------------- │
            % │                                                             │
            % │ Args:                                                       │
            % │   - info (struct): info field loaded from a NeuroPAL file.  │
            % └─────────────────────────────────────────────────────────────┤ Reminder:
            %                                                               ↓ Please don't forget to add comments!

            % Grab variables to be referenced below.
            app = Program.app;                                              % Grab application handle.
            ref_handle = Program.Handlers.channels.handles{'pp_ref'};       % Grab component handle string pattern for reference dropdowns.
            references = app.(sprintf(ref_handle, 4)).Items;                % Grab all currently loaded references (by default, this is {'White', 'GFP', 'DIC'}).
            loaded_fluos = app.(sprintf( ...                                % Grab all loaded fluorophores.
                Program.Handlers.channels.handles{'pp_dd'}, 1)).Items; 

            % From the array of loaded references, remove unused ones.
            for r=4:3+length(references)                                    % For every known reference...
                reference = references{r-3};                                % Get its name.

                if isfield(info, reference) && info.(reference) == 0        % If this reference is optional & not present...
                    references{r-3} = 'None';                               % Rename it to None.

                else                                                        % Otherwise...
                    related_fluos = ...                                     % Grab a cell array of valid fluorophores associated with this reference.
                        Program.Handlers.channels.fluorophore_map{lower(reference)};

                    if ~isempty(related_fluos) && ...                       % If we don't know of fluorophores related to this reference...
                        ~any(ismember(related_fluos, lower(loaded_fluos)))  % ...or such a fluorophore is not currently loaded...
                        references{r-3} = '???';                            % Set the reference name to ???.
                    end
                end
            end

            references = references(~strcmp(references, 'None'));           % Remove any loaded references we've set to None.

            % Update reference dropdowns.
            for r=length(app.proc_channel_grid.RowHeight):-1:4              % For every reference channel dropdown...

                if r-3 <= length(references)                                 % If there is a reference for this dropdown...
                    handle = sprintf(ref_handle, r);                        % Get the component handle.
                    app.(handle).Items = references;                        % Update its items property.
                    app.(handle).Value = references{r-3};                   % Set its value to the appropriate reference name.

                else                                                        % If there isn't a reference for this dropdown...
                    Program.Handlers.channels.delete(r);                    % Delete the excess channel.
                end
            end
        end

        function add_reference(name)
            %  add_reference   Adds one or more reference names to UI elements.
            % ┌─────────────────────────────────────────────────────────────┐
            % │ Description:                                                │
            % │   This function updates the reference-related UI components │
            % │   so they include the provided reference name(s).           │
            % │                                                             │
            % │ ----------------------------------------------------------- │
            % │                                                             │
            % │ Args:                                                       │
            % │   - name (char | string | cell): The name of the reference  │
            % │     to be added. If multiple references are passed in a     │
            % │     cell array, the function iterates over each.            │
            % │                                                             │
            % │ ----------------------------------------------------------- │
            % │                                                             │
            % │ Notes:                                                      │
            % │   - If 'name' is not a string/char and is not scalar, it's  │
            % │     treated as a collection (e.g., cell array).             │
            % └─────────────────────────────────────────────────────────────┤ Reminder:
            %                                                               ↓ Please don't forget to add comments!

            % Ensure input argument is a single string/char.
            if ~ischar(name) && ~isstring(name) && ~isscalar(name)          % If the input 'name' is not a single string/char...
                for n = 1:length(name)                                      % Iterate over each entry in the collection.
                    Program.Handlers.channels.add_reference(name{n});       % Recursively call add_reference for each entry.
                end
                return;                                                     % After adding each item, exit the function.
            end
        
            % Add new reference to all reference dropdowns.
            app = Program.app;                                              % Retrieve application handle from the global Program object.
            for r = 4:6                                                     % For each row in 4 through 6, update the Items in the corresponding UI component.
                handle = sprintf( ...                                       % Generate the component handle string based on "pp_ref" pattern and row index.
                    Program.Handlers.channels.handles{'pp_ref'}, r);
                
                app.(handle).Items{end+1} = name;                           % Append the new reference name to the Items property of that component.
            end
        end


        function remove_reference(name)
            %  remove_reference   Removes a specified reference name from UI elements.
            % ┌─────────────────────────────────────────────────────────────┐
            % │ Description:                                                │
            % │   This function removes the specified reference name from   │
            % │   the set of reference dropdowns in rows 4 through          │
            % │   'length(supported_references)'. If the reference is       │
            % │   currently selected, the corresponding channel is deleted. │
            % │   Otherwise, only the reference name is removed from the    │
            % │   dropdown.                                                 │
            % │                                                             │
            % │ ----------------------------------------------------------- │
            % │                                                             │
            % │ Args:                                                       │
            % │   - name (char | string): The name of the reference to be   │
            % │     removed from the UI elements.                           │
            % │                                                             │
            % │ ----------------------------------------------------------- │
            % │                                                             │
            % │ Notes:                                                      │
            % │   - 'supported_references' must be available in scope here. │
            % │   - The loop iterates backward from the highest reference   │
            % │     index down to row 4.                                    │
            % └─────────────────────────────────────────────────────────────┤ Reminder:
            %                                                               ↓ Please don't forget to add comments!
        
            % Grab variables to be referenced below.
            app = Program.app;                                                    % Retrieve application handle from the global Program object.
            ref_handle = Program.Handlers.channels.handles{'pp_ref'};             % Retrieve reference handle pattern ("pp_ref").
            current_references = app.(sprintf(ref_handle, 4)).Items;              % Store existing reference Items from row 4 for comparison.
        
            % Remove reference name from all reference GUI objects.
            for r = length(supported_references):-1:4                             % Iterate backward from the last reference index down to row 4.
                handle = sprintf(ref_handle, r);                                  % Generate the UI component handle name for row r.
        
                if strcmp(app.(handle).Value, name)                               % If this dropdown's current value matches the target reference...
                    Program.Handlers.channels.delete(r);                          % ...delete the entire channel.
                else
                    app.(handle).Items = {                                        % Otherwise, exclude the matching name
                        current_references{~strcmp(current_references, name)} };  % from the Items property of this dropdown.
                end
            end
        end


        function delete(channel)
            %  Delete a channel from the processing tab.
            % ┌─────────────────────────────────────────────────────────────┐
            % │ Notes:                                                      │
            % │  - If the channel is last in the grid layout, we simply     │
            % │    delete it. Otherwise, we move all channels one row down  │
            % │    first.                                                   │
            % │                                                             │
            % │ ----------------------------------------------------------- │
            % │                                                             │
            % │ Args:                                                       │
            % │  - channel (double | string | char):                        │
            % │     Either the row number or the name of the channel to be  │
            % │     deleted.                                                │
            % └─────────────────────────────────────────────────────────────┤ Reminder:
            %                                                               ↓ Please don't forget to add comments!

            % Ensure input argument is either a name or an index.
            if ~ismember(class(channel), {'string', 'char', 'double'})      % If input argument is not an index or a name...
                return                                                      % Skip the rest of the function.
            end

            % Define variables to be referenced below.
            app = Program.app;                                              % Grab application handle.
            handles = Program.Handlers.channels.get_handles();              % Get struct containing all handle string patterns.
            components = fieldnames(handles);                               % Get cell array of component types.
            n_channels = length(app.proc_channel_grid.RowHeight);                   % Get total number of channels.
            component_properties = {'Value', 'Items'};                      % Create cell array of component properties to transfer.

            % If input argument is a name, resolve to index.
            if isa(channel, "string") || isa(channel, "char")               % If input argument is a channel name...
                for c=1:n_channels                                          % For all channels,
                    channel_name = app.(sprintf(handles.dd, c)).Value;      % Grab the channel name.
                    if strcmp(channel_name, channel)                        % If channel name matches target channel...
                        channel = c;                                        % Grab index.
                        break                                               % Skip remaining channels.
                    end
                end
            end
                                 
            % Transfer component properties if necessary, then delete.
            for n=1:length(components)                                      % For each component type...
                handle = handles.(components{n});                   
                                                                    
                if channel == n_channels                                    % If this is the last channel in the grid, we just delete it.
                    this_component = sprintf(handle, channel);         
                    delete(app.(this_component));                      
                else                                                        % If this is not the last channel in the grid...
                    for p=channel+1:n_channels                              % For each channel that comes after it in the grid...
                        this_component = app.( ...                          % Grab the component handle.
                            sprintf(handle, p));             
                        previous_component = app.( ...                      % Grab the handle of the component for the channel ahead of it.
                            sprintf(components{n}, p-1));           
                        for c=1:length(component_properties)                % Transfer property values of channel to that of the ahead of it.
                            property = component_properties{c};     
                            if isprop(this_component, property)     
                                previous_component.(property) = ... 
                                    this_component.(property);      
                            end                                     
                        end                                         
                    end                                             
                                                                    
                    last_component = app.( ...                              % Get the component handle of the last channel in the grid.
                        sprintf(components{n}, n_channels));        
                    delete(last_component);                                 % Delete it.
                end                                                 
            end                                                     

            app.proc_channel_grid.RowHeight(channel) = [];
        end

        function populate(order)
            app = Program.app;
            names = order.names;
            indices = order.idx;
            nc = length(indices);

            [indices, ~, ~] = Program.Validation.check_for_duplicate_fluorophores(indices);

            n_rows = length(app.proc_channel_grid.RowHeight);
            if n_rows < nc
                for c=1:(nc-n_rows)
                    Program.Handlers.channels.add_channel();
                end
            end

            for c=1:nc
                cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
                app.(cb_handle).Value = c <= 3;

                dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);

                if ~isempty(names)
                    app.(dd_handle).Items = names;
                end

                name = app.(dd_handle).Items{indices(c)};
                if indices(c) ~= 0
                    app.(dd_handle).Value = name;
                end
            end
        end

        function channel_struct = get_channel_struct()
            [r, g, b, white, dic, gfp] = Program.Handlers.channels.parse_channel_gui();
            channel_struct = struct( ...
                'r', {r}, ...
                'g', {g}, ...
                'b', {b}, ...
                'white', {white}, ...
                'dic', {dic}, ...
                'gfp', {gfp});
        end

        function [r, g, b, white, dic, gfp, other] = parse_channel_gui()
            app = Program.app;
            indices = Program.Handlers.channels.get_channel_idx();
            references = lower(app.(sprintf(Program.Handlers.channels.handles{'pp_ref'}, 4)).Items);
            nc = length(app.proc_channel_grid.RowHeight);

            r = struct( ...
                'idx', indices.r, ...
                'bool', app.proc_c1_checkbox.Value, ...
                'settings', Program.Handlers.channels.get_processing_info('r'));

            if nc > 2
                g = struct( ...
                    'idx', indices.g, ...
                    'bool', app.proc_c2_checkbox.Value, ...
                    'settings', Program.Handlers.channels.get_processing_info('g'));
            else
                g = struct('idx', indices.r, 'bool', 0);
            end

            if nc > 2
                b = struct( ...
                    'idx', indices.b, ...
                    'bool', app.proc_c3_checkbox.Value, ...
                    'settings', Program.Handlers.channels.get_processing_info('b'));
            else
                b = struct('idx', indices.r, 'bool', 0);
            end

            if nc > 3
                white = struct('idx', indices.white, 'settings', Program.Handlers.channels.get_processing_info('white'));
                if ismember('white', references)
                    white.bool = app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, Program.Helpers.decode_references('white'))).Value;
                else
                    white.bool = 0;
                end
    
                dic = struct('idx', indices.dic, 'settings', Program.Handlers.channels.get_processing_info('dic'));
                if ismember('dic', references)
                    dic.bool = app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, Program.Helpers.decode_references('dic'))).Value;
                else
                    dic.bool = 0;
                end
    
                gfp = struct('idx', indices.gfp, 'settings', Program.Handlers.channels.get_processing_info('gfp'));
                if ismember('gfp', references)
                    gfp.bool = app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, Program.Helpers.decode_references('gfp'))).Value;
                else
                    gfp.bool = 0;
                end
    
                n_rows = length(app.proc_channel_grid.RowHeight);
                n_max = Program.Handlers.channels.config{'max_channels'};
                other = {};
                for n=n_max+1:n_rows
                    cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, n);
                    color_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, n);
                    other{end+1} = struct( ...
                        'idx', indices.other(n-n_max), ...
                        'bool', {app.(cb_handle).Value}, ...
                        'color', {app.(color_handle).Value});
                end
            else
                white = struct('bool', 0);
                dic = struct('bool', 0);
                gfp = struct('bool', 0);
                other = {};
            end
        end        

        function bools = get_bools(mode)
            app = Program.app;

            if nargin < 1
                mode = 'array';
            end

            switch mode
                case 'array'
                    bools = [];
                    for c=1:length(app.proc_channel_grid.RowHeight)
                        handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
                        if app.(handle).Value
                            dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
                            idx = find(ismember(app.(dd_handle).Items, app.(dd_handle).Value));
                            bools = [bools idx];
                        end
                    end

                case 'struct'
                    bools = struct( ...
                        'r', {app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, 1)).Value}, ...
                        'g', {app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, 2)).Value}, ...
                        'b', {app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, 3)).Value}, ...
                        'white', {app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, 4)).Value}, ...
                        'dic', {app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, 5)).Value}, ...
                        'gfp', {app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, 6)).Value});
            end
        end

        function max_idx = get_max_idx()
            app = Program.app;
            nc = length(app.proc_channel_grid.RowHeight);
            indices = zeros([1, nc]);
            for c=nc:-1:1
                cb_handle = app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, c));
                if cb_handle.Value
                    dd_handle = app.(sprintf(Program.Handlers.channels.handles{'pp_dd'}, c));
                    indices(c) = find(strcmp(dd_handle.Items, dd_handle.Value));
                end
            end

            max_idx = max(indices);
        end

        function set_idx(order, ~)
            app = Program.app;

            % Setup the color channels
            order_nan = isnan(order);
            order(order_nan) = 1; % default unassigned colors to channel 1
            channels_str = arrayfun(@num2str, 1:length(order), 'UniformOutput', false);
            channel_prefixes = Program.Handlers.channels.handles(id_pfx);

            for c=1:length(order)
                ch = channel_prefixes{c};
                dd_handle = sprintf("%sDropDown", ch);
                cb_handle = sprintf("%sCheckBox", ch);

                app.(dd_handle).Items = channels_str;
                app.(dd_handle).Value = app.(dd_handle).Items{order(c)};

                if c <= 3
                    app.(cb_handle).Value = true;
                end
            end
        end

        function edit_channels()
            app = Program.app;
            state = app.EditChannelsButton.Text;

            switch state
                case "Edit Channels"
                    app.EditChannelsButton.Text = "Done Editing";

                    for c=1:length(app.proc_channel_grid.RowHeight)
                        dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
                        ef_handle = sprintf(Program.Handlers.channels.handles{'pp_ef'}, c);
        
                        app.(ef_handle).Value = app.(dd_handle).Value;
        
                        app.(ef_handle).Visible = 'on';
                        app.(dd_handle).Visible = 'off';
                    end

                case "Done Editing"
                    app.EditChannelsButton.Text = "Edit Channels";

                    new_channel_list = {};
                    
                    for c=1:length(app.proc_channel_grid.RowHeight)
                        ef_handle = sprintf(Program.Handlers.channels.handles{'pp_ef'}, c);
                        new_channel_list{end+1} = app.(ef_handle).Value;
                        app.(ef_handle).Visible = 'off';
                    end
                    
                    for c=1:length(app.proc_channel_grid.RowHeight)
                        ef_handle = sprintf(Program.Handlers.channels.handles{'pp_ef'}, c);
                        dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
                        app.(dd_handle).Items = new_channel_list;
                        app.(dd_handle).Value = app.(ef_handle).Value;
                        app.(dd_handle).Visible = 'on';
                    end
            end
        end

        function set_gamma(gamma)
            app = Program.app;

            for c=1:length(gamma)
                c_gamma = gamma(c);
                % to do
            end
        end

        function order = parse_info(channel_names)
            max_nc = Program.Handlers.channels.config{'max_channels'};
            order = zeros(1, max_nc, 'double');

            for c=1:length(channel_names)
                ch_name = channel_names{c};
                [~, ch_idx] = Program.Handlers.channels.identify_color(ch_name);
                order(c) = ch_idx;
            end
        end

        function add_channel()
            app = Program.app;
            current_rows = app.proc_channel_grid.RowHeight;
            tc = length(current_rows)+1;
            current_rows{end+1} = 'fit';
            app.proc_channel_grid.RowHeight = current_rows;

            cb = sprintf(Program.Handlers.channels.handles{'pp_cb'}, tc);
            ref = sprintf(Program.Handlers.channels.handles{'pp_ref'}, tc);
            dd = sprintf(Program.Handlers.channels.handles{'pp_dd'}, tc);
            ef = sprintf(Program.Handlers.channels.handles{'pp_ef'}, tc); 

            app.(cb) = uicheckbox( ...
                "Text", "", "Value", 0, ...
                "Parent", app.proc_channel_grid, ...
                "ValueChangedFcn", @(src, event) Program.Routines.Processing.render());
            app.(cb).Layout.Row = tc;
            app.(cb).Layout.Column = 1;

            app.(ref) = uicolorpicker( ...
                "Parent", app.proc_channel_grid, ...
                "ValueChangedFcn", @(src, event) Program.Routines.Processing.render());
            app.(ref).Layout.Row = tc;
            app.(ref).Layout.Column = 2;

            app.(dd) = uidropdown( ...
                "Items", app.proc_c1_dropdown.Items, ...
                "Parent", app.proc_channel_grid, ...
                "ValueChangedFcn", @(src, event) Program.Helpers.dd_sync(event.Source, event.PreviousValue, event.Value, Program.Handlers.channels.handles{'pp_dd'}));
            app.(dd).Layout.Row = tc;
            app.(dd).Layout.Column = 3;

            app.(ef) = uieditfield("Parent", app.proc_channel_grid);
            app.(ef).Layout.Row = tc;
            app.(ef).Layout.Column = 3;
            app.(ef).Visible = 'off';

            down = uibutton( ...
                "Text", app.proc_c1_down.Text, ...
                "Parent", app.proc_c1_down.Parent, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.move_channel(event));
            down.Layout.Row = tc;
            down.Layout.Column = 4;

            up = uibutton( ...
                "Text", app.proc_c1_up.Text, ...
                "Parent", app.proc_c1_up.Parent, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.move_channel(event));
            up.Layout.Row = tc;
            up.Layout.Column = 5;

            del = uibutton( ...
                "Text", app.proc_c1_delete.Text, ...
                "FontWeight", app.proc_c1_delete.FontWeight, ...
                "BackgroundColor", app.proc_c1_delete.BackgroundColor, ...
                "Parent", app.proc_c1_delete.Parent, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.delete_channel(tc));
            del.Layout.Row = tc;
            del.Layout.Column = 6;
        end
    end

    methods (Static, Access = private)
        function handles = get_handles()
            handles = struct( ...
                'ref', {Program.Handlers.channels.handles{'pp_ref'}}, ...
                'dd', {Program.Handlers.channels.handles{'pp_dd'}}, ...
                'cb', {Program.Handlers.channels.handles{'pp_cb'}}, ...
                'ef', {Program.Handlers.channels.handles{'pp_ef'}}, ...
                'up', {'proc_c%.f_up'}, ...
                'down', {'proc_c%.f_down'}, ...
                'delete', {'proc_c%.f_delete'});
        end
        
        function [color, idx] = identify_color(name)
            fluorophore_keys = keys(Program.Handlers.channels.fluorophore_map);
            idx = 0;

            for c=1:length(fluorophore_keys)
                color = fluorophore_keys{c};

                fluorophores = Program.Handlers.channels.fluorophore_map{color};
                if any(ismember(lower(name), fluorophores))
                    idx = c;
                    return
                end

            end

            color = 'none';
        end

        function idx = get_channel_idx(query)
            app = Program.app;
            if nargin < 1
                idx = struct( ...
                    'r', {Program.Handlers.channels.get_channel_idx('r')}, ...
                    'g', {Program.Handlers.channels.get_channel_idx('g')}, ...
                    'b', {Program.Handlers.channels.get_channel_idx('b')}, ...
                    'white', {Program.Handlers.channels.get_channel_idx('white')}, ...
                    'dic', {Program.Handlers.channels.get_channel_idx('dic')}, ...
                    'gfp', {Program.Handlers.channels.get_channel_idx('gfp')});
                
                idx.other = {};

                n_rows = length(app.proc_channel_grid.RowHeight);
                n_max = Program.Handlers.channels.config{'max_channels'};
                
                value_list = app.proc_c1_dropdown.Items;
                for n=n_max+1:n_rows
                    target_component_string = sprintf(Program.Handlers.channels.handles{'pp_dd'}, n);
                    idx.other{end+1} = find(strcmp(value_list, app.(target_component_string).Value));
                end

            else
                value_list = app.proc_c1_dropdown.Items;

                switch query
                    case 'r'
                        target_component_string = sprintf(Program.Handlers.channels.handles{'pp_dd'}, 1);

                    case 'g'
                        target_component_string = sprintf(Program.Handlers.channels.handles{'pp_dd'}, 2);

                    case 'b'
                        target_component_string = sprintf(Program.Handlers.channels.handles{'pp_dd'}, 3);

                    otherwise
                        target_reference = Program.Helpers.decode_references(query);
                        if ~isempty(target_reference)
                            target_component_string = sprintf(Program.Handlers.channels.handles{'pp_dd'}, target_reference);
                        else
                            idx = [];
                            return
                        end
                end
                
                idx = find(strcmp(value_list, app.(target_component_string).Value));
            end
        end

        function info_struct = get_processing_info(query)
            if nargin < 1
                idx = struct( ...
                    'r', {Program.Handlers.channels.get_processing_info('r')}, ...
                    'g', {Program.Handlers.channels.get_processing_info('g')}, ...
                    'b', {Program.Handlers.channels.get_processing_info('b')}, ...
                    'white', {Program.Handlers.channels.get_processing_info('white')}, ...
                    'dic', {Program.Handlers.channels.get_processing_info('dic')}, ...
                    'gfp', {Program.Handlers.channels.get_processing_info('gfp')});

            else
                app = Program.app;
                query = Program.Helpers.short_to_long(query);
                grid_pfx = Program.Handlers.channels.names{'histogram_grid'};

                for pfx=1:length(grid_pfx)
                    label = sprintf("%s_Label", grid_pfx{pfx});
                    if contains(app.(label).Text, query)
                        slider_vals = app.(sprintf("%s_hist_slider", grid_pfx{pfx})).Value;
                        hist_limit = app.(sprintf("%s_hist_slider", grid_pfx{pfx})).Limits(2);   

                        info_struct = struct( ...
                            'gamma', {app.(sprintf("%s_GammaEditField", grid_pfx{pfx})).Value}, ...
                            'low_high_in', {[]}, ...
                            'low_high_out', {[slider_vals(1)/hist_limit slider_vals(2)/hist_limit]});
                        return
                    end
                end

                info_struct = struct( ...
                    'gamma', {1}, ...
                    'low_high_in', {[]}, ...
                    'low_high_out', {[]});
            end
        end

    end
end

