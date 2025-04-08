function fill_channels(data)
    app = Program.app;
    if strcmp(app.proc_c1_dropdown.Value, 'None')
        channel_count = size(data, 4);
        new_items = arrayfun(@(x) sprintf('Fluo #%d', x), 1:size(data,4), 'UniformOutput', false);

        for c=1:channel_count
            handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
            if ~isprop(app, handle) && ~isgraphics(app.(handle))
                Program.Handlers.channels.add_channel();
            end

            app.(handle).Items = new_items;
            app.(handle).Value = new_items{c};
        end
    end
end

