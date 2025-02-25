function load_channels_from_file(names, indices)
    has_NA, idx_NA = ismember(names, 'NA');
    if has_NA
        names(idx_NA) = [];
        indices(idx_NA) = [];
    end

    nc = length(indices);
    n_rows = length(app.proc_channel_grid.RowHeight);
    ref_idx = indices(indices > 3);

    % Ensure row count == channel count
    Program.Helpers.set_channel_rows(nc);

    % For each channel...
    for c=1:nc
        c_idx = indices(c);

        % Get components
        cb = app.(sprintf(Program.Handlers.channels.handles{'pp_cb'}, c));
        dd = app.(sprintf(Program.Handlers.channels.handles{'pp_dd'}, c));
        ref = app.(sprintf(Program.Handlers.channels.handles{'pp_ref'}, c));

        % If rgb channel, enable render.
        cb.Value = c_idx <= 3;

        % Set dropdown items
        dd.Items = names;
        dd.Value = names{c_idx};

        if ~cb.Value
            ref.Value = ref_names;
        end
    end
end

