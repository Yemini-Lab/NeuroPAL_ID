function externalStartupFcn(app, parent_app, image_neurons, neuron_activity, image_file, csvfile, image_prefs, image_data_zscored, image_um_scale, image_data)
    % Externalized version of the startup function
    % Initialize properties
    app.parent_app = parent_app;
    app.image_neurons = image_neurons;
    app.neuron_activity_by_name = neuron_activity;
    app.image_file = image_file;

    app.csvfile = csvfile;
    app.image_prefs = image_prefs;
    app.image_data = image_data;
    app.image_data_zscored = image_data_zscored;
    app.image_um_scale = image_um_scale;

    % Call the NWB initialization
    Program.GUIHandling.nwb_init(app);
end

