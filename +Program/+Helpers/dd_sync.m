function dd_sync(source, old_value, new_value, group)
    app = Program.app;
    for dd=1:Program.Handlers.channels.config{'max_channels'}
        this_handle = sprintf(group, dd);
        this_dd = app.(this_handle);
        if strcmp(new_value, this_dd.Value) && this_dd ~= source
            this_dd.Value = old_value;
        end
    end
end

