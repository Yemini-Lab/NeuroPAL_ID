function reference_idx = decode_references(query)
    app = Program.app;
    if ~strcmp(query, 'other')
        reference_values = {};
        for r=4:6
            ref_handle = sprintf('proc_c%.f_ref', r);
            if isprop(app, ref_handle) && isgraphics(app.(ref_handle)) && isvalid(app.(ref_handle))
                reference_values{end+1} = lower(app.(ref_handle).Value);
            end
        end

        reference_idx = find(strcmp(query, reference_values))+3;
    else
        reference_idx = length(app.proc_channel_grid.RowHeight) - Program.Handlers.channels.config{'max_channels'};
    end
end

