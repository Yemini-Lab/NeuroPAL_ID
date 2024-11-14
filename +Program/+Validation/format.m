function [is_valid, fmt] = format(fmt)
    if ~startsWith(fmt, '.')
        [~, ~, fmt] = fileparts(fmt);
    end

    if isempty(fmt) || ~isfile(fullfile('+DataHandling', '+Helpers', sprintf('%s.f', fmt)))
        error('Unknown image format: "%s"', fmt);
    end

    is_valid = 1;
    fmt = lower(fmt);
end

