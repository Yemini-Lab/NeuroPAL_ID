function dd_sync(event)

    %(source, old_value, new_value, group)

    pattern = dbstack;

    app = Program.app;
    for dd=1:length(event.Source.Parent.RowHeight)
        this_handle = sprintf(group, dd);
        this_dd = app.(this_handle);
        if strcmp(new_value, this_dd.Value) && this_dd ~= source
            this_dd.Value = old_value;
        end
    end

    Program.Routines.Processing.render()
end

