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

            % Define all biological worm properties.
            worm_properties = {"Age", "Sex", "Body"};

            % For each biological property...
            for wp=1:length(worm_properties)
                % Get the name of the biological property.
                bio_property = worm_properties{wp};

                % Get the value of the biological property.
                bio_value = worm.(lower(bio_property));

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

