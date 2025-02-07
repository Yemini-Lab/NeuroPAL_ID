function pass_to_main()
    app = Program.app;

    switch app.VolumeDropDown.Value
        case 'Colormap'
            Program.Routines.open(app.proc_image);
            app.TabGroup.Selected = app.NeuroPALIDTab;

        case 'Video'
            Program.Routines.Videos.load();
            app.TabGroup.Selected = app.VideoTrackingTab;
    end
end

