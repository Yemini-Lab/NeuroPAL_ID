classdef neurons
    
    properties
    end
    
    methods (Static)
        function initialize(neurons)
            app = Program.app;

            if ~isempty(neurons)
                app.image_neurons = neurons;
                Program.Routines.GUI.enable_neurons;                        % Program.GUIHandling.gui_lock(app, 'enable', 'neuron_gui');
            else
                app.image_neurons = Neurons.Image([], worm.body, 'scale', app.image_um_scale');

            end
                
            read_nwb_neurons = 0;
            nwb_data = nwbRead(filename);
            if any(ismember(nwb_data.processing.keys, 'NeuroPAL')) & (any(ismember(nwb_data.processing.get('NeuroPAL').nwbdatainterface.keys, 'NeuroPALSegmentation')) | any(ismember(nwb_data.processing.get('NeuroPAL').nwbdatainterface.keys, 'ImageSegmentation')) | any(ismember(nwb_data.processing.get('NeuroPAL').dynamictable.keys, 'VolumeSegmentation')) | any(ismember(nwb_data.processing.get('NeuroPAL').dynamictable.keys, 'NeuroPALNeurons')))
                read_nwb_neurons = 1;
            end             
            app.image_neurons = Neurons.Image([], worm.body, 'scale', app.image_um_scale');
        end

        function unselect_neuron(varargin)
            % Unselect the currently selected neuron. Optional argument, re-draw the image?
            % Note: Matlab buffers re-draws so, if you want them to execute in an orderly fashion,
            % you need to only make one call.

            app = Program.app;

            % Unselect the selected neuron.
            if ~isempty(app.selected_neuron) && app.image_neurons.neurons(app.selected_neuron).is_selected == true

                % Unselect the neuron.
                app.image_neurons.neurons(app.selected_neuron).is_selected = false;
                app.selected_neuron = [];

                % Disable the ID fields.
                app.AutoIDDropDown.Items = {''};
                app.AutoIDDropDown.Value = '';
                app.IDEditField.Value = '';

                % Disable the input fields.
                app.AutoIDDropDown.Enable = 'off';
                app.IDEditField.Enable = 'off';
                app.AutoIDButton.Enable = 'off';
                app.UserIDButton.Enable = 'off';

                % Redraw the Z-slice.
                is_redraw = true; % re-draw the image?
                if ~isempty(varargin)
                    is_redraw = varargin{1};
                end
                if is_redraw

                    % Give the GUI time to update.
                    pause(0.2);

                    % Re-draw.
                    Program.Handlers.renders.draw_z(app.image_view, app.XY);
                end
            end
        end

        function reset()
            app = Program.app;

            app.selected_neuron = [];
            Program.Handlers.neurons.unselect_neuron();
            app.UserNeuronIDsListBox.Items = {};
            app.UserNeuronIDsListBox.ItemsData = [];
            app.UserNeuronIDsListBox.Value = {};
        end
    end
end

