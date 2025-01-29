function move_channel(event)
    app = Program.app;
    direction = -1+2*(any(ismember(event.Source.Text, [Program.Handlers.channels.handles{'pp_down'}{:}])));
    target_channel = event.Source.Layout.Row;

    if direction > 0
        can_move = target_channel < length(event.Source.Parent.RowHeight);
    else
        can_move = target_channel > 1;
    end

    if can_move
        target_dd = app.(sprintf(Program.Handlers.channels.handles{'pp_dd'}, target_channel));
        neighbor_dd = app.(sprintf(Program.Handlers.channels.handles{'pp_dd'}, target_channel + direction));

        old_value = target_dd.Value;
        new_value = neighbor_dd.Value;

        target_dd.Value = new_value;
        neighbor_dd.Value = old_value;
    end

    Program.Routines.Processing.render()
end