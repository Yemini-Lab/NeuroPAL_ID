function initialize()
    % Hack: close that weird window that pops up for no reason.
    % Note: I have to do this because Matlab sucks.
    close all;

    % Using mlapptools because Matlab refuses to give me focus control.
    % This warning needs to shut up :-)
    % mlapptools.getWebWindow (line 337)
    warning off MATLAB:ui:javaframe:PropertyToBeRemoved;

    app = Program.GUIHandling.app;
    window = Program.GUIHandling.window_fig;

    d = uiprogressdlg(window, "Title","NeuroPAL ID","Message","Starting NeuroPAL_ID...",'Indeterminate','on');
    app.logEvent('Main','Starting NeuroPAL_ID...', 1);
    app.logEvent('Main','Resizing NeuroPAL_ID...', 1);

    Program.Helpers.resize_window();
    Program.Routines.GUI.toggle_buttons();
    Program.Handlers.dialogue.active([]);

    % Load the application preferences.
    is_loaded = Program.GUIPreferences.load();

    % Add the path corresponding to the models.
    if ~isdeployed
        [path, ~, ~] = fileparts(mfilename('fullpath'));
        addpath(genpath([path, filesep, 'Data']));
    end

    % Log the change.
    if exist('TraceHistory', 'class')
        app.log = TraceHistory.Instance;
        app.log.setup({'startupFcn'});
    end

    % Are we using the parallelization toolbox?
    parallel_tb = ver('parallel');
    if isempty(parallel_tb)
        app.is_parallel = false;
    end

    % Initialize the structured properties.
    Program.GUIHandling.init_click_states(app);
    app.neuron_marker.shape = 'c';
    app.neuron_marker.color.edge = [0,0,0];
    Program.GUIHandling.gui_lock(app, 'disable', 'identification_tab');

    % Initialize the neuron birth times.
    [app.hermaphrodite_neurons.names, ...
        app.hermaphrodite_neurons.birth_stages, ~] = ...
        Neurons.NeuronBirth.getHermaphroditeBirthText();
    [app.male_neurons.names, ...
        app.male_neurons.birth_stages, ~] = ...
        Neurons.NeuronBirth.getMaleBirthText();

    app.logEvent('Main','Setting up GUI...', 1);
    % Setup the GUI.
    if is_loaded
        GUIPrefs = Program.GUIPreferences.instance();

        % Are we showing the neuron birth times?
        if GUIPrefs.is_show_birth_times
            app.ToggleBirthTimesMenu.Text = 'Hide Birth Times';
        end

        % Are auto-completing neuron names?
        app.AutoNameCheckBox.Value = GUIPrefs.is_auto_name;

        % Are we auto-updating neuron IDs?
        if ~GUIPrefs.is_autoID_updates
            app.ToggleAutoIDUpdatesMenu.Text = 'Enable Auto-ID Updates';
        end

        % Are we using matching pursuit (MP) to detect neurons?
        if ~GUIPrefs.is_MP_detect
            app.ToggleNeuronDetectionMenu.Text = 'Use MP-Detect Neurons';
        end

        % This is a new user, give them some help!
    else

        answer = uiconfirm(app.CELL_ID, ...
            {['Welcome to NeuroPAL ID!'], ...
            ['Please read the instructions very carefully.']}, ...
            'NeuroPAL ID Instructions', 'Options', {'OK'}, ...
            'DefaultOption', 1, 'CancelOption', 1, 'Icon', 'info');

        % Show the instructions.
        try
            if isdeployed
                DataHandling.PNGViewer.show('Instructions.png', ...
                    'Software Instructions');
            else
                DataHandling.PNGViewer.show('./Data/Documents/Instructions.png', ...
                    'Software Instructions');
            end
        catch ME
            msg = getReport(ME, 'extended', 'hyperlinks', 'off');
            uialert(app.CELL_ID, ...
                {'Cannot open instructions!', '', 'Error:', msg}, ...
                'Display Instructions', 'Icon', 'error');
            return;
        end

        % Save the GUI preferences.
        Program.GUIPreferences.save();
    end

    close(d);
end

