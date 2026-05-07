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
            'pp_down', {{'1', 'down', 'dn', '↓', '⮟'}}, ...                % Buttons that move channels down in the grid.
            'pp_up', {{'-1', 'up', '↑', '⮝'}});                            % Buttons that move channels up in the grid.

        % Dictionary of channel colors and their respective fluorophores.
        fluorophore_map = dictionary( ...
            'red', {{'neptune', 'nep', 'n2.5', 'n25', 'n.25'}}, ...
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
        function order = initialize(path)
            app = Program.app;
            mode = lower(string(app.VolumeDropDown.Value));
            max_nc = Program.Handlers.channels.config{'max_channels'};

            switch mode
                case "video"
                    names = Program.Handlers.channels.video_channel_names(app);
                    idx = zeros(1, max_nc, 'double');
                    idx(1:min(max_nc, numel(names))) = 1:min(max_nc, numel(names));
                    gammas = ones(1, max_nc);

                case "colormap"
                    [names, info, prefs] = Program.Handlers.channels.image_channel_context(app, path);
                    idx = Program.Handlers.channels.image_channel_indices(prefs, numel(names), max_nc);
                    gammas = Program.Handlers.channels.image_channel_gammas(app, prefs, max_nc);

                otherwise
                    names = {};
                    idx = zeros(1, max_nc, 'double');
                    gammas = ones(1, max_nc);
            end

            names = Program.Handlers.channels.ensure_none_channel(names);
            order = struct('names', {names}, 'idx', {idx}, 'gammas', {gammas});
            Program.Handlers.channels.populate(order);

            if mode == "colormap" && exist('info', 'var') && isstruct(info)
                try
                    Program.Handlers.channels.set_references(info);
                catch
                    % Reference rows are best-effort and should not block loading.
                end
            end
        end

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
            generic_channel_names = Program.Handlers.channels.is_generic_channel_list(loaded_fluos);

            % From the array of loaded references, remove unused ones.
            for r=4:3+length(references)                                    % For every known reference...
                reference = references{r-3};                                % Get its name.

                if isfield(info, reference) && info.(reference) == 0        % If this reference is optional & not present...
                    references{r-3} = 'None';                               % Rename it to None.

                elseif ~generic_channel_names                               % Otherwise...
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
            names = Program.Handlers.channels.ensure_none_channel(order.names);
            indices = double(order.idx(:)');
            if isempty(indices)
                indices = zeros(1, Program.Handlers.channels.config{'max_channels'});
            end
            nc = length(indices);

            [indices, ~, ~] = Program.Validation.check_for_duplicate_fluorophores(indices);

            n_rows = length(app.proc_channel_grid.RowHeight);
            if n_rows < nc
                for c=1:(nc-n_rows)
                    Program.Handlers.channels.add_channel();
                end
            end

            role_defaults = {'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'};
            role_colors = {[1 0 0], [0.3922 0.8314 0.0745], [0 0 1]};
            role_font_colors = {[0 0 0], [0 0 0], [1 1 1]};

            for c=1:nc
                cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
                idx = round(indices(c));
                app.(cb_handle).Value = c <= 3 && idx > 0;

                dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);

                if ~isempty(names)
                    app.(dd_handle).Items = names;
                end

                ref_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, c);
                if c <= 3
                    if isprop(app, ref_handle) && isvalid(app.(ref_handle))
                        app.(ref_handle).Text = role_defaults{c};
                        app.(ref_handle).BackgroundColor = role_colors{c};
                        app.(ref_handle).FontWeight = 'bold';
                        app.(ref_handle).FontColor = role_font_colors{c};
                    end
                elseif c >= 4
                    if isprop(app, ref_handle) && isvalid(app.(ref_handle))
                        app.(ref_handle).Items = {'White', 'DIC', 'GFP'};
                        ref_items = string(app.(ref_handle).Items);
                        target_role = string(role_defaults{min(c, numel(role_defaults))});
                        if any(ref_items == target_role)
                            app.(ref_handle).Value = char(target_role);
                        end
                    end
                end

                if idx > 0
                    items = app.(dd_handle).Items;
                    if idx > numel(items)
                        idx = numel(items);
                    end
                    if idx >= 1
                        name = items{idx};
                        app.(dd_handle).Value = name;
                    end
                else
                    items = string(app.(dd_handle).Items);
                    none_idx = find(strcmpi(items, "None"), 1);
                    if ~isempty(none_idx)
                        app.(dd_handle).Value = app.(dd_handle).Items{none_idx};
                    elseif ~isempty(app.(dd_handle).Items)
                        app.(dd_handle).Value = app.(dd_handle).Items{1};
                    end
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

        function state = main_state(app)
            if nargin < 1
                app = Program.app;
            end

            gammas = Program.Helpers.expand_gamma(app.image_gamma, 6);
            state = struct( ...
                'r', Program.Handlers.channels.build_main_channel(app, 'r', 'Red', 'RDropDown', 'RCheckBox', gammas(1), [1 0 0]), ...
                'g', Program.Handlers.channels.build_main_channel(app, 'g', 'Green', 'GDropDown', 'GCheckBox', gammas(2), [0 1 0]), ...
                'b', Program.Handlers.channels.build_main_channel(app, 'b', 'Blue', 'BDropDown', 'BCheckBox', gammas(3), [0 0 1]), ...
                'white', Program.Handlers.channels.build_main_channel(app, 'white', 'White', 'WDropDown', 'WCheckBox', gammas(4), [1 1 1]), ...
                'dic', Program.Handlers.channels.build_main_channel(app, 'dic', 'DIC', 'DICDropDown', 'DICCheckBox', gammas(5), [0.42 0.42 0.42]), ...
                'gfp', Program.Handlers.channels.build_main_channel(app, 'gfp', 'GFP', 'GFPDropDown', 'GFPCheckBox', gammas(6), [1 1 0]));
        end

        function state = processing_state(app)
            if nargin < 1
                app = Program.app;
            end

            n_rows = length(app.proc_channel_grid.RowHeight);
            rows = repmat(Program.Handlers.channels.empty_processing_row(), 1, n_rows);
            for row = 1:n_rows
                rows(row) = Program.Handlers.channels.build_processing_row(app, row);
            end

            state = struct();
            state.rows = rows;
            state.r = rows(1);
            state.g = Program.Handlers.channels.get_processing_role(rows, 'g');
            state.b = Program.Handlers.channels.get_processing_role(rows, 'b');
            state.white = Program.Handlers.channels.get_processing_role(rows, 'white');
            state.dic = Program.Handlers.channels.get_processing_role(rows, 'dic');
            state.gfp = Program.Handlers.channels.get_processing_role(rows, 'gfp');
            state.other = rows(strcmp({rows.role_key}, 'other'));

            enabled_rows = rows([rows.enabled]);
            enabled_indices = unique([enabled_rows.source_idx]);
            enabled_indices = enabled_indices(enabled_indices > 0);
            state.enabled_source_indices = enabled_indices;

            source_indices = [rows.source_idx];
            source_indices = source_indices(source_indices > 0);
            if isempty(source_indices)
                state.max_source_idx = 0;
            else
                state.max_source_idx = max(source_indices);
            end
        end

        function [r, g, b, white, dic, gfp, other] = parse_channel_gui()
            state = Program.Handlers.channels.processing_state();
            r = Program.Handlers.channels.render_struct_from_row(state.r);
            g = Program.Handlers.channels.render_struct_from_row(state.g);
            b = Program.Handlers.channels.render_struct_from_row(state.b);
            white = Program.Handlers.channels.render_struct_from_row(state.white);
            dic = Program.Handlers.channels.render_struct_from_row(state.dic);
            gfp = Program.Handlers.channels.render_struct_from_row(state.gfp);
            other = cellfun(@Program.Handlers.channels.other_struct_from_row, ...
                num2cell(state.other), 'UniformOutput', false);
        end        

        function bools = get_bools(mode)
            state = Program.Handlers.channels.processing_state();

            if nargin < 1
                mode = 'array';
            end

            switch mode
                case 'array'
                    bools = state.enabled_source_indices;

                case 'struct'
                    bools = struct( ...
                        'r', {state.r.enabled}, ...
                        'g', {state.g.enabled}, ...
                        'b', {state.b.enabled}, ...
                        'white', {state.white.enabled}, ...
                        'dic', {state.dic.enabled}, ...
                        'gfp', {state.gfp.enabled});
            end
        end

        function max_idx = get_max_idx()
            state = Program.Handlers.channels.processing_state();
            max_idx = state.max_source_idx;
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
            show_controls = false;
            if isprop(app, 'EditChannelsButton') && isvalid(app.EditChannelsButton)
                show_controls = logical(app.EditChannelsButton.Value);
            end
            Program.Handlers.channels.set_edit_control_buttons_visible(show_controls);
        end

        function hide_edit_controls()
            app = Program.app;
            Program.Handlers.channels.set_edit_control_buttons_visible(false);
            if isprop(app, 'EditChannelsButton') && isvalid(app.EditChannelsButton)
                app.EditChannelsButton.Value = false;
                app.EditChannelsButton.Visible = 'off';
            end
        end

        function hide_edit_buttons_only()
            app = Program.app;
            Program.Handlers.channels.set_edit_control_buttons_visible(false);
            if isprop(app, 'EditChannelsButton') && isvalid(app.EditChannelsButton)
                app.EditChannelsButton.Value = false;
                app.EditChannelsButton.Visible = 'off';
                app.EditChannelsButton.Enable = 'off';
            end
        end

        function set_edit_control_buttons_visible(show_controls)
            app = Program.app;
            handles = Program.Handlers.channels.get_handles();

            app.ProcessingGridLayout.ColumnWidth = {'1x', 292};
            % The web ViewModel is fragile around hidden grid columns; keep
            % the columns narrow rather than collapsing them to zero width.
            if show_controls
                app.proc_channel_grid.ColumnWidth = {15, 88, '1x', 'fit', 'fit', 'fit'};
                visible_state = 'on';
            else
                app.proc_channel_grid.ColumnWidth = {15, 88, '1x', 8, 8, 8};
                visible_state = 'off';
            end

            for c=1:length(app.proc_channel_grid.RowHeight)
                dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
                up_handle = sprintf(handles.up, c);
                down_handle = sprintf(handles.down, c);
                delete_handle = sprintf(handles.delete, c);

                app.(dd_handle).Visible = 'on';

                if isprop(app, down_handle) && isvalid(app.(down_handle))
                    app.(down_handle).Visible = visible_state;
                end
                if isprop(app, up_handle) && isvalid(app.(up_handle))
                    app.(up_handle).Visible = visible_state;
                end
                if isprop(app, delete_handle) && isvalid(app.(delete_handle))
                    app.(delete_handle).Visible = visible_state;
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
                "Text", '↓', ...
                "Tooltip", app.proc_c1_down.Tooltip, ...
                "Parent", app.proc_c1_down.Parent, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.move_channel(event));
            down.Layout.Row = tc;
            down.Layout.Column = 4;
            down.Visible = 'off';

            up = uibutton( ...
                "Text", '↑', ...
                "Tooltip", app.proc_c1_up.Tooltip, ...
                "Parent", app.proc_c1_up.Parent, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.move_channel(event));
            up.Layout.Row = tc;
            up.Layout.Column = 5;
            up.Visible = 'off';

            del = uibutton( ...
                "Text", app.proc_c1_delete.Text, ...
                "Tooltip", app.proc_c1_delete.Tooltip, ...
                "FontWeight", app.proc_c1_delete.FontWeight, ...
                "BackgroundColor", app.proc_c1_delete.BackgroundColor, ...
                "Parent", app.proc_c1_delete.Parent, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.delete_channel(tc));
            del.Layout.Row = tc;
            del.Layout.Column = 6;
            del.Visible = 'off';
        end
    end

    methods (Static)
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
            name_lower = lower(string(name));

            for c=1:length(fluorophore_keys)
                color = fluorophore_keys{c};

                fluorophores = lower(string(Program.Handlers.channels.fluorophore_map{color}));
                if any(name_lower == fluorophores) || any(contains(name_lower, fluorophores))
                    idx = c;
                    return
                end

            end

            color = 'none';
        end

        function idx = get_channel_idx(query)
            state = Program.Handlers.channels.processing_state();
            if nargin < 1
                idx = struct( ...
                    'r', {state.r.source_idx}, ...
                    'g', {state.g.source_idx}, ...
                    'b', {state.b.source_idx}, ...
                    'white', {state.white.source_idx}, ...
                    'dic', {state.dic.source_idx}, ...
                    'gfp', {state.gfp.source_idx});
                idx.other = num2cell([state.other.source_idx]);

            else
                row = Program.Handlers.channels.get_processing_role(state.rows, lower(string(query)));
                if isempty(row.row)
                    idx = [];
                else
                    idx = row.source_idx;
                end
            end
        end

        function info_struct = get_processing_info(query)
            if nargin < 1
                info_struct = struct( ...
                    'r', {Program.Handlers.channels.get_processing_info('r')}, ...
                    'g', {Program.Handlers.channels.get_processing_info('g')}, ...
                    'b', {Program.Handlers.channels.get_processing_info('b')}, ...
                    'white', {Program.Handlers.channels.get_processing_info('white')}, ...
                    'dic', {Program.Handlers.channels.get_processing_info('dic')}, ...
                    'gfp', {Program.Handlers.channels.get_processing_info('gfp')});

            else
                state = Program.Handlers.channels.processing_state();
                row = Program.Handlers.channels.get_processing_role(state.rows, lower(string(query)));
                info_struct = row.settings;
            end
        end

        function channel = build_main_channel(app, key, name, dd_handle, cb_handle, gamma, color)
            idx = Program.Handlers.channels.dropdown_index(app.(dd_handle));
            settings = Program.Handlers.channels.main_display_settings(app, key, gamma);
            channel = struct( ...
                'key', key, ...
                'name', name, ...
                'row', [], ...
                'source_idx', idx, ...
                'idx', idx, ...
                'source_name', string(app.(dd_handle).Value), ...
                'enabled', logical(app.(cb_handle).Value), ...
                'bool', logical(app.(cb_handle).Value), ...
                'color', color, ...
                'settings', settings);
        end

        function settings = main_display_settings(app, key, gamma)
            settings = struct('gamma', gamma, 'low_high_in', [], 'low_high_out', []);
            if isempty(app) || ~isvalid(app) || ...
                    ~Program.GUIHandling.processing_tab_rendered(app) || ...
                    ~strcmpi(char(string(app.VolumeDropDown.Value)), 'Colormap')
                return
            end

            try
                state = Program.Handlers.channels.processing_state(app);
                row = Program.Handlers.channels.get_processing_role(state.rows, lower(string(key)));
            catch
                return
            end

            if isempty(row) || row.row < 1 || row.source_idx < 1 || ~isstruct(row.settings)
                return
            end

            if isfield(row.settings, 'low_high_in')
                settings.low_high_in = row.settings.low_high_in;
            end
            if isfield(row.settings, 'low_high_out')
                settings.low_high_out = row.settings.low_high_out;
            end
        end

        function row = empty_processing_row()
            row = struct( ...
                'row', [], ...
                'role_key', '', ...
                'role_name', '', ...
                'source_idx', 0, ...
                'idx', 0, ...
                'source_name', "", ...
                'enabled', false, ...
                'bool', false, ...
                'color', [], ...
                'settings', struct('gamma', 1, 'low_high_in', [], 'low_high_out', []));
        end

        function row = build_processing_row(app, row_idx)
            row = Program.Handlers.channels.empty_processing_row();
            row.row = row_idx;

            dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, row_idx);
            cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, row_idx);

            row.source_idx = Program.Handlers.channels.dropdown_index(app.(dd_handle));
            row.idx = row.source_idx;
            row.source_name = string(app.(dd_handle).Value);
            row.enabled = logical(app.(cb_handle).Value);
            row.bool = row.enabled;
            row.settings = Program.Handlers.channels.processing_row_settings(app, row_idx);
            [row.role_key, row.role_name, row.color] = Program.Handlers.channels.processing_role(app, row_idx);
        end

        function settings = processing_row_settings(app, row)
            settings = struct('gamma', 1, 'low_high_in', [], 'low_high_out', []);
            grid_pfx = Program.Handlers.channels.names{'histogram_grid'};
            if row < 1 || row > length(grid_pfx)
                return
            end

            slider_handle = sprintf("%s_hist_slider", grid_pfx{row});
            gamma_handle = sprintf("%s_GammaEditField", grid_pfx{row});
            slider_vals = app.(slider_handle).Value;
            hist_limit = app.(slider_handle).Limits(2);
            if hist_limit <= 0
                low_high_in = [];
            else
                low_high_in = [slider_vals(1)/hist_limit slider_vals(2)/hist_limit];
            end

            settings = struct( ...
                'gamma', app.(gamma_handle).Value, ...
                'low_high_in', {low_high_in}, ...
                'low_high_out', {[]});
        end

        function [role_key, role_name, color] = processing_role(app, row)
            switch row
                case 1
                    role_key = 'r';
                    role_name = 'Red';
                    color = '#ff0000';
                case 2
                    role_key = 'g';
                    role_name = 'Green';
                    color = '#00d100';
                case 3
                    role_key = 'b';
                    role_name = 'Blue';
                    color = '#0000ff';
                otherwise
                    ref_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, row);
                    ref_value = app.(ref_handle).Value;
                    if isnumeric(ref_value) || (isfloat(ref_value) && numel(ref_value) == 3)
                        role_key = 'other';
                        role_name = sprintf('Channel %d', row);
                        color = ref_value;
                    else
                        role_key = char(lower(string(ref_value)));
                        role_name = char(string(ref_value));
                        color = Program.Handlers.channels.role_plot_color(role_key);
                    end
            end
        end

        function role = get_processing_role(rows, query)
            role = Program.Handlers.channels.empty_processing_row();
            if isempty(rows)
                return
            end

            switch lower(string(query))
                case {"r", "red"}
                    idx = 1;
                case {"g", "green"}
                    idx = 2;
                case {"b", "blue"}
                    idx = 3;
                otherwise
                    idx = find(strcmp({rows.role_key}, char(lower(string(query)))), 1);
            end

            if ~isempty(idx) && idx >= 1 && idx <= numel(rows)
                role = rows(idx);
            end
        end

        function idx = dropdown_index(dropdown)
            items = string(dropdown.Items);
            value = string(dropdown.Value);
            if strcmpi(value, "None") || strcmp(value, "")
                idx = 0;
                return
            end

            idx = find(items == value, 1);
            if isempty(idx)
                idx = 0;
            end
        end

        function names = ensure_none_channel(names)
            if isempty(names)
                names = {'None'};
                return
            end

            names = cellstr(string(names(:))');
            if ~any(strcmpi(string(names), "None"))
                names{end+1} = 'None';
            end
        end

        function names = video_channel_names(app)
            names = {};

            try
                if isstruct(app.video_info) && isfield(app.video_info, 'channel_names') && ...
                        ~isempty(app.video_info.channel_names)
                    names = cellstr(string(app.video_info.channel_names(:))');
                end
            catch
                names = {};
            end

            if isempty(names)
                nc = 0;
                try
                    nc = double(app.video_info.nc);
                catch
                    nc = 0;
                end
                names = arrayfun(@(c) sprintf('Channel %d', c), 1:nc, 'UniformOutput', false);
            end
        end

        function [names, info, prefs] = image_channel_context(app, path)
            names = {};
            info = struct();
            prefs = struct();

            try
                if isstruct(app.image_info)
                    info = app.image_info;
                end
            catch
            end
            try
                if isstruct(app.image_prefs)
                    prefs = app.image_prefs;
                end
            catch
            end

            if (isempty(fieldnames(info)) || isempty(fieldnames(prefs))) && ...
                    isa(app.proc_image, 'matlab.io.MatFile')
                try
                    info = app.proc_image.info;
                catch
                end
                try
                    prefs = app.proc_image.prefs;
                catch
                end
            end

            if isfield(info, 'channel_names') && ~isempty(info.channel_names)
                names = cellstr(string(info.channel_names(:))');
            elseif isfield(info, 'channels') && ~isempty(info.channels)
                names = cellstr(string(info.channels(:))');
            else
                nc = Program.Handlers.channels.image_channel_count(app, path);
                names = arrayfun(@(c) sprintf('Channel %d', c), 1:nc, 'UniformOutput', false);
            end
        end

        function nc = image_channel_count(app, path)
            nc = 0;

            try
                if isa(app.proc_image, 'matlab.io.MatFile')
                    dims = size(app.proc_image, 'data');
                    if numel(dims) >= 4
                        nc = dims(4);
                    end
                end
            catch
            end

            if nc < 1
                try
                    dims = size(app.image_data);
                    if numel(dims) >= 4
                        nc = dims(4);
                    end
                catch
                end
            end

            if nc < 1 && nargin >= 2 && ~isempty(path)
                try
                    mat_file = matfile(path);
                    dims = size(mat_file, 'data');
                    if numel(dims) >= 4
                        nc = dims(4);
                    end
                catch
                end
            end
        end

        function idx = image_channel_indices(prefs, nc, max_nc)
            idx = zeros(1, max_nc, 'double');

            if isstruct(prefs) && isfield(prefs, 'RGBW') && ~isempty(prefs.RGBW)
                rgbw = round(double(prefs.RGBW(:)'));
                idx(1:min(4, numel(rgbw))) = rgbw(1:min(4, numel(rgbw)));
            else
                idx(1:min(3, nc)) = 1:min(3, nc);
            end

            if isstruct(prefs) && isfield(prefs, 'DIC') && ~isempty(prefs.DIC)
                idx(5) = Program.Handlers.channels.first_valid_channel(prefs.DIC);
            end
            if isstruct(prefs) && isfield(prefs, 'GFP') && ~isempty(prefs.GFP)
                idx(6) = Program.Handlers.channels.first_valid_channel(prefs.GFP);
            end

            idx(~isfinite(idx) | idx < 1 | idx > max(1, nc)) = 0;
        end

        function idx = first_valid_channel(value)
            values = round(double(value(:)'));
            values = values(isfinite(values) & values > 0);
            if isempty(values)
                idx = 0;
            else
                idx = values(1);
            end
        end

        function gammas = image_channel_gammas(app, prefs, max_nc)
            gamma = [];

            if isstruct(prefs) && isfield(prefs, 'gamma') && ~isempty(prefs.gamma)
                gamma = prefs.gamma;
            else
                try
                    gamma = app.image_gamma;
                catch
                    gamma = [];
                end
            end

            gammas = Program.Helpers.expand_gamma(gamma, max_nc);
        end

        function tf = is_generic_channel_list(names)
            tf = false;
            if isempty(names)
                return
            end

            names = string(names);
            names = names(strlength(names) > 0 & ~strcmpi(names, "None"));
            if isempty(names)
                return
            end

            tf = all(~cellfun(@isempty, regexp(cellstr(names), '^Channel\s+\d+$', 'once')));
        end

        function color = role_plot_color(role_key)
            switch lower(string(role_key))
                case {"r", "red"}
                    color = '#ff0000';
                case {"g", "green"}
                    color = '#00d100';
                case {"b", "blue"}
                    color = '#0000ff';
                case "gfp"
                    color = '#ffff00';
                case {"white", "dic"}
                    color = '#6b6b6b';
                otherwise
                    color = '#6b6b6b';
            end
        end

        function row = render_struct_from_row(row)
            row = struct( ...
                'idx', row.source_idx, ...
                'bool', row.enabled, ...
                'settings', row.settings);
        end

        function row = other_struct_from_row(row)
            row = struct( ...
                'idx', row.source_idx, ...
                'bool', row.enabled, ...
                'color', row.color);
        end

    end
end
