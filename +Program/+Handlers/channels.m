classdef channels
    
    properties (Constant)
        handles = dictionary( ...
            'id_pfx', {{'R', 'G', 'B', 'W', 'DIC', 'GFP'}}, ...
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
            'blue', {'bfp'}, ...
            'white', {{'rfp', 'tagrfp', 'tagrfp1'}}, ...
            'dic', {{'dic', 'dia', 'nomarski', 'phase'}}, ...
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
        function [r, g, b, white, dic, gfp] = parse_channel_gui()
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
                'bool', app.(sprintf(Program.Handlers.channels.handles('pp_cb'), Program.Helpers.decode_references('white'))).Value, ...
                'settings', Program.Handlers.channels.get_processing_info('white'));

            dic = struct( ...
                'idx', indices.dic, ...
                'bool', app.(sprintf(Program.Handlers.channels.handles('pp_cb'), Program.Helpers.decode_references('dic'))).Value, ...
                'settings', Program.Handlers.channels.get_processing_info('dic'));

            gfp = struct( ...
                'idx', indices.gfp, ...
                'bool', app.(sprintf(Program.Handlers.channels.handles('pp_cb'), Program.Helpers.decode_references('gfp'))).Value, ...
                'settings', Program.Handlers.channels.get_processing_info('gfp'));
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
                value_list = app.proc_c1_dropdown.Items;

                switch query
                    case 'r'
                        target_component_string = sprintf(Program.Handlers.channels.handles('pp_dd'), 1);

                    case 'g'
                        target_component_string = sprintf(Program.Handlers.channels.handles('pp_dd'), 2);

                    case 'b'
                        target_component_string = sprintf(Program.Handlers.channels.handles('pp_dd'), 3);

                    otherwise
                        target_reference = Program.Helpers.decode_references(query);
                        target_component_string = sprintf(Program.Handlers.channels.handles('pp_ref'), target_reference);
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
                query = Program.Helpers.short_to_long(query);
                grid_pfx = Program.Handlers.channels.names('histogram_grid');

                for pfx=1:length(grid_pfx)
                    label = sprintf("%s_Label", pfx);
                    if contains(app.(label).Value, query)
                        slider_vals = app.(sprintf("%s_hist_slider", pfx)).Value;
                        hist_limit = app.(sprintf("%s_hist_slider", pfx)).Limits(2);                        

                        info_struct = struct( ...
                            'gamma', {app.(sprintf("%s_GammaEditField", pfx)).Value}, ...
                            'low_high_in', {[slider_vals(1)/hist_limit slider_vals(2)/hist_limit]}, ...
                            'low_high_out', {[]});
                        return
                    end
                end

            end
        end

    end
end

