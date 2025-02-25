function activity()
    app = Program.app;
    app.DisplayNeuronActivityMenu.Checked = ~app.DisplayNeuronActivityMenu.Checked;
    if app.DisplayNeuronActivityMenu.Checked
        app.TabGroup4.SelectedTab = app.NeuronActivityTab;
    else
        app.TabGroup4.SelectedTab = app.MaximumIntensityProjectionTab;
    end
end

