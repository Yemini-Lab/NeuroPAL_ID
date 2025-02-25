function fill_channel_gui(nc)
    app = Program.app;
    n_rows = length(app.proc_channel_grid.RowHeight);
    if n_rows < nc
        for c=1:(nc-n_rows)
            Program.Handlers.channels.add_channel();
        end
    end
end

