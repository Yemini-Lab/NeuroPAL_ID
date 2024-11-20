function rotation()
    app = Program.GUIHandling.app;
    rotation_stack = app.rotation_stack;
    rotation_stack.screencap = {Program.Helpers.screenshot()};
    save('rotation_debug.mat', '-struct', 'rotation_stack');
    [path, ~, ~] = fileparts(which('rotation_debug.mat'));

    if ispc
        winopen(path);
    else
        unix(path)
    end
end

