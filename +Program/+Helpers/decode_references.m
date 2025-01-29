function reference_idx = decode_references(query)
    app = Program.app;
    if ~strcmp(query, 'other')
        reference_values = { ...
            lower(app.proc_c4_ref.Value), ...
            lower(app.proc_c5_ref.Value), ...
            lower(app.proc_c6_ref.Value)};
        reference_idx = find(strcmp(query, reference_values))+3;
    else
        reference_idx = length(app.proc_channel_grid.RowHeight) - Program.Handlers.channels.config{'max_channels'};
    end
end

