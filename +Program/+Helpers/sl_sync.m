function sl_sync()
    app = Program.app;
    app.xEditField.Value = app.xSlider.Value;
    app.yEditField.Value = app.video_info.ny-app.ySlider.Value;
    app.zEditField.Value = round(app.hor_zSlider.Value);
    app.tEditField.Value = app.tSlider.Value;
end

