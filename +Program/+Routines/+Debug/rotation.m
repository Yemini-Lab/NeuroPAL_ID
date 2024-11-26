function debug_struct = rotation(save_flag)
    app = Program.GUIHandling.app;
    debug_struct = app.rotation_stack;
    debug_struct.screencap = {Program.Helpers.screenshot()};

    debug_struct.graphics = Program.Routines.Debug.graphics();

    if nargin > 0
        if ~isfolder('debug')
            mkdir('debug');
        end
        Program.Helpers.save_and_open(fullfile('debug', 'rotation_debug.mat'), debug_struct);
    end
end

