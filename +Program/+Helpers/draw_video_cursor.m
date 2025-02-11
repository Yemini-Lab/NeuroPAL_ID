function draw_video_cursor(y, x, z)
    app = Program.app;

    cursor_marker = '--';
    cursor_color = '#9c9c9c';
    cursor_width = 0.2;

    delete(app.xy_yline)
    delete(app.yz_yline)
    delete(app.xz_yline)
    
    delete(app.xy_xline)
    delete(app.yz_xline)
    delete(app.xz_xline)
    
    app.xy_yline = yline(app.xyAxes, y, cursor_marker, 'color', cursor_color, 'LineWidth', cursor_width);
    app.yz_yline = yline(app.yzAxes, y, cursor_marker, 'color', cursor_color, 'LineWidth', cursor_width);
    app.xz_yline = yline(app.xzAxes, app.xzAxes.YLim(2)*(z/app.video_info.nz), cursor_marker, 'color', cursor_color, 'LineWidth', cursor_width);
    
    app.xy_xline = xline(app.xyAxes, x, cursor_marker, 'color', cursor_color, 'LineWidth', cursor_width);
    app.xz_xline = xline(app.xzAxes, x, cursor_marker, 'color', cursor_color, 'LineWidth', cursor_width);
    app.yz_xline = xline(app.yzAxes, app.yzAxes.XLim(2)*(z/app.video_info.nz), cursor_marker, 'color', cursor_color, 'LineWidth', cursor_width);

    delete(findobj(app.xyAxes,'Type','images.roi.Point'));
    delete(findobj(app.yzAxes,'Type','images.roi.Point'));
    delete(findobj(app.xzAxes,'Type','images.roi.Point'));
end

