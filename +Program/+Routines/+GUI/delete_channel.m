function delete_channel(app, channel, permanence_flag, from_file)
    target = Program.channel_handler.get_channel(app, channel);

    if permanence_flag
        grid = target.gui.dd.Parent;

        for n=numel(grid.Children):-1:1
            child = grid.Children(n);
            if child.Layout.Row == channel
                delete(child)
            end
        end

        temp_rows = grid.RowHeight;
        temp_rows(channel) = [];
        grid.RowHeight = temp_rows;
    else
        %target.gui.dd.Value = "N/A";
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

    %Program.GUIHandling.histogram_handler(app, 'draw');
end