classdef neuron_gui
    %NEURON_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        neurons = [];
        parent_gui = [];
    end
    
    methods
        function obj = neuron_gui(parent_gui)
            %NEURON_GUI Constructs a persistent instance
            %   of the neuron gui.
            %
            %   Inputs:
            %   - parent_gui: The gui class instance that instantiated this
            %       object. This allows neuron-related callbacks to request
            %       certain actions to be performend by the parent_gui,
            %       such as redrawing axes.
            %
            %   Outputs:
            %   - obj: neuron_gui instance.

            % Set the parent_gui property equal to the passed instance.
            obj.parent_gui = parent_gui;
        end

        function obj = save_neuron_identities(obj, id_file)
            %SAVE_NEURON_IDENTITIES Checks whether we have an ID file and
            %   if so, saves all neuron identities to it.
            %
            %   Inputs:
            %   - obj: neuron_gui instance.
            %   - id_file: Optional string/char representing a file to
            %       which the neuron identities are to be saved.
            %
            %   Outputs:
            %   - obj: neuron_gui instance.

            % Get the running app instance.
            app = Program.ProgramInfo.app;

            % If no id_file was was passed...
            if nargin ~= 2
                % Set id_file equal to the default id file.
                id_file = app.id_file;
            end

            % Check whether an ID file has been defined.
            have_known_id_file = ~isempty(id_file);

            % If if has...
            if have_known_id_file
                % Check whether this ID file actually exists.
                if ~exist(app.id_file, 'file')
                    % If it doesn't, create it.
                    obj.create_id_file();
                end

                % If it does, save our neuron identities to that file.
                version = Program.ProgramInfo.version;
                mp_params = app.mp_params;
                mp_params.k = length(obj.neurons);
                neurons = obj.neurons;
                save(app.id_file, 'version', 'neurons', 'mp_params');
            end
        end

        function obj = unselect_neuron(obj, redraw_flag)
            %UNSELECT_NEURON Checks whether a neuron is currently selected
            %   and if so, unselects it.
            %
            %   Inputs:
            %   - obj: neuron_gui instance.
            %   - redraw_flag: Optional boolean indicating whether to
            %       request that the parent class instance redraw its
            %       image. Note that Matlab buffers re-draws, so if you
            %       want them to execute in an orderly fashion, you need
            %       make just one call.
            %
            %   Outputs:
            %   - obj: neuron_gui instance.

            % Get the running app instance.
            app = Program.ProgramInfo.app;

            % Check whether we currently have a neuron selected.
            if ~isempty(app.selected_neuron) && ...
                    app.image_neurons.neurons(app.selected_neuron).is_selected == true

                % If so, unselect the neuron.
                app.image_neurons.neurons(app.selected_neuron).is_selected = false;
                app.selected_neuron = [];

                % Clear any gui components whose callbacks rely on a
                % neuron currently being selected.
                app.AutoIDDropDown.Items = {''};
                app.AutoIDDropDown.Value = '';
                app.IDEditField.Value = '';

                % Disable those same gui components.
                app.AutoIDDropDown.Enable = 'off';
                app.IDEditField.Enable = 'off';
                app.AutoIDButton.Enable = 'off';
                app.UserIDButton.Enable = 'off';

                % Check whether the redraw_flag argument was passed.
                if nargin == 2
                    % If so, request that the parent gui redraw its image.
                    obj.parent_gui.draw_image();
                end
            end
        end

        function obj = disable_activity_menu(obj)
            %DISABLE_ACTIVITY_MENU Checks whether the activity menu is
            %   currently enabled and if so, disables it.
            %
            %   Inputs:
            %   - obj: neuron_gui instance.
            %
            %   Outputs:
            %   - obj: neuron_gui instance.

            % Get the running app instance.
            app = Program.ProgramInfo.app;

            % Check whether the activity menu is currently enabled.
            if app.DisplayNeuronActivityMenu.Checked
                % If so, disable it.
                app.DisplayNeuronActivityMenu.Checked = ...
                    ~app.DisplayNeuronActivityMenu.Checked;

                % Switch the selected tab of the activity menu's parent
                % panel back to the maximum intensity projection.
                app.TabGroup4.SelectedTab = ...
                    app.MaximumIntensityProjectionTab;
            end
        end
        
        function obj = reset_gui(obj)
            %RESET_GUI Resets the neuron gui back to its uninitialized
            %   state.
            %
            %   Inputs:
            %   - obj: identification_gui instance.
            %
            %   Outputs:
            %   - obj: identification_gui instance.

            % Unselect any neuron that may currently be selected.
            obj.unselect_neuron();

            % Disable the activity menu.
            obj.disable_activity_menu();

            % Save any neuron identities we may have.
            obj.save_neuron_identities();
        end
    end
end

