classdef channels
    
    properties (Constant)
        handles = dictionary( ...
            'id_pfx', {{'R', 'G', 'B', 'W', 'DIC', 'GFP'}}, ...
            'pp_dd', {'proc_c%.f_dropdown'}, ...
            'pp_cb', {'proc_c%.f_checkbox'}, ...
            'pp_rep', {'proc_c%.f_rep'}, ...
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
            'long', {{'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'}});

        config = dictionary( ...
            'default_gamma', {0.8}, ...
            'max_channels', {6}, ...
            'label_colors', {{'#000', '#000', '#fff', '#000', '#fff', '#000'}}, ...
            'channel_colors', {{'#ff0000', '#00d100', '#0000ff', '#fff', '#6b6b6b', '#ffff00'}});
    end
    
    methods (Static)
                names = input;
                nc = length(names);
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

    end
end

