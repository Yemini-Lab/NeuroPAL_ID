function open()
    % Are we already opening a file?
    if app.is_opening_file
        return;
    end
    app.is_opening_file = true;
    
    % Unselect any neurons.
    UnselectNeuron(app);
    if ~isempty(app.id_file) && exist(app.id_file, 'file')
        app.SaveIDToFile();
    end

    % Setup the file chooser's path.
    %path = '../';
    GUI_prefs = Program.GUIPreferences.instance();
    path = GUI_prefs.image_dir;

    if isfield(event, 'file')
        [path, name] = fileparts(event.file);
        filename = event.file;

        % Load the file.
        d = uiprogressdlg(app.CELL_ID,'Title','Reloading processed file...',...
    'Indeterminate','on');

        if app.DisplayNeuronActivityMenu.Checked
            app.DisplayNeuronActivityMenu.Checked = ~app.DisplayNeuronActivityMenu.Checked;
            app.TabGroup4.SelectedTab = app.MaximumIntensityProjectionTab;
        end

        app.trigger_reload = 0;
    else
        % Ask the user which file they want.
        file_info = [path ';*.mat;*.czi;*.nd2;*.tif;*.tiff;*.h5;*.nwb'];
        app.CELL_ID.Visible = 'off'; % Hack On! * Matlab can't seem to put the modal dialogue in the foreground
        [name, path, ~] = uigetfile(file_info, 'Select Worm Image');
        app.CELL_ID.Visible = 'on'; % Hack Off! * Matlab can't seem to put the modal dialogue in the foreground
        if name == 0
            app.is_opening_file = false;
            return; % user cancelled
        end

        % Load the file.
        d = uiprogressdlg(app.CELL_ID,'Title','Loading file...',...
    'Indeterminate','on');

        if app.DisplayNeuronActivityMenu.Checked
            app.DisplayNeuronActivityMenu.Checked = ~app.DisplayNeuronActivityMenu.Checked;
            app.TabGroup4.SelectedTab = app.MaximumIntensityProjectionTab;
        end

        filename = [path, name];
        close(d)
        proc_code = app.proc_check("image", filename);
        d = uiprogressdlg(app.CELL_ID,'Title','Loading file...',...
    'Indeterminate','on');
        if proc_code == 1
            return
        end
    end

    app.logEvent('Main',sprintf('Loading file from %s...', filename), 1)

    % Save the path in our preferences.
    GUI_prefs.image_dir = path;
    GUI_prefs.save();
    try                
        [data, info, prefs, worm, mp, neurons, np_file, id_file] = ...
            DataHandling.NeuroPALImage.open(filename);
    catch ME
        msg = getReport(ME, 'extended', 'hyperlinks', 'off');
        uialert(app.CELL_ID, ...
            {['Cannot read "' filename '"!'], ['Error:' msg]}, ...
            'Image File Failure', 'Icon', 'error');
        return;
    end

    % Check the worm info.
    if ~Program.Validation.worm(worm)
        return
    end

    % Fix the prefs for z-axis orientation.
    if ~isfield(prefs, 'z_center')
        prefs.z_center = ceil(size(data,3) / 2);
        prefs.is_Z_LR = true;
        prefs.is_Z_flip = true;
    end

    % Setup the file.
    Program.Handlers.neuropal.initialize(np_file, prefs);

    % Setup the image.
    app.image_name = name; %strrep(name, '_', '\_');
    app.image_data = data;

    % Z-score the image.
    app.image_data_zscored = Methods.Preprocess.zscore_frame(app.image_data);

    % Load and update the gamma.
    Program.Handlers.neuropal.load_gamma(prefs);

    % Load the image scale and info.
    app.image_um_scale = info.scale;
    app.image_info = info;

    % Setup the color channels.
    Program.Handlers.channels.set_idx(prefs.RGBW);

    % Setup the worm info.
    Program.Handlers.worm.set_worm(worm);

    % Enable the image GUI.
    Program.GUIHandling.gui_lock(app, 'enable', 'identification_tab');
    Program.GUIHandling.gui_lock(app, 'disable', 'neuron_gui');

    % Determine the image scale.
    scale = ones(1,3);
    if ~isempty(info.scale)
        scale = info.scale;
    end

    % Did we detect neurons?
    app.id_file = id_file;
    app.mp_params = mp;
    read_nwb_neurons = 0;
    if ~isempty(neurons)
        app.image_neurons = neurons;
        Program.GUIHandling.gui_lock(app, 'enable', 'neuron_gui');
    elseif contains(filename,'.nwb')
        
        nwb_data = nwbRead(filename);

        if any(ismember(nwb_data.processing.keys, 'NeuroPAL')) & (any(ismember(nwb_data.processing.get('NeuroPAL').nwbdatainterface.keys, 'NeuroPALSegmentation')) | any(ismember(nwb_data.processing.get('NeuroPAL').nwbdatainterface.keys, 'ImageSegmentation')) | any(ismember(nwb_data.processing.get('NeuroPAL').dynamictable.keys, 'VolumeSegmentation')) | any(ismember(nwb_data.processing.get('NeuroPAL').dynamictable.keys, 'NeuroPALNeurons')))
            read_nwb_neurons = 1;
        end             

        app.image_neurons = Neurons.Image([], worm.body, 'scale', app.image_um_scale');
    else
        app.image_neurons = Neurons.Image([], worm.body, 'scale', app.image_um_scale');
    end

    % Restrict the slider to the z stack.
    Program.Routines.GUI.reset_zstack(app.image_data);

    Program.Routines.GUI.reset_id_render(app.image_data);

    % Select no neurons.
    app.selected_neuron = [];

    % Draw everything.
    app.UnselectNeuron();
    app.UserNeuronIDsListBox.Items = {};
    app.UserNeuronIDsListBox.ItemsData = [];
    app.UserNeuronIDsListBox.Value = {};

    if ismember('is_matched', fieldnames(app.image_prefs))
        if app.image_prefs.is_matched == 1
            app.image_data(:, :, :, app.image_info.RGBW(1:3)) = Methods.run_histmatch(app.image_data, app.image_info.RGBW);
        end
    end
    
    app.DrawImageData();
    app.UpdateSexNeuronLists();
    if ~isempty(app.image_neurons)
        app.UpdateNeuronLists();
        app.DrawAutoIDList();
    end

    if read_nwb_neurons == 1
        app.load_neurons_from_nwb(nwb_data);
        Program.GUIHandling.gui_lock(app, 'enable', 'neuron_gui');
    end

    % Go to the middle.
    zEvent.Value = round(num_z_slices / 2);
    app.ZSliderValueChanging(zEvent);
    close(d)

    addlistener(app.CELL_ID, 'WindowMousePress', @(src, event) app.DragManager('down', event));
    addlistener(app.CELL_ID, 'WindowMouseRelease', @(src, event) app.DragManager('up', event));
    
    % Done.
    app.is_opening_file = false;
    app.data_flags.('NeuroPAL_Volume') = 1;

    set(app.VolumeDropDown, 'Enable', 'on');
    
    if ~any(ismember(app.VolumeDropDown.Items, 'Colormap'))
        app.VolumeDropDown.Items{end+1} = 'Colormap';
    end
    app.VolumeDropDown.Value = 'Colormap';

    set(app.IdGridLayout, 'Visible', 'on');
    set(app.ProcessingGridLayout, 'Visible', 'on');
    set(app.IdButton, 'Visible', 'off');
    set(app.ProcessingButton, 'Visible', 'off');
end

