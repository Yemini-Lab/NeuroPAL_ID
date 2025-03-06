function pass_to_main()
    app = Program.app;

    switch app.VolumeDropDown.Value
        case 'Colormap'
            DataHandling.Helpers.npal.create_neurons('matfile', app.proc_image);
            Program.Routines.open(app.proc_image.Properties.Source);
            app.TabGroup.SelectedTab = app.NeuroPALIDTab;

        case 'Video'
            Program.Routines.Videos.load(app.video_info.file);
            app.TabGroup.SelectedTab = app.VideoTrackingTab;
    end
end

