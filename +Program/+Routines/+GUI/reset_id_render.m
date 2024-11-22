function reset_id_render(arr)
    app = Program.app;

    nx = size(arr, 2);
    ny = size(arr, 1);

    scale = app.image_info.scale;

    % Setup the max projection.
    daspect(app.XY, [1 1 1]);
    daspect(app.MaxProjection, [1 1 1]);
    axis(app.MaxProjection, 'off');

    % Constrain the image.
    app.XY.XLim = [0, nx];
    app.XY.YLim = [0, ny];

    % Label the image.
    app.XY.Title.Interpreter = 'none';
    app.XY.Title.String = app.image_name;
    app.XY.TitleFontSizeMultiplier = 2;
    app.XY.TitleFontWeight = 'bold';

    x_ticks = linspace(0, nx, 15);
    y_ticks = linspace(0, ny, 5);

    app.XY.XTick = x_ticks;
    app.XY.YTick = y_ticks;

    x_labels = arrayfun(@(x) num2str(x, '%.1f'), x_ticks * scale(1), 'UniformOutput', false);
    y_labels = arrayfun(@(y) num2str(y, '%.1f'), y_ticks * scale(2), 'UniformOutput', false);
    
    x_labels{1} = '0';
    y_labels{1} = '0';

    app.XY.XTickLabel = x_labels;
    app.XY.YTickLabel = flip(y_labels);
end

