function set_channel_rows(nc)
    app = Program.app;
    n_rows = length(app.proc_channel_grid.RowHeight);
    if nc-n_rows ~= 0
        for c=n_rows:nc
            Program.Handlers.channels.add_channel();
        end

        for c=n_rows:-1:nc+1
            Program.Handlers.channels.delete(c);
        end
    end
end

