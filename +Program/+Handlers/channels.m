classdef channels
    
    properties (Constant)
        handles = dictionary( ...
            'id_pfx', {{'R', 'G', 'B', 'W', 'DIC', 'GFP'}}, ...
            'pp_ef', {'proc_c%.f_editfield'}, ...
            'pp_dd', {'proc_c%.f_dropdown'}, ...
            'pp_cb', {'proc_c%.f_checkbox'}, ...
            'pp_ref', {'proc_c%.f_ref'}, ...
            'pp_grid', {'EditChannelsGrid'}, ...
            'pp_button', {'EditChannelsButton'}, ...
            'pp_down', {{'1', 'down', '⮟'}}, ...
            'pp_up', {{'-1', 'up', '⮝'}});

        fluorophore_map = dictionary( ...
            'red', {{'neptune', 'nep', 'n2.5', 'n25'}}, ...
            'green', {{'cyofp1', 'cyofp', 'cyo'}}, ...
            'blue', {{'bfp'}}, ...
            'white', {{'rfp', 'tagrfp', 'tagrfp1'}}, ...
            'dic', {{'dic', 'dia', 'nomarski', 'phase', 'dic1', 'dic2'}}, ...
            'gfp', {{'gfp', 'gcamp'}});

        names = dictionary( ...
            'short', {{'r', 'g', 'b', 'w', 'dic', 'gfp'}}, ...
            'color', {{'red', 'green', 'blue'}}, ...
            'long', {{'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'}}, ...
            'histogram_grid', {{'tl', 'tm', 'tr', 'bl', 'bm', 'br'}});

        config = dictionary( ...
            'default_gamma', {0.8}, ...
            'max_channels', {6}, ...
            'label_colors', {{'#000', '#000', '#fff', '#000', '#fff', '#000'}}, ...
            'channel_colors', {{'#ff0000', '#00d100', '#0000ff', '#fff', '#6b6b6b', '#ffff00'}});
    end
    
    methods (Static)        
        function populate(order)
            app = Program.app;
            for c=1:length(order.idx)
                handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);

                if ~isempty(order.names)
                    app.(handle).Items = order.names;
                end

                if order.idx(c) ~= 0
                    app.(handle).Value = app.(handle).Items{order.idx(c)};
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

        function [r, g, b, white, dic, gfp] = parse_channel_gui()
            app = Program.app;
            indices = Program.Handlers.channels.get_channel_idx();

            r = struct( ...
                'idx', indices.r, ...
                'bool', app.proc_c1_checkbox.Value, ...
                'settings', Program.Handlers.channels.get_processing_info('r'));

            g = struct( ...
                'idx', indices.g, ...
                'bool', app.proc_c2_checkbox.Value, ...
                'settings', Program.Handlers.channels.get_processing_info('g'));

            b = struct( ...
                'idx', indices.b, ...
                'bool', app.proc_c3_checkbox.Value, ...
                'settings', Program.Handlers.channels.get_processing_info('b'));

            white = struct( ...
                'idx', indices.white, ...
                'bool', app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, Program.Helpers.decode_references('white'))).Value, ...
                'settings', Program.Handlers.channels.get_processing_info('white'));

            dic = struct( ...
                'idx', indices.dic, ...
                'bool', app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, Program.Helpers.decode_references('dic'))).Value, ...
                'settings', Program.Handlers.channels.get_processing_info('dic'));

            gfp = struct( ...
                'idx', indices.gfp, ...
                'bool', app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, Program.Helpers.decode_references('gfp'))).Value, ...
                'settings', Program.Handlers.channels.get_processing_info('gfp'));
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
            dd = sprintf(Program.Handlers.channels.handles{'pp_dd'}, tc);
            ef = sprintf(Program.Handlers.channels.handles{'pp_ef'}, tc); 

            app.(cb) = uicheckbox( ...
                "Text", "", "Value", 0, ...
                "Parent", app.proc_channel_grid, ...
                "ValueChangedFcn", @app.proc_c1_checkbox.ValueChangedFcn);
            app.(cb).Layout.Row = tc;
            app.(cb).Layout.Column = 1;

            app.(dd) = uidropdown( ...
                "Items", app.proc_c1_dropdown.Items, ...
                "Parent", app.proc_channel_grid, ...
                "ValueChangedFcn", @app.proc_c1_dropdown.ValueChangedFcn);
            app.(dd).Layout.Row = tc;
            app.(dd).Layout.Column = 3;

            app.(ef) = uieditfield("Parent", app.proc_channel_grid);
            app.(ef).Layout.Row = tc;
            app.(ef).Layout.Column = 3;
            app.(ef).Visible = 'off';

            up = uibutton( ...
                "Text", "⮝", ...
                "Parent", app.proc_channel_grid, ...
                "ButtonPushedFcn", @app.proc_c1_up.ButtonPushedFcn);
            up.Layout.Row = tc;
            up.Layout.Column = 5;

            down = uibutton( ...
                "Text", "⮟", ...
                "Parent", app.proc_channel_grid, ...
                "ButtonPushedFcn", @app.proc_c1_down.ButtonPushedFcn);
            down.Layout.Row = tc;
            down.Layout.Column = 6;

            del = uibutton( ...
                "Text", "🗑", ...
                "FontWeight", "bold", ...
                "Parent", app.proc_channel_grid, ...
                "ButtonPushedFcn", @app.proc_c1_delete.ButtonPushedFcn);
            del.Layout.Row = tc;
            del.Layout.Column = 7;
        end
    end

    methods (Static, Access = private)
        
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
            if nargin < 1
                idx = struct( ...
                    'r', {Program.Handlers.channels.get_channel_idx('r')}, ...
                    'g', {Program.Handlers.channels.get_channel_idx('g')}, ...
                    'b', {Program.Handlers.channels.get_channel_idx('b')}, ...
                    'white', {Program.Handlers.channels.get_channel_idx('white')}, ...
                    'dic', {Program.Handlers.channels.get_channel_idx('dic')}, ...
                    'gfp', {Program.Handlers.channels.get_channel_idx('gfp')});

            else
                app = Program.app;
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
                        target_component_string = sprintf(Program.Handlers.channels.handles{'pp_dd'}, target_reference);
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

