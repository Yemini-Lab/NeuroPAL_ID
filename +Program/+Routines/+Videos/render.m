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
        y = round(app.xSlider.Value);
    end
    
    if ~exist ('x', 'var')
        x = round(app.video_info.ny-app.ySlider.Value);
    end
    
    Program.Validation.frame_in_bounds(t);
    Program.Validation.slice_in_bounds(z);
    render = app.retrieveVideoRenderViews(t, z, x, y, app.OverlayFrameMIPCheckBox.Value);

    proj = fieldnames(render);
    for p=1:length(proj)
        projection = proj{p};
        arr = squeeze(render.(projection));

        if strcmp(projection, 'yz')
            arr = permute(arr, [2, 1, 3]);
        end

        render.(projection) = app.scaleVideoProjection(arr);
    end
    
    xy_img = app.setVideoImage(app.xyAxes, render.xy, 'npal_video_xy');
    xz_img = app.setVideoImage(app.xzAxes, render.yz, 'npal_video_xz');
    yz_img = app.setVideoImage(app.yzAxes, render.xz, 'npal_video_yz');

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
