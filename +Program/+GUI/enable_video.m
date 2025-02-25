function enable_video()
    app = Program.app;
    if ~any(ismember(app.VolumeDropDown.Items, 'Video'))
        current_items = app.VolumeDropDown.Items;
        current_items(end+1) = {'Video'};
        app.VolumeDropDown.Items = current_items;
    end
end

