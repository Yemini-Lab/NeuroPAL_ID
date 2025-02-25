function enable_cstack()
    app = Program.app;
    if ~any(ismember(app.VolumeDropDown.Items, 'Colormap'))
        current_items = app.VolumeDropDown.Items;
        current_items(end+1) = {'Colormap'};
        app.VolumeDropDown.Items = current_items;
    end
end

