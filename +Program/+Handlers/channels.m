classdef channels
    
    properties (Constant)
        handles = dictionary( ...
            'id_tab', {'R', 'G', 'B', 'W', 'DIC', 'GFP'});
        id_strings = {'R', 'G', 'B', 'W', 'DIC', 'GFP'};
    end
    
    methods (Static)
        function set_idx(order, ~)
            app = Program.app;

            % Setup the color channels
            order_nan = isnan(order);
            order(order_nan) = 1; % default unassigned colors to channel 1
            channels_str = arrayfun(@num2str, 1:length(order), 'UniformOutput', false);

            for c=1:length(order)
                ch = Program.Handlers.channels.id_strings{c};
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
                
            end
        end
    end
end

