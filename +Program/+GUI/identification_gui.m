classdef identification_gui
    %IDENTIFICATION_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        neuron_gui = [];                % Instance of the neuron_gui class.
        is_opening_file = 0;            % Boolean indicating whether we are currently opening a file.
        valid_image_formats = [';' ...  % Pattern describing file formats we associate with images.
            '*.mat;' ...
            '*.czi;' ...
            '*.nd2;' ...
            '*.tif;' ...
            '*.tiff;' ...
            '*.h5;' ...
            '*.nwb'];
    end
    
    methods (Access = public)
        function obj = identification_gui(path)
            %IDENTIFICATION_GUI Constructs a persistent instance
            %   of the identification gui.
            %
            %   Inputs:
            %   - path (Optional): string/char representing the path of
            %       a file to be loaded into the gui.
            %
            %   Outputs:
            %   - obj: identification_gui instance.

            % Initialize a persistent variable which will reference our
            % sole instance of this object.
            persistent gui_instance

            % If uninitialized...
            if isempty(gui_instance)
                % Update persistent instance with constructed object.
                gui_instance = obj;

                % Create an instance of the neuron_gui class and assign
                % it to the neuron_gui property.
                gui_instance.neuron_gui = Program.GUI.neuron_gui( ...
                    gui_instance);
            end

            % If a path was passed...
            if nargin ~= 0
                gui_instance.open_file(path);
            end

            % Return the persistent instance.
            obj = gui_instance;
        end
        
        function code = open_file(obj, path)
            %OPEN_FILE Loads a given file into the identification gui.
            %
            %   Inputs:
            %   - obj: identification_gui instance.
            %   - path: Optional string/char representing a file path.
            %
            %   Outputs:
            %   - code: Boolean describing whether the file was loaded
            %       successfully (true) or not (false).

            % Initialize code as 0.
            code = 0;

            % Check whether we're actively opening a file. If so, return.
            if obj.is_opening_file
                return
            end

            % If no path was passed...
            if ~exist('path', 'var')
                % Prompt a file selection dialogue.
                [file_name, parent_path] = obj.prompt_file_selection();

                % Check whether returned path is empty.
                if ~isempty(parent_path)
                    % If not, construct the file path by joining the
                    % parent_path and the file_name.
                    file_path = [parent_path, file_name];
                else
                    % If the resulting path is empty, the user canceled
                    % the file selection dialogue, so return.
                    return
                end
            end           

            % Get the handle of our dialogues class.
            dlg = Program.GUI.dialogues;

            % Reset the identification gui.
            dlg.step("Reloading ID tab...")
            obj.reset_gui();

            % Create a progress bar indicating that we are loading the
            % file.
            dlg.add_task(sprintf("Loading %s...", file_name));

            % Check whether this file warrants preprocessing.
            preprocessing = Program.GUI.preprocessing_gui();
            file_needs_preprocessing = preprocessing.check_for_preprocessing_threshold( ...
                file_path);

            % If the user has opted to switch to the preprocessing
            % interface or an issue with the file prevented us from
            % calculating the size of its data, resolve the last task
            % passed to the progress dialogue and return.
            if ~ismember(file_needs_preprocessing, [0 2])
                dlg.resolve()
                return
            end

            % Get the running app instance.
            app = Program.ProgramInfo.app;

            % Get the active window.
            window = Program.ProgramInfo.window;

            % Open the file.
            try                
                [data, info, prefs, worm, mp, neurons, np_file, id_file] = ...
                    DataHandling.NeuroPALImage.open(file_path);
            catch ME
                msg = getReport(ME, 'extended', 'hyperlinks', 'off');
                uialert(window, ...
                    {['Cannot read "' filename '"!'], ['Error:' msg]}, ...
                    'Image File Failure', 'Icon', 'error');
                return;
            end

            % Validate the biological properties (age, sex, body part) of
            % the given worm by checking whether each property's value is
            % present in its respective dropdown's item list.
            is_valid_worm = obj.validate_worm_properties(worm);
            if ~is_valid_worm
                % If it isn't, return.
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
            app.image_data_zscored = Methods.Preprocess.zscore_frame( ...
                app.image_data);


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
            end

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
            Program.GUIHandling.gui_lock(app, ...
                'enable', 'identification_tab');
            Program.GUIHandling.gui_lock(app, ...
                'disable', 'neuron_gui');

            % Determine the image scale.
            scale = ones(1,3);
            if ~isempty(info.scale)
                scale = info.scale;
            end
        end
    end

    methods (Static, Access = public)
        function enable_gui()
            %ENABLE_GUI Renders ID tab visible and enables its various gui
            % components.
            %
            %   Inputs:
            %   - obj: identification_gui instance.

            % Get the running app instance.
            app = Program.ProgramInfo.app;

            % Disable the load image button.
            app.IdButton.Enable = 'off';
            app.IdButton.Visible = 'off';

            % Ensure the ID grid layout is visible.
            set(app.IdGridLayout, 'Visible', 'on');

            % Switch to the ID tab.
            app.TabGroup.SelectedTab = app.NeuroPALIDTab;
        end

        function is_valid_worm = validate_worm_properties(worm_struct)
            % Initialize is_valid_worm.
            is_valid_worm = 0;

            % Define all biological worm properties.
            worm_properties = {"Age", "Sex", "Body"};

            % For each biological property...
            for wp=1:length(worm_properties)
                % Get the name of the biological property.
                bio_property = worm_properties{wp};

                % Get the value of the biological property.
                bio_value = worm_struct.(lower(bio_property));

                % Construct the string corresponding to its dropdown handle.
                dropdown_handle = sprintf("%sDropDown");

                % Turn this string into a handle.
                dropdown = app.(dropdown_handle);

                % Check whether this is a value among a list of expected
                % values. (E.g. Is this a body part we expect to see in a
                % worm?)
                if ~ismember(bio_value, dropdown.Items)
                    % If not, raise an error.
                    error("Unrecognized worm %s %s in %s", ...
                        lower(bio_property), bio_value, file_path);
                end
            end           

            is_valid_worm = 1;
        end
    end

    methods (Access = private)
        function [name, parent_path] = prompt_file_selection(obj)
            %PROMPT_FILE_SELECTION Display a file selection dialogue and
            %   return the file selection by the user.
            %
            %   Inputs:
            %   - obj: identification_gui instance.
            %
            %   Outputs:
            %   - name: String/char representing the name of the 
            %       selected file, including the file extension.
            %   - parent_path: String/char representing the path in
            %       which the selected file resides.

            % Get the active window handle.
            window = Program.ProgramInfo.window;

            % Get a GUI preference instance.
            GUI_prefs = Program.GUIPreferences.instance();
            
            % Initialize default_path as the image directory saved to the
            % GUI preference instance, which is generally the last path
            % from which a file was loaded.
            default_path = GUI_prefs.image_dir;

            % Define the default dialogue settings. This ensures that the
            % dialogue opens with the correct default path and only
            % displays files whose formats we associated with valid images.
            default_dialogue_settings = [default_path, ...
                obj.valid_image_formats];

            % Render the active window invisible. This is to ensure that
            % the modal window we will be creating appears in the
            % foreground across all systems.
            window.Visible = 'off';

            % Create the file selection dialogue.
            [name, parent_path, ~] = uigetfile(...
                default_dialogue_settings, ...
                'Select Worm Image');

            % Render the active window visible again.
            window.Visible = 'on';

            % Check whether name is false.
            if name ~= 0
                % Should that be the case, the file selection dialogue
                % was canceled and no file was selected. We thus return
                % an empty parent path.
                parent_path = '';
                return
            end

            % Save the selected file to our GUI preference instance.
            GUI_prefs.image_dir = parent_path;
            GUI_prefs.save();
        end

        function obj = reset_gui(obj)
            %RESET_GUI Resets the identification gui back to its
            %   uninitialized state by unselecting neurons, disabling
            %   the activity sub-menu, etc.
            %
            %   Inputs:
            %   - obj: identification_gui instance.
            %
            %   Outputs:
            %   - obj: identification_gui instance.

            % Prompt the neuron GUI to reset.
            obj.neuron_gui.reset_gui();
        end
    end
end

