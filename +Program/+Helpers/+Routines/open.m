function open(path)
    app = Program.app;

    % Are we already opening a file?
    if app.is_opening_file
        return;
    end
    app.is_opening_file = true;
    
    % Unselect any neurons.
    Program.Handlers.neurons.unselect_neuron();
    if ~isempty(app.id_file) && exist(app.id_file, 'file')
        app.SaveIDToFile();
    end

    GUI_prefs = Program.GUIPreferences.instance();
    if nargin == 0
        % Setup the file chooser's path.
        %path = '../';
        path = GUI_prefs.image_dir;

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
    else
        [~, name, fmt] = fileparts(path);
        filename = path;

        % Load the file.
        d = uiprogressdlg(app.CELL_ID,'Title','Reloading processed file...', 'Indeterminate','on');

        if app.DisplayNeuronActivityMenu.Checked
            app.DisplayNeuronActivityMenu.Checked = ~app.DisplayNeuronActivityMenu.Checked;
            app.TabGroup4.SelectedTab = app.MaximumIntensityProjectionTab;
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
    app.image_file = np_file;
    app.id_file = [];
    app.image_prefs = prefs;

    % Setup the image.
    app.image_name = name; %strrep(name, '_', '\_');
    app.image_data = data;

    % Z-score the image.
    app.image_data_zscored = Methods.Preprocess.zscore_frame(app.image_data);

    % Load and update the gamma.
    gamma_size = length(app.gamma_RGBW_DIC_GFP_index);
    if isscalar(prefs.gamma)
        app.image_gamma = ones(gamma_size, 1);
        app.image_gamma(1:3) = prefs.gamma;
        app.image_prefs.gamma = app.image_gamma;
    elseif length(prefs.gamma) < gamma_size
        app.image_gamma = ones(gamma_size, 1);
        app.image_gamma(1:length(prefs.gamma)) = prefs.gamma;
        app.image_prefs.gamma = app.image_gamma;
    else
        app.image_gamma = prefs.gamma;

    % Load the image scale and info.
    app.image_um_scale = info.scale;
    app.image_info = info;

    % Setup the color channels.
    RGBW = prefs.RGBW;
    RGBW_nan = isnan(RGBW);
    RGBW(RGBW_nan) = 1; % default unassigned colors to channel 1
    channels_str = arrayfun(@num2str, 1:size(app.image_data, 4), 'UniformOutput', false);
    % Red.
    app.RDropDown.Items = channels_str;
    app.RDropDown.Value = app.RDropDown.Items{RGBW(1)};
    app.RCheckBox.Value = true;
    % Green.
    app.GDropDown.Items = channels_str;
    app.GDropDown.Value = app.GDropDown.Items{RGBW(2)};
    app.GCheckBox.Value = true;
    % Blue.
    app.BDropDown.Items = channels_str;
    app.BDropDown.Value = app.BDropDown.Items{RGBW(3)};
    app.BCheckBox.Value = true;
    % White.
    app.WDropDown.Items = channels_str;
    if size(app.image_data, 4)>3
        app.WDropDown.Value = app.WDropDown.Items{RGBW(4)};
    end
    app.WCheckBox.Value = false;
    % DIC.
    app.DICDropDown.Items = channels_str;
    if ~isnan(prefs.DIC)
        try
            app.DICDropDown.Value = app.DICDropDown.Items{prefs.DIC};
        catch
            app.DICDropDown.Value = '5';
        end
    end
    app.DICCheckBox.Value = false;
    % GFP.
    app.GFPDropDown.Items = channels_str;
    if ~isnan(prefs.GFP)
        try
            app.GFPDropDown.Value = app.GFPDropDown.Items{prefs.GFP};
        catch
            app.GFPDropDown.Value = '6';
        end
    end
    app.GFPCheckBox.Value = false;

    % Setup the worm info.
    app.worm = worm;
    app.BodyDropDown.Value = worm.body;
    app.AgeDropDown.Value = worm.age;
    app.SexDropDown.Value = worm.sex;
    app.StrainEditField.Value = worm.strain;
    app.SubjectNotesTextArea.Value = worm.notes;

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

        if any(ismember(nwb_data.processing.keys, 'NeuroPAL')) & ...
            (any(ismember(nwb_data.processing.get('NeuroPAL').nwbdatainterface.keys, 'NeuroPALSegmentation')) |  ...
            any(ismember(nwb_data.processing.get('NeuroPAL').nwbdatainterface.keys, 'ImageSegmentation')) |  ...
            any(ismember(nwb_data.processing.get('NeuroPAL').dynamictable.keys, 'VolumeSegmentation')) |  ...
            any(ismember(nwb_data.processing.get('NeuroPAL').dynamictable.keys, 'NeuroPALNeurons')))
            read_nwb_neurons = 1;
        end             

        app.image_neurons = Neurons.Image([], worm.body, 'scale', app.image_um_scale');
    else
        app.image_neurons = Neurons.Image([], worm.body, 'scale', app.image_um_scale');
    end

    % Restrict the slider to the z stack.
    num_z_slices = size(app.image_data, 3);
    z_slices = 1:num_z_slices;
    if num_z_slices <= 1
        uialert(app.CELL_ID, 'The image is not a volume!', ...
            'Image Not a Volume', 'Icon', 'error');
        return;
    else
        z_labels = arrayfun(@(z) num2str(z, '%.1f'), ...
            (z_slices-1) * info.scale(3), 'UniformOutput', false);
    end
    app.ZSlider.Limits = [1, num_z_slices];
    app.ZSlider.MajorTicks = z_slices;
    app.ZSlider.MajorTickLabels = z_labels;

    % Setup the z-axis orientation.
    app.ZCenterEditField.Value = round((prefs.z_center - 1) * info.scale(3), 1);
    if prefs.is_Z_LR
        app.ZAxisDropDown.Value = 'L/R';
        app.ZLeftLabel.Text = 'LEFT';
        app.ZRightLabel.Text = 'RIGHT';
    else
        app.ZAxisDropDown.Value = 'D/V';
        app.ZLeftLabel.Text = 'DORSAL';
        app.ZRightLabel.Text = 'VENTRAL';
    end

    % Setup the max projection.
    daspect(app.XY,[1 1 1]);
    daspect(app.MaxProjection,[1 1 1]);
    axis(app.MaxProjection, 'off');

    % Constrain the image.
    app.XY.XLim = [0, size(app.image_data, 2)];
    app.XY.YLim = [0, size(app.image_data, 1)];

    % Label the image.
    app.XY.Title.Interpreter = 'none';
    app.XY.Title.String = app.image_name;
    app.XY.TitleFontSizeMultiplier = 2;
    app.XY.TitleFontWeight = 'bold';
    x_ticks = linspace(0, size(app.image_data, 2), 15);
    y_ticks = linspace(0, size(app.image_data, 1), 5);
    app.XY.XTick = x_ticks;
    app.XY.YTick = y_ticks;
    x_labels = arrayfun(@(x) num2str(x, '%.1f'), x_ticks * info.scale(1), 'UniformOutput', false);
    y_labels = arrayfun(@(y) num2str(y, '%.1f'), y_ticks * info.scale(2), 'UniformOutput', false);
    x_labels{1} = '0';
    y_labels{1} = '0';
    app.XY.XTickLabel = x_labels;
    app.XY.YTickLabel = flip(y_labels);

    % Select no neurons.
    app.selected_neuron = [];

    % Draw everything.
    if nargin==0
        app.UnselectNeuron();
    end
    app.UserNeuronIDsListBox.Items = {};
    app.UserNeuronIDsListBox.ItemsData = [];
    app.UserNeuronIDsListBox.Value = {};

    if ismember('is_matched', fieldnames(app.image_prefs))
        if app.image_prefs.is_matched == 1
            app.image_data(:, :, :, app.image_info.RGBW(1:3)) = Methods.run_histmatch(app.image_data, app.image_info.RGBW);
        end
    end
    
    Program.Routines.ID.render();
    Program.Routines.ID.hot_neuron_reset();

    if read_nwb_neurons == 1
        app.load_neurons_from_nwb(nwb_data);
        Program.GUIHandling.gui_lock(app, 'enable', 'neuron_gui');
    end

    % Go to the middle.
    app.ZSlider.Value = round(num_z_slices / 2);

    % Draw the neurons in this z-slice.
    Program.Routines.ID.get_slice(app.ZSlider, app.image_view, app.XY);
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
    drawnow;
end

