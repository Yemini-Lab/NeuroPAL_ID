function signature = processing_histogram_signature(app)
% Build a cache key for histogram content/layout on the processing tab.

if nargin < 1 || isempty(app)
    app = Program.app;
end

state = Program.Handlers.channels.processing_state(app);
rows = state.rows([state.rows.source_idx] > 0);
row_payload = arrayfun(@local_row_signature, rows, 'UniformOutput', false);

payload = struct( ...
    'raw_signature', Program.Helpers.processing_raw_signature(app), ...
    'show_mip', logical(app.ProcShowMIPCheckBox.Value), ...
    'z_index', double(app.proc_zSlider.Value), ...
    'hide_zero', logical(app.HidezerointensitypixelsCheckBox.Value), ...
    'rows', {row_payload});

signature = jsonencode(payload);
end

function payload = local_row_signature(row)
payload = struct( ...
    'row', double(row.row), ...
    'role', char(string(row.role_name)), ...
    'source_idx', double(row.source_idx));
end
