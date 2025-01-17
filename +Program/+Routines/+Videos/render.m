function render(t, z, y, x)
    app = Program.app;

    if nargin == 0
        cursor = Program.Routines.Videos.cursor;
    else
        cursor = struct( ...
            't', {t}, ...
            'x', {x}, ...
            'y', {y}, ...
            'z', {z}, ...
            'marker_size', {app.MarkerSizeSlider.Value});
    end

    if ~Program.Validation.video_bounds(cursor)
        return
    end

    target_frame = app.retrieve_frame(cursor.t);

    switch app.video_info.nc
        case 1
            zero_frame = zeros([app.video_info.nx, app.video_info.ny, app.video_info.nz, 3]);
            zero_frame(:, :, :, 2) = target_frame;
            target_frame = zero_frame;

        case 2
            target_frame = cat(4, target_frame, zeros([app.video_info.ny, app.video_info.nx, app.video_info.nz, 1]));
    end

    if app.OverlayFrameMIPCheckBox.Value
        xy_arr = max(target_frame,[],3);
        xz_arr = max(target_frame(:, y, :, :), [], 3);
        yz_arr = max(target_frame(x, :, :, :), [], 3);

    else
        xy_arr = target_frame(:, :, z, :);
        xz_arr = target_frame(:, y, :, :);
        yz_arr = target_frame(x, :, :, :);

        xy_arr(:, :, :, 1) = xy_arr(:, :, :, 1) * app.RSlider.Value;
        xy_arr(:, :, :, 2) = xy_arr(:, :, :, 2) * app.GSlider.Value;
        xy_arr(:, :, :, 3) = xy_arr(:, :, :, 3) * app.BSlider.Value;
        
        xz_arr(:, :, :, 1) = xz_arr(:, :, :, 1) * app.RSlider.Value;
        xz_arr(:, :, :, 2) = xz_arr(:, :, :, 2) * app.GSlider.Value;
        xz_arr(:, :, :, 3) = xz_arr(:, :, :, 3) * app.BSlider.Value;
        
        yz_arr(:, :, :, 1) = yz_arr(:, :, :, 1) * app.RSlider.Value;
        yz_arr(:, :, :, 2) = yz_arr(:, :, :, 2) * app.GSlider.Value;
        yz_arr(:, :, :, 3) = yz_arr(:, :, :, 3) * app.BSlider.Value;
    end

    xy_arr = squeeze(xy_arr);
    xz_arr = squeeze(xz_arr);
    yz_arr = permute(squeeze(yz_arr),[2, 1, 3]);

    xy_img = image(app.xyAxes, xy_arr);
    xz_img = image(app.xzAxes, yz_arr);
    yz_img = image(app.yzAxes, xz_arr);

    app.xEditField.Value = app.xSlider.Value;
    app.yEditField.Value = app.video_info.ny-app.ySlider.Value;
    app.zEditField.Value = round(app.hor_zSlider.Value);
    app.tEditField.Value = app.tSlider.Value;

    xy_img.ButtonDownFcn = {@app.ImageClicked};
    xz_img.ButtonDownFcn = {@app.ImageClicked};
    yz_img.ButtonDownFcn = {@app.ImageClicked};

    app.xyAxes.XLim = [1, size(xy_arr, 2)];
    app.xyAxes.YLim = [1, size(xy_arr, 1)];
    app.xzAxes.XLim = [1, size(yz_arr, 2)];
    app.xzAxes.YLim = [1, size(yz_arr, 1)];
    app.yzAxes.XLim = [1, size(xz_arr, 2)];
    app.yzAxes.YLim = [1, size(xz_arr, 1)];

    delete(app.xy_yline)
    delete(app.yz_yline)
    delete(app.xz_yline)

    delete(app.xy_xline)
    delete(app.yz_xline)
    delete(app.xz_xline)

    app.xy_yline = yline(app.xyAxes, x, '--', 'color', '#9c9c9c', 'LineWidth', 0.2);
    app.yz_yline = yline(app.yzAxes, x, '--', 'color', '#9c9c9c', 'LineWidth', 0.2);
    app.xz_yline = yline(app.xzAxes, app.xzAxes.YLim(2)*(z/app.video_info.nz), '--', 'color', '#9c9c9c', 'LineWidth', 0.2);

    app.xy_xline = xline(app.xyAxes, y, '--', 'color', '#9c9c9c', 'LineWidth', 0.2);
    app.yz_xline = xline(app.yzAxes, app.yzAxes.XLim(2)*(z/app.video_info.nz), '--', 'color', '#9c9c9c', 'LineWidth', 0.2);
    app.xz_xline = xline(app.xzAxes, y, '--', 'color', '#9c9c9c', 'LineWidth', 0.2);

    delete(findobj(app.xyAxes,'Type','images.roi.Point'));
    delete(findobj(app.yzAxes,'Type','images.roi.Point'));
    delete(findobj(app.xzAxes,'Type','images.roi.Point'));

    Program.Routines.Videos.tracks.draw(cursor);
end

