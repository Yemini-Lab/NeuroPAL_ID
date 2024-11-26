function debug_struct = graphics(save_flag)
    graphics_keys = {'ScreenPixelsPerInch', 'MonitorPositions', 'FixedWidthFontName', 'Units'};

    for n=1:length(graphics_keys)
        key = graphics_keys{n};
        value = get(0, key);
        if exist('debug_struct', 'var')
            debug_struct.(key) = {value};

        else
            debug_struct = struct(key, {value});

        end
    end

    if nargin > 0
        if ~isfolder('debug')
            mkdir('debug');
        end
        Program.Helpers.save_and_open(fullfile('debug', 'graphics_debug.mat'), debug_struct);
    end
end

