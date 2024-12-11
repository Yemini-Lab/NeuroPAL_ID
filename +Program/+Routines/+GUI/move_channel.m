function move_channel(channel, direction)
    direction = -1+2*(any(ismember(direction, [Program.channel_handler.down_signs{:}])));
    target = Program.Handlers.channels.get_channel(channel);

    if Program.channel_handler.can_move(target.gui.dd, direction)
        neighbor = Program.channel_handler.get_channel(channel + direction);

        target.gui.dd.Value = neighbor.cached_values.dd;
        neighbor.gui.dd.Value = target.cached_values.dd;

        target.gui.cb.Value = neighbor.cached_values.cb;
        neighbor.gui.cb.Value = target.cached_values.cb;
    end

    %Program.GUIHandling.histogram_handler(app, 'draw');
end