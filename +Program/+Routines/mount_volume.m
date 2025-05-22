function mount_volume(volume)
    Program.dlg.add_task(sprintf('Mounting %s.%s', ...
        volume.name, volume.fmt));

    Program.GUI.channel_editor.populate(volume);
    Program.GUI.Panels.histograms.populate(volume);
    
    volume.validate_channels();
    cellfun(@(x)(x.assign_gui()), volume.channels);
    Program.GUI.set_gammas(volume);
    volume.update_channels();

    Program.state().set('active_volume', volume);
    Program.dlg.resolve();
end

