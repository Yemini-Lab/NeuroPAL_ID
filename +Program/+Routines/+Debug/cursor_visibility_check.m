function cursor_visibility_check(target_axes)
    if length(target_axes) > 1
        for n=1:length(target_axes)
            Program.Routines.Debug.cursor_visibility_check(target_axes{n});
            return
        end
    end

    % Create and activate a pointer manager for the figure:
    iptPointerManager(Program.window, 'enable');

    % Have the pointer change to a cross when the mouse enters an axes object:
    iptSetPointerBehavior(target_axes, @(hFigure, currentPoint) set(hFigure, 'Pointer', 'arrow'));
end

