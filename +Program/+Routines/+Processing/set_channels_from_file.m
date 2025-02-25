function set_channels_from_file(names, indices)
    indices = Program.Validation.extract(indices);
    if isempty(names)
        names = arrayfun(@(x) sprintf('Fluo #%d', x), 1:length(indices), 'UniformOutput', false);
    end

    % Remove any NA channels
    [has_NA, idx_NA] = ismember(names, 'NA');
    if has_NA
        names(idx_NA) = [];
        indices(idx_NA) = [];
    end

    % Get channel count
    nc = length(indices);
    references = Program.Helpers.names_to_references(names);

    % Ensure row count == channel count
    Program.Helpers.set_channel_rows(nc);

    % For each channel...
    for c=1:nc
        % Get channel info
        channel_idx = indices(c);

        if channel_idx == 0
            continue
        end

        channel_name = names{channel_idx};
        channel_reference = references{channel_idx};

        % Get components
        cb_handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, c);
        dd_handle = sprintf(Program.Handlers.channels.handles{'pp_dd'}, c);
        ref_handle = sprintf(Program.Handlers.channels.handles{'pp_ref'}, c);

        % If rgb channel, enable render
        app.(cb_handle).Value = channel_idx <= 3;

        % Set dropdown items
        app.(dd_handle).Items = names;
        app.(dd_handle).Value = channel_name;

        if ~app.(cb_handle).Value && isprop(app, ref_handle)
            ref = app.(ref_handle);
            if isgraphics(ref) && isvalid(ref)
                ref.Items = references;
                ref.Value = channel_reference;
            end
        end
    end
end

