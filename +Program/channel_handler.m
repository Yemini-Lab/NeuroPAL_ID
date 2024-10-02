classdef channel_handler
    %CHANNEL_HANDLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        up_signs = {-1, 'up', '⮝'}
        down_signs = {1, 'down', '⮟'}
        dd_string = "proc_c%.f_dropdown"
        cb_string = "proc_c%.f_checkbox"
    end
    
    methods (Static)
        function initialize(app, file)
            if ~isempty(order)
                channel_names = {Program.GUIHandling.channel_names{end/2+1:end}};
                null_pad = 0;
                for c=1:length(order)
                    if order(c) ~= 0 && isnan(order(c))
                        app.(sprintf(gui_strings.dd, c-null_pad)).Value = channel_names{c};
                    else
                        null_pad = null_pad + 1;
                    end
                end
    
                for n=1:length(null_pad)
                    Program.GUIHandling.edit_channels(app, 'mode', 'gui', 'action', 'delete', 'target', length(grid.RowHeight));
                end
            else
                for c=1:count
                    app.(sprintf(gui_strings.dd, c)).Value = app.(sprintf(gui_strings.dd, c)).Items{c};
                end
            end
    
            if count < 6
                for dd=length(grid.RowHeight)-2:-1:count+1
                    Program.GUIHandling.edit_channels(app, 'mode', 'gui', 'action', 'delete', 'target', dd);
                end
            end
        end

        function create_channel(app, label)
            channel_grid = app.EditChannelsGrid;

            nc = length(channel_grid.RowHeight);
            dd_name = sprintf(Program.channel_handler.dd_string, nc+1);

            for c=1:nc
                app.(dd_name).Items(end+1) = label;
            end
        end

        function channel = get_channel(app, target)
            dd_name = sprintf(Program.channel_handler.dd_string, target);
            cb_name = sprintf(Program.channel_handler.cb_string, target);

            components = struct( ...
                'dd', app.(dd_name), ...
                'cb', app.(cb_name));

            channel = struct( ...
                'idx', target, ...
                'name', {components.dd.name}, ...
                'gui', {components}, ...
                'cached_value', {components.cb.Value});
        end

        function has_space = can_move(channel, direction)
            switch direction
                case Program.channel_handler.up_signs
                    has_space = channel.Layout.Row > 1;
                case Program.channel_handler.down_signs
                    has_space = channel.Layout.Row < length(channel.Parent.RowHeight);
            end
        end
        
        function move_channel(app, channel, direction)
            direction = -1+2*(any(ismember(direction, Program.channel_handler.down_signs)));
            target = Program.channel_handler.get_channel(app, channel);
            neighbor = Program.channel_handler.get_channel(app, channel + direction);

            if Program.channel_handler.can_move(target.gui.dd, direction)
                target.gui.Value = neighbor.cached_value;
                neighbor.gui.Value = target.cached_value;
            end

            Program.GUIHandling.histogram_handler(app, 'draw');
        end
        
        function delete_channel(app, channel, permanence_flag, from_file)
            target = Program.channel_handler.get_channel(app, channel);

            if permanence_flag
                target.gui.dd.Parent.RowHeight(channel) = [];
            else
                target.gui.dd.Value = "N/A";
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

            Program.GUIHandling.histogram_handler(app, 'draw');
        end
    end
end

