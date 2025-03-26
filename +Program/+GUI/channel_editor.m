classdef channel_editor < handle

    properties
        rows = {};
        grid = [];
        is_initialized = 0;
    end

    properties (Constant)
        default_handles = dictionary( ...
            'cb', 'proc_c%.f_checkbox', ...
            'ref', 'proc_c%.f_ref', ...
            'dd', 'proc_c%.f_dropdown', ...
            'ef', 'proc_c%.f_editfield', ...
            'up', 'proc_c%.f_up', ...
            'down', 'proc_c%.f_down', ...
            'delete', 'proc_c%.f_delete');
    end

    methods (Access = public)
        function obj = channel_editor()
            persistent component_instance

            if isempty(component_instance) || ...
                    ~isgraphics(component_instance.grid) || ...
                    isempty(component_instance.rows)
                app = Program.app;
                obj.grid = app.proc_channel_grid;

                component_types = keys(obj.default_handles);
                for c=1:length(obj.grid.RowHeight)
                    obj.rows{end+1} = struct();
                    for n=1:obj.default_handles.numEntries
                        type = component_types{n};
                        pattern = obj.default_handles(type);
                        obj.rows{end}.(type) = app.(sprintf(pattern, c));
                    end
                end

                component_instance = obj;
            end

            obj = component_instance;
        end
    end

    methods (Static, Access = public)
        function n = n_rows()
            obj = Program.GUI.channel_editor;
            n = length(obj.rows);
        end

        function array = fluorophores()
            obj = Program.GUI.channel_editor;
            array = cellfun(@(x)(x.dd.Value), obj.rows);
        end

        function array = colors()
            obj = Program.GUI.channel_editor;
            array = cellfun(@(x)(x.ref.Value), obj.rows);
        end

        function array = bools()
            obj = Program.GUI.channel_editor;
            array = cellfun(@(x)(x.cb.Value), obj.rows);
        end

        function channel = read(index)
            components = obj.rows{index};

            channel = struct();
            channel.is_rendered = components.cb.Value;
            channel.fluorophore = components.dd.Value;
            channel.color = components.ref.Value;
        end

        function move(channel, direction)
            obj = Program.GUI.channel_editor;
            obj.swap_rows(channel, direction);
            app.state.active_volume.update_channels();
        end

        function populate(volume)
            nc = volume.nc;
            channels = volume.channels;

            obj = Program.GUI.channel_editor;
            fluorophores = cellfun(@(x)(x.fluorophore), channels, 'UniformOutput', false);
            colors = cellfun(@(x)(x.color), channels, 'UniformOutput', false);

            obj.set_row_count(nc);
            obj.set_fluorophores(string(fluorophores));
            obj.set_colors(string(colors));

            for c=1:nc
                channel = channels{c};
                gui_idx = channel.gui_idx;
                channel_style = uistyle( ...
                    "BackgroundColor", channel.styling.background, ...
                    "FontColor", channel.styling.font);

                components = obj.rows{gui_idx};
                components.cb.Value = channel.is_rgb;

                components.dd.Value = channel.fluorophore;
                addStyle(components.dd, channel_style, "item", gui_idx)

                switch class(components.ref)
                    case 'matlab.ui.control.ColorPicker'
                        components.ref.Value = channel.styling.background;
                    case 'matlab.ui.control.DropDown'
                        components.ref.Value = channel.color;
                        addStyle(components.ref, channel_style, ...
                            "item", find(ismember( ...
                            components.ref.Items, channel.color)))
                end
            end
        end

        function channels = query(varargin)
            p = inputParser();
            addParameter(p, 'bool', []);
            addParameter(p, 'fluorophore', {});
            addParameter(p, 'color', {});
            parse(p, varargin{:});

            obj = Program.GUI.channel_editor;

            filtered = ones(size(obj.rows));
            n_filters = length(varargin)/2;
            for n=1:2:n_filters
                filter_type = varargin{n};
                filter_value = p.Results.(filter_type);

                switch filter_type
                    case 'bool'
                        filter_func = @(x)(x.cb.Value);
                    case 'fluorophore'
                        filter_func = @(x)(strcmp(x.dd.Value, filter_value));
                    case 'color'
                        filter_func = @(x)(x.cb.Value);
                end

                filtered = filtered .* [cellfun(filter_func, obj_rows)];
            end
            
            channels = obj.rows{filtered};
        end

        function row = request_row(idx)
            stack = dbstack;
            source = stack(2).name;
            valid_source = 'channel.assign_gui';
            if strcmp(source, valid_source) || contains(source, 'channel_editor')
                gui = Program.GUI.channel_editor;

                if idx > gui.n_rows
                    gui.add_channel();
                    row = Program.GUI.channel_editor.request_row(idx);
                    return
                end

                if idx ~= 0
                    row = gui.rows{idx};
                else
                    row = gui.rows{end};
                end
            else
                error("Protected property %s from class %s may " + ...
                    "only be accessed from within %s, but was" + ...
                    "accessed from within %s.", ...
                    'rows', 'channel_editor', valid_source, source);
            end
        end
    end

    methods(Access = private)
        function add_channel(obj, count)
            if isempty(obj.rows) || ~isgraphics(obj.grid)
                obj = Program.GUI.channel_editor;
            end

            if nargin == 2
                for n=1:count
                    obj.add_channel();
                end

                return
            end

            handles = struct;
            parent_rowheights = obj.grid.RowHeight;
            parent_rowheights{end+1} = 'fit';
            obj.grid.RowHeight = parent_rowheights;
            target_row = obj.n_rows + 1;

            handles.cb = Program.GUI.build.checkbox('Parent', obj.grid, ...
                'ValueChangedFcn', @(src, event) Program.Routines.Processing.render());

            handles.ref = Program.GUI.build.colorpicker('Parent', obj.grid, ...
                'Value', Program.Helpers.get_random_color(), ...
                "ValueChangedFcn", @(src, event) Program.Routines.Processing.render());

            handles.dd = Program.GUI.build.dropdown('Parent', obj.grid, ...
                'Items', obj.rows{1}.dd.Items, ...
                'ValueChangedFcn', @(src, event) Program.Helpers.dd_sync(event.Source, event.PreviousValue, event.Value, Program.Handlers.channels.handles{'pp_dd'}));

            handles.ef = Program.GUI.build.editfield('Parent', obj.grid, ...
                'Visible', 'off');

            handles.up = Program.GUI.build.button('Parent', obj.grid, ...
                'Text', obj.rows{1}.up.Text, ...
                'ButtonPushedFcn', @(src, event) Program.Routines.GUI.move_channel(event));

            handles.down = Program.GUI.build.button('Parent', obj.grid, ...
                'Text', obj.rows{1}.down.Text, ...
                'ButtonPushedFcn', @(src, event) Program.Routines.GUI.move_channel(event));

            handles.delete = Program.GUI.build.button('Parent', obj.grid, ...
                'Text', obj.rows{1}.delete.Text,...
                "FontWeight", obj.rows{1}.delete.FontWeight, ...
                "BackgroundColor", obj.rows{1}.delete.BackgroundColor, ...
                "ButtonPushedFcn", @(src, event) Program.Routines.GUI.delete_channel(tc));

            handle_types = fieldnames(handles);
            skip_count = 0;
            for h=1:length(handle_types)
                target_handle = handle_types{h};
                handles.(target_handle).Layout.Row = target_row;

                skip_count = skip_count + strcmp(target_handle, 'ef');
                handles.(target_handle).Layout.Column = h - skip_count;
            end

            obj.rows{end+1} = handles;
        end

        function obj = delete_channel(obj, idx)
            if ~isscalar(idx)
                for n=1:length(idx)
                    obj.delete_channel(idx(n));
                end

                return
            end

            % Grab target row.
            gui = obj.rows{idx};

            % Delete all components within row struct.
            structfun(@delete, gui);

            % Delete row entry.
            obj.rows(idx) = [];

            % Update parent grid.
            live_rows = obj.grid.RowHeight;
            live_rows(idx) = [];
            obj.grid.RowHeight = live_rows;
        end

        function set_fluorophores(obj, array)
            for c=1:obj.n_rows
                obj.rows{c}.dd.Items = array;
            end
        end

        function set_colors(obj, array)
            array = array(~ismember(array, {'red', 'blue', 'green'}));

            for c=1:obj.n_rows
                if isa(obj.rows{c}.ref, 'matlab.ui.control.DropDown')
                    obj.rows{c}.ref.Items = array;
                end
            end
        end

        function add_fluorophore(obj, fluorophore)
            existing_fluorophores = obj.rows{1}.dd.Items;
            existing_fluorophores{end+1} = fluorophore;
            for c=1:obj.n_rows
                obj.rows{c}.dd.Items = existing_fluorophores;
            end
        end

        function delete_fluorophore(obj, fluorophore)
            new_items = obj.fluorophores;
            new_items = new_items(~ismember(new_items, fluorophore));
            for c=1:obj.n_rows
                obj.rows{c}.dd.Items = new_items;
            end
        end

        function add_color(obj, color)
            for c=1:obj.n_rows
                if isa(obj.rows{c}.ref, 'matlab.ui.control.DropDown')
                    existing_colors = obj.rows{c}.ref.Items;
                    existing_colors{end+1} = color;
                    obj.rows{c}.ref.Items = existing_colors;
                end
            end
        end

        function delete_color(obj, color)
            new_items = obj.colors;
            new_items = new_items(~ismember(new_items, color));
            for c=1:obj.n_rows
                if isa(obj.rows{c}.ref, 'matlab.ui.control.DropDown')
                    obj.rows{c}.ref.Items = new_items;
                end
            end
        end

        function set_row_count(obj, n)
            if obj.n_rows == n
                return
            elseif obj.n_rows < n
                missing_channels = obj.n_rows+1:n;
                obj.add_channel(length(missing_channels));
            else
                excess_channels = obj.n_rows:-1:n+1;
                obj.delete_channel(excess_channels);
            end
        end

        function swap_rows(obj, idx, direction)
            app = Program.app;

            if ~isnumeric(direction)
                direction = -1+2*(any(ismember(direction, [Program.GUI.handles.pp.ch_down{:}])));
            end
        
            if direction > 0
                can_move = idx < obj.n_rows;
            else
                can_move = idx > 1;
            end
        
            if can_move
                dd_pattern = Program.GUI.handles.pp.ch_dd;
                target_dd = app.(sprintf(dd_pattern, idx));
                neighbor_dd = app.(sprintf(dd_pattern, idx + direction));
        
                old_value = target_dd.Value;
                new_value = neighbor_dd.Value;
        
                target_dd.Value = new_value;
                neighbor_dd.Value = old_value;
            end
        end
    end
end