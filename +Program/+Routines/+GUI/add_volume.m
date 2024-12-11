function add_volume(volume_type)
    app = Program.app;

    if ~any(ismember(app.VolumeDropDown.Items, volume_type))
        current_items = app.VolumeDropDown.Items;
        current_items(end+1) = {volume_type};
        app.VolumeDropDown.Items = current_items;
    end
end

