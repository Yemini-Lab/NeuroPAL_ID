function render(t, z, x, y)
    app = Program.app;

    if nargin == 0
        t = round(app.tSlider.Value);
    elseif app.OverlaylastIDdframeCheckBox_2.Value
        earlier_frames = app.id_frames(app.id_frames < app.tSlider.Value);
        t = max(earlier_frames);
    end
   
    if ~exist ('z', 'var')
        z = round(app.hor_zSlider.Value);
    end
    
    if ~exist('y', 'var')
        x = round(app.xSlider.Value);
    end
    
    if ~exist ('x', 'var')
        y = round(app.video_info.ny-app.ySlider.Value);
    end
    
    Program.Validation.frame_in_bounds(t);
    Program.Validation.slice_in_bounds(z);
    target_frame = app.retrieve_frame(t);

    if app.video_info.nc < 3
        n_xyz = [app.video_info nx, app.video_info.ny, app.video_info.nz];
        target_frame = cat(4, target_frame, zeros(n_xyz));
    end
    
    if app.OverlayFrameMIPCheckBox.Value
        render = struct( ...
            'xy', {max(target_frame, [], 3)}, ...
            'xz', {max(target_frame(:, x, :, :), [], 3)}, ...
            'yz', {max(target_frame(y, :, :, :), [], 3)});
        
    else
        render = struct( ...
            'xy', {target_frame(:, :, z, :)}, ...
            'xz', {target_frame(:, x, :, :)}, ...
            'yz', {target_frame(y, :, :, :)});
        proj = fieldnames(render);
    
        for p=1:length(proj)
            projection = proj{p};
            arr = render.(projection);
            arr(:, :, :, 1) = arr(:, :, :, 1) * app.RSlider.Value;
            arr(:, :, :, 2) = arr(:, :, :, 2) * app.RSlider.Value;
            arr(:, :, :, 3) = arr(:, :, :, 3) * app.RSlider.Value;
            arr = squeeze(arr);

            if strcmp(projection, 'yz')
                render.(projection) = permute(arr, [2, 1, 3]);
            end
        end
    end
    
    xy_img = image(app.xyAxes, render.xy);
    xz_img = image(app.xzAxes, render.yz);
    yz_img = image(app.yzAxes, render.xz);

    Program.Helpers.sl_sync();
    
    xy_img.ButtonDownFcn = {@app.ImageClicked};
    xz_img.ButtonDownFcn = {@app.ImageClicked};
    yz_img.ButtonDownFcn = {@app.ImageClicked};
    
    app.xyAxes.XLim = [1, size(render.xy, 2)];
    app.xyAxes.YLim = [1, size(render.xy, 1)];
    app.xzAxes.XLim = [1, size(render.yz, 2)];
    app.xzAxes.YLim = [1, size(render.yz, 1)];
    app.yzAxes.XLim = [1, size(render.xz, 2)];
    app.yzAxes.YLim = [1, size(render.xz, 1)];

    Program.Helpers.draw_video_cursor(x, y, z);

    delete(findobj(app.xyAxes,'Type','images.roi.Point'));
    delete(findobj(app.yzAxes,'Type','images.roi.Point'));
    delete(findobj(app.xzAxes,'Type','images.roi.Point'));

    if any(app.id_frames == app.tSlider.Value)
        app.roi_draw(app.xSlider.Value, app.ySlider.Value, z, t)
    end
end

