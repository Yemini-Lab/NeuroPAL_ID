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

        channel_names = dictionary( ...
            'short', {{'r', 'g', 'b', 'w', 'dic', 'gfp'}}, ...
            'color', {{'red', 'green', 'blue'}}, ...
            'long', {{'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'}});

        config = dictionary( ...
            'max_channels', {6}, ...
            'label_colors', {{'#000', '#000', '#fff', '#000', '#fff', '#000'}}, ...
            'channel_colors', {{'#ff0000', '#00d100', '#0000ff', '#fff', '#6b6b6b', '#ffff00'}});
    end
    
    methods (Static)
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
    end
end

