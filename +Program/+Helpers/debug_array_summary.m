function debug_array_summary(source, label, arr)
if ~Program.Helpers.debug_enabled()
    return
end

if isempty(arr)
    Program.Helpers.debug_event(source, '%s: empty', label);
    return
end

values = double(arr(:));
if numel(values) > 1e5
    idx = round(linspace(1, numel(values), 1e5));
    values = values(idx);
end

Program.Helpers.debug_event(source, ...
    '%s: size=%s class=%s min=%g max=%g mean=%g', ...
    label, ...
    mat2str(size(arr)), ...
    class(arr), ...
    min(values), ...
    max(values), ...
    mean(values));
end
