function draw_video_cursor(y, x, z)
    app = Program.app;

    cursor_marker = '--';
    cursor_color = '#9c9c9c';
    cursor_width = 0.2;

    app.xy_yline = update_line(app.xy_yline, app.xyAxes, 'y', y, cursor_marker, cursor_color, cursor_width);
    app.yz_yline = update_line(app.yz_yline, app.yzAxes, 'y', y, cursor_marker, cursor_color, cursor_width);
    app.xz_yline = update_line(app.xz_yline, app.xzAxes, 'y', ...
        app.xzAxes.YLim(2)*(z/app.video_info.nz), cursor_marker, cursor_color, cursor_width);

    app.xy_xline = update_line(app.xy_xline, app.xyAxes, 'x', x, cursor_marker, cursor_color, cursor_width);
    app.xz_xline = update_line(app.xz_xline, app.xzAxes, 'x', x, cursor_marker, cursor_color, cursor_width);
    app.yz_xline = update_line(app.yz_xline, app.yzAxes, 'x', ...
        app.yzAxes.XLim(2)*(z/app.video_info.nz), cursor_marker, cursor_color, cursor_width);

    delete(findobj(app.xyAxes,'Type','images.roi.Point'));
    delete(findobj(app.yzAxes,'Type','images.roi.Point'));
    delete(findobj(app.xzAxes,'Type','images.roi.Point'));
end

function line_handle = update_line(line_handle, ax, orientation, value, marker, color, width)
    needs_new_line = isempty(line_handle);
    if ~needs_new_line
        try
            needs_new_line = ~isvalid(line_handle);
        catch
            needs_new_line = true;
        end
    end

    if needs_new_line
        if strcmp(orientation, 'x')
            line_handle = xline(ax, value, marker, 'color', color, 'LineWidth', width);
        else
            line_handle = yline(ax, value, marker, 'color', color, 'LineWidth', width);
        end
        return
    end

    try
        line_handle.Value = value;
        line_handle.LineStyle = marker;
        line_handle.Color = color;
        line_handle.LineWidth = width;
    catch
        delete(line_handle);
        if strcmp(orientation, 'x')
            line_handle = xline(ax, value, marker, 'color', color, 'LineWidth', width);
        else
            line_handle = yline(ax, value, marker, 'color', color, 'LineWidth', width);
        end
    end
end
