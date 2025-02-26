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

    methods (Static, Access = public)
        function n = n_rows()
            obj = Program.GUI.channel_editor;
            n = length(obj.rows);
        end

        function out = channels(varargin)
            obj = Program.GUI.channel_editor;
            out = obj.handle_channels(varargin{:});
        end

        function out = fluorophores(varargin)
            obj = Program.GUI.channel_editor;
            out = obj.handle_fluorophores(varargin{:});
        end

        function out = colors(varargin)
            obj = Program.GUI.channel_editor;
            out = obj.handle_colors(varargin{:});
        end
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

        function move(obj, direction, idx)
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
        
            Program.states.active_volume.update_channels();
        end

        function out = read(obj, varargin)
            p = inputParser();
            addParameter(p, 'idx', []);
            addParameter(p, 'bool', []);
            addParameter(p, 'fluorophore', {});
            addParameter(p, 'color', {});
            parse(p, obj, varargin{:});
            query = p.Results;

            if isempty(query.idx)
                if ~isempty(query.bool)
                    query.idx = find(obj.bools == 1);
                elseif ~isempty(query.fluorophore)
                    fluorophores = obj.fluorophores('get');
                    query.idx = find(ismember(query.fluorophore, fluorophores));
                elseif ~isempty(query.color)
                    colors = obj.colors('get');
                    query.idx = find(ismember(query.color, colors));
                end
            end

            out = obj.find_channel('idx', query.idx);
            components = fieldnames(out);
            for n=1:length(components)
                out.(components{n}) = out.(components{n}).Value;
            end
        end

        function obj = populate(obj, volume, varargin)
            if isa(obj, 'volume')
                Program.GUI.channel_editor.populate_from_volume(volume);
            else
                p = inputParser();
                addParameter(p, 'names', {});
                addParameter(p, 'indices', []);
                parse(p, obj, volume, varargin{:});
                pck = p.Results;

                if isempty(pck.names) && isempty(pck.indices)
                    obj.populate_from_defaults();
                else
                    obj.populate_from_parameters(pck.names, pck.indices);
                end
            end

            obj.is_initialized = 1;
        end

        function out = handle_channels(obj, cmd, varargin)
            p = inputParser();
            addRequired(p, 'cmd');
            addParameter(p, 'fluorophore', '');
            addParameter(p, 'color', '');
            addParameter(p, 'idx', []);
            parse(p, cmd, varargin{:});
            pck = p.Results;
            out = [];

            if isempty(pck.idx)
                pck.idx = obj.find_channel(varargin{:});
            end

            switch p.Results.cmd
                case 'add'
                    obj.add_channel(pck.idx);
                case 'delete'
                    obj.delete_channel(pck.idx);
                case 'read'
                    obj.read_channel(pck.idx);
                case 'find'
                    out = obj.find_channel(pck{:});
            end
        end

        function out = handle_fluorophores(obj, cmd, varargin)
            p = inputParser();
            addRequired(p, 'cmd');
            addParameter(p, 'name', '');
            addParameter(p, 'idx', []);
            parse(p, cmd, varargin{:});
            pck = p.Results;
            out = [];

            switch p.Results.cmd
                case 'add'
                    obj.add('fluorophore', pck.name);
                case 'delete'
                    obj.delete_entry('fluorophore', pck.name);
                case 'set'
                    obj.set('fluorophore', pck.name);
                case {'get', 'read'}
                    out = obj.get_all_fluorophores();
                    if ~isempty(pck.idx)
                        out = out{pck.idx};
                    elseif ~isempty(pck.name)
                        out = out{ismember(out, pck.name)};
                    end
            end
        end

        function out = handle_colors(obj, cmd, varargin)
            p = inputParser();
            addRequired(p, 'cmd');
            addParameter(p, 'name', '');
            addParameter(p, 'idx', []);
            parse(p, cmd, varargin{:});
            pck = p.Results;
            out = [];

            switch p.Results.cmd
                case 'add'
                    obj.add('color', pck.name);
                case 'delete'
                    obj.delete_entry('color', pck.name);
                case 'set'
                    obj.set('color', pck.name);
                case {'get', 'read'}
                    out = obj.get_all_colors();
                    if ~isempty(pck.idx)
                        out = out{pck.idx};
                    elseif ~isempty(pck.name)
                        out = out{ismember(out, pck.name)};
                    end
            end
        end
    end

    methods (Static, Access = public)
        function components = get_components(idx)
            %GET_COMPONENTS(idx)
            % Returns struct of channel editor's child component handles
            % given a target row index. If no index is passed, get all
            % component handles.
            % Args: idx --> (integer | numeric array)
            
            % Validate inputs
            if ~boolean(nargin)                                             % If no input, use all possible inputs.
                idx = 1:Program.GUI.channel_editor.n_rows;
            elseif isnumeric(idx) && ~isscalar(idx)                         % If input is numeric non-scalar, run function for each element.
                components = arrayfun( ...
                    @Program.GUI.channel_editor.get_components, idx);
                return
            elseif ~isnumeric(idx) || mod(idx, 1) ~= 0 || idx < 0           % If invalid input, raise error.
                error(['Invalid input arguments passed to ' ...             
                    'get_component:\n- idx = %s --> %s'], idx, class(idx));
            end

            % Retrieve required handles & variables.
            app = Program.app;                                              % RunningAppInstance.
            gui = Program.GUI.channel_editor;                               % Active gui manager.
            component_types = keys(gui.default_handles);                    % Get array of relevant component types.

            % Initialize & populate struct of component handles.
            components = struct();                                          % Initialize empty struct.
            for n=1:gui.default_handles.numEntries                          % For each component type, ...
                type = component_types{n};                                  % ... grab the type name, 
                pattern = gui.default_handles(type);                        % ... grab the handle pattern,

                handle = sprintf(pattern, idx);
                if ~isprop(app, handle) || (isempty(app.(handle)) || ~isgraphics(app.(handle)))
                    handle = gui.add_channel();
                else
                    handle = app.(handle);
                end

                components.(type) = handle;                                 % ... using the pattern & index, retrieve application property.
            end
        end
    end

    methods (Static, Access = private)
        function handles = add_channel(obj)
            if nargin == 0
                obj = Program.GUI.channel_editor;
            end

            if isempty(obj.rows) || ~isgraphics(obj.grid)
                obj = Program.GUI.channel_editor;
            end

            handles = struct;
            parent_rowheights = obj.grid.RowHeight;
            parent_rowheights{end+1} = 'fit';
            obj.grid.RowHeight = parent_rowheights;
            target_row = obj.n_rows + 1;

            handles.cb = Program.GUI.build.checkbox('Parent', obj.grid, ...
                'ValueChangedFcn', @(src, event) Program.Routines.Processing.render());

            handles.ref = Program.GUI.build.colorpicker('Parent', obj.grid, ...
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
            for h=1:length(handle_types)
                target_handle = handle_types{h};
                handles.(target_handle).Layout.Row = target_row;

                use_same_cell = strcmp(target_handle, 'ef');
                handles.(target_handle).Layout.Column = h - use_same_cell;
            end

            obj.rows{end+1} = handles;
        end

        function array = get_all_fluorophores()
            current_rows = Program.GUI.channel_editor.rows;
            n_rows = length(current_rows);
            array = {};
            for n=1:n_rows
                array{end+1} = current_rows{n}.dd.Value;
            end
        end

        function array = get_all_colors()
            current_rows = Program.GUI.channel_editor.rows;
            n_rows = length(current_rows);
            array = {};
            for n=1:n_rows
                array{end+1} = current_rows{n}.ref.Value;
            end
        end

        function array = bools()
            current_rows = Program.GUI.channel_editor.rows;
            n_rows = length(current_rows);
            array = zeros(1, n_rows);
            for n=1:n_rows
                array(n) = current_rows{n}.cb.Value;
            end
        end
    end

    methods (Access = private)
        function idx = find_channel(obj, varargin)
            p = inputParser();
            addParameter(p, 'fluorophore', '');
            addParameter(p, 'color', '');
            parse(p, varargin{:});
            pck = p.Results;

            for c=1:obj.n_rows
                gui = obj.rows{c};
                if ~isempty(pck.fluorophore)
                    this_channel = strcmp(pck.fluorophore, gui.dd.Value);
                elseif ~isempty(pck.color)
                    this_channel = strcmp(pck.fluorophore, gui.ref.Value);
                else
                    this_channel = 0;
                end

                if this_channel
                    idx = c;
                    return
                end
            end
        end

        function obj = delete_channel(obj, idx)
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

            % Validate
            obj.validate();
        end

        function add(keyword, value)
            switch keyword
                case 'fluorophore'
                    c_handle = 'dd';
                case 'color'
                    c_handle = 'ref';
            end

            for c=1:Program.GUI.channel_editor.n_rows
                component = Program.GUI.channel_editor.rows{c}.(c_handle);
                component.Items{end+1} = value;
            end
        end

        function obj = delete_entry(obj, keyword, value)
            switch keyword
                case 'fluorophore'
                    c_handle = 'dd';
                case 'color'
                    c_handle = 'ref';
            end

            for c=1:obj.n_rows
                row = obj.rows{c};
                component = row.(c_handle);
                if isprop(component, 'Items')
                    component.Items(~ismember(component.Items, value));
                elseif isprop(component, 'Text') && strcmp(component.Text, value)
                    component.Text = '';
                end
            end
        end

        function set(keyword, value)
            switch keyword
                case 'fluorophore'
                    c_handle = 'dd';
                case 'color'
                    c_handle = 'ref';
            end

            for c=1:Program.GUI.channel_editor.n_rows
                component = Program.GUI.channel_editor.rows{c}.(c_handle);
                component.Items = value;
            end
        end

        function populate_from_volume(obj)
            Program.GUI.channel_editor.fluorophores('set', 'name', obj.channels.fluorophores);
            Program.GUI.channel_editor.colors('set', 'name', obj.channels.colors);

            % Add any missing channel components.
            for c=obj.nc:Program.GUI.channel_editor.n_rows
                Program.GUI.channel_editor.channels('add');
            end

            % Delete any excess channel components.
            for c=Program.GUI.channel_editor.n_rows:-1:obj.nc
                Program.GUI.channel_editor.channels('delete', 'idx', c)
            end

            for c=1:length(obj.channels)
                channel = obj.channels{c};
                
                if channel.is_known
                    graphical_index = find(channel.color, {'red', 'green', 'blue', 'white', 'dic', 'gfp'});
                else
                    graphical_index = Program.GUI.channel_editor.n_rows;
                end

                components = Program.GUI.channel_editor.rows{graphical_index};
                components.cb.Value = channel.is_rgb;
                components.ref.Value = channel.color;
                components.dd.Value = channel.fluorophore;
            end
        end

        function [names, indices] = get_defaults(names, indices)
            if nargin == 0
                has_names = 0;
                has_indices = 0;
            else
                has_names = ~isempty(names);
                has_indices = ~isempty(indices);
            end

            if ~has_names && ~has_indices
                indices = 1:Program.active.volume.nc;
                names = arrayfun(@(x) sprintf('Fluo #%d', x), indices, 'UniformOutput', false);

            elseif ~has_names && has_indices
                names = arrayfun(@(x) sprintf('Fluo #%d', x), 1:length(indices), 'UniformOutput', false);

            elseif has_names && ~has_indices
                indices = 1:length(names);
            end
        end

        function obj = validate(obj)
            for c=1:obj.n_rows
                row = obj.rows{c};
                handles = fieldnames(row);
                invalid_handles = structfun(@(x) ...
                    (all(~isgraphics(x)|isempty(x))), row);
                obj.rows{c} = rmfield(row, handles(invalid_handles));
            end

            obj.rows(cellfun(@isempty, obj.rows)) = [];
        end

    end
end