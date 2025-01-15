classdef nwbsave_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SaveasNWBFileUIFigure           matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        MetadataLabel                   matlab.ui.control.Label
        TabGroup                        matlab.ui.container.TabGroup
        AuthorTab                       matlab.ui.container.Tab
        AuthorGrid                      matlab.ui.container.GridLayout
        RelatedPublications             matlab.ui.control.EditField
        RelatedPublicationsLabel        matlab.ui.control.Label
        DatadescriptionTextArea         matlab.ui.control.TextArea
        DatadescriptionTextAreaLabel    matlab.ui.control.Label
        InstitutionalAffiliationEditField  matlab.ui.control.EditField
        InstitutionalAffiliationEditFieldLabel  matlab.ui.control.Label
        AuthorLaboratoryEditField       matlab.ui.control.EditField
        AuthorLaboratoryEditFieldLabel  matlab.ui.control.Label
        WormTab                         matlab.ui.container.Tab
        WormGrid                        matlab.ui.container.GridLayout
        SubjectNotesTextArea            matlab.ui.control.TextArea
        NotesTextAreaLabel              matlab.ui.control.Label
        BodyDropDown                    matlab.ui.control.DropDown
        BodypartDropDownLabel           matlab.ui.control.Label
        CultivationtempCEditField       matlab.ui.control.NumericEditField
        CultivationtempCEditField_2Label  matlab.ui.control.Label
        SexDropDown                     matlab.ui.control.DropDown
        SexDropDown_2Label              matlab.ui.control.Label
        AgeDropDown                     matlab.ui.control.DropDown
        AgeDropDown_2Label              matlab.ui.control.Label
        SessionDateDatePicker           matlab.ui.control.DatePicker
        SessionDateDatePicker_2Label    matlab.ui.control.Label
        WormIdentifierEditField         matlab.ui.control.EditField
        WormIdentifierEditFieldLabel    matlab.ui.control.Label
        StrainEditField                 matlab.ui.control.EditField
        StrainEditField_2Label_2        matlab.ui.control.Label
        MicroscopeTab                   matlab.ui.container.Tab
        GridLayout4_2                   matlab.ui.container.GridLayout
        DeviceManufacturerEditFieldLabel_2  matlab.ui.control.Label
        DeviceUITable                   matlab.ui.control.Table
        Panel_18                        matlab.ui.container.Panel
        GridLayout13                    matlab.ui.container.GridLayout
        EditButton                      matlab.ui.control.Button
        RemoveButton                    matlab.ui.control.Button
        AddHardwareDeviceButton         matlab.ui.control.Button
        HardwareDescriptionTextArea     matlab.ui.control.TextArea
        HardwareDescriptionTextAreaLabel  matlab.ui.control.Label
        ManufacturerEditField           matlab.ui.control.EditField
        ManufacturerEditFieldLabel      matlab.ui.control.Label
        NameEditField                   matlab.ui.control.EditField
        NameEditFieldLabel              matlab.ui.control.Label
        ChannelsTab                     matlab.ui.container.Tab
        GridLayout15                    matlab.ui.container.GridLayout
        Panel_24                        matlab.ui.container.Panel
        GridLayout18_2                  matlab.ui.container.GridLayout
        EmissionLabel_2                 matlab.ui.control.Label
        EmFilterHighEditField           matlab.ui.control.NumericEditField
        FilterHighEditField_2Label      matlab.ui.control.Label
        EmFilterLowEditField            matlab.ui.control.NumericEditField
        FilterLowEditField_2Label       matlab.ui.control.Label
        EmLambdaEditField               matlab.ui.control.NumericEditField
        EditField_9Label                matlab.ui.control.Label
        Panel_23                        matlab.ui.container.Panel
        GridLayout18                    matlab.ui.container.GridLayout
        ExcitationLabel                 matlab.ui.control.Label
        ExFilterHighEditField           matlab.ui.control.NumericEditField
        FilterHighEditFieldLabel        matlab.ui.control.Label
        ExFilterLowEditField            matlab.ui.control.NumericEditField
        FilterLowEditFieldLabel         matlab.ui.control.Label
        ExLambdaEditField               matlab.ui.control.NumericEditField
        EditField_7Label                matlab.ui.control.Label
        Panel_20                        matlab.ui.container.Panel
        GridLayout16                    matlab.ui.container.GridLayout
        RemoveButton_2                  matlab.ui.control.Button
        EditButton_2                    matlab.ui.control.Button
        AddOpticalChannelButton         matlab.ui.control.Button
        GridLayout6                     matlab.ui.container.GridLayout
        OpticalUITable                  matlab.ui.control.Table
        OpticalChannelReferencesLabel   matlab.ui.control.Label
        FilterEditField                 matlab.ui.control.EditField
        FilterEditFieldLabel            matlab.ui.control.Label
        FluorophoreEditField            matlab.ui.control.EditField
        FluorophoreEditFieldLabel       matlab.ui.control.Label
        NotesTab                        matlab.ui.container.Tab
        GridLayout7                     matlab.ui.container.GridLayout
        TabGroup2                       matlab.ui.container.TabGroup
        NPALVolumeTab                   matlab.ui.container.Tab
        NPALVolumeGrid                  matlab.ui.container.GridLayout
        NpalNotes                       matlab.ui.control.EditField
        VolumeDescriptionLabel          matlab.ui.control.Label
        EditField_4                     matlab.ui.control.EditField
        Label_4                         matlab.ui.control.Label
        Label_3                         matlab.ui.control.Label
        Label_2                         matlab.ui.control.Label
        Label                           matlab.ui.control.Label
        EditField_3                     matlab.ui.control.NumericEditField
        EditField_2                     matlab.ui.control.NumericEditField
        EditField                       matlab.ui.control.NumericEditField
        GridSpacingLabel                matlab.ui.control.Label
        NpalHardwareDeviceDropDown      matlab.ui.control.DropDown
        HardwareDeviceDropDownLabel     matlab.ui.control.Label
        VideoVolumeTab                  matlab.ui.container.Tab
        VideoVolumeGrid                 matlab.ui.container.GridLayout
        NpalNotes_2                     matlab.ui.control.EditField
        VideoVolumeDescriptionLabel     matlab.ui.control.Label
        TrackingNotesLabel              matlab.ui.control.Label
        NpalNotes_3                     matlab.ui.control.EditField
        VideoHardwareDeviceDropDown     matlab.ui.control.DropDown
        VideoHardwareDeviceLabel        matlab.ui.control.Label
        NeuronDataTab                   matlab.ui.container.Tab
        NeuronDataGrid                  matlab.ui.container.GridLayout
        NeuroPALIDsDescription          matlab.ui.control.EditField
        NeuroPALIDsDescriptionLabel     matlab.ui.control.Label
        StimulusFileLabel               matlab.ui.control.Label
        StimulusFileSelect              matlab.ui.control.DropDown
        NeuronalActivityDescriptionLabel  matlab.ui.control.Label
        NeuronalActivityDescription     matlab.ui.control.EditField
        Panel                           matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        Panel_5                         matlab.ui.container.Panel
        GridLayout3_2                   matlab.ui.container.GridLayout
        CustomFileName                  matlab.ui.control.EditField
        CustomFileNameLabel             matlab.ui.control.Label
        CheckBox                        matlab.ui.control.CheckBox
        CancelButton                    matlab.ui.control.Button
        SaveButton                      matlab.ui.control.Button
        Panel_2                         matlab.ui.container.Panel
        GridLayout3                     matlab.ui.container.GridLayout
        Hyperlink                       matlab.ui.control.Hyperlink
        OpenDANDIaftersavingCheckBox    matlab.ui.control.CheckBox
        AvailableDataLabel              matlab.ui.control.Label
        Tree                            matlab.ui.container.CheckBoxTree
        NeuroPALVolumeNode              matlab.ui.container.TreeNode
        VideoVolumeNode                 matlab.ui.container.TreeNode
        TrackingROIsNode                matlab.ui.container.TreeNode
        NeuronsNode                     matlab.ui.container.TreeNode
        NeuronalIdentitiesNode          matlab.ui.container.TreeNode
        NeuronalActivityNode            matlab.ui.container.TreeNode
        StimulusFileNode                matlab.ui.container.TreeNode
    end

    
    properties (Access = public)
        parent_app;
        image_neurons;
        neuron_activity_by_name;
        image_file;
        devices;
        opt_chans;

        csvfile;
        image_prefs;
        image_data;
        image_data_zscored;
        image_um_scale;
    end
    
    methods (Access = private)
        
        function create_nwb_file(app, metadata)
            % Load the .mat file
            npal_file = load(metadata.mat_path);
            npal_vol = npal_file.data;
            metadata.npal_shape = size(npal_file.data);
            metadata.rgbw = npal_file.prefs(1).rgbw;
            metadata.grid_spacing = npal_file.info(1).grid_spacing;
            
            reference_frame = ['worm ', metadata.worm_bodypart];
            
            % Generate file. Assuming gen_file is a custom function you have in MATLAB
            nwbfile = gen_file(metadata);
            
            % Populate subject data
            % Assuming CElegansSubject is a custom class or function you've defined in MATLAB
            nwbfile.subject = types.ndx_multichannel_volume.CElegansSubject(...
                'subject_id', metadata.worm_identifier, ...
                'age', metadata.worm_age, ...
                'date_of_birth', metadata.worm_date, ...
                'growth_stage', metadata.worm_age, ...
                'cultivation_temp', metadata.cultivation_temp, ...
                'description', metadata.data_description, ...
                'species', 'http://purl.obolibrary.org/obo/NCBITaxon_6239', ...
                'sex', metadata.worm_sex, ...
                'strain', metadata.worm_strain);
            
            % Populate device data
            for eachDevice = 1:length(metadata.devices)
                if eachDevice == 1
                    device = nwbfile.create_device(...
                        'name', metadata.devices{eachDevice}.name, ...
                        'description', metadata.devices{eachDevice}.description, ...
                        'manufacturer', metadata.devices{eachDevice}.manufacturer);
                else
                    nwbfile.create_device(...
                        'name', metadata.devices{eachDevice}.name, ...
                        'description', metadata.devices{eachDevice}.description, ...
                        'manufacturer', metadata.devices{eachDevice}.manufacturer);
                end
            end
            
            % Populate imaging data
            % Assuming create_im_vol is a custom function you've defined in MATLAB
            [ImagingVol, OptChannelRefs, OptChannels] = app.create_im_vol(device, metadata, ...
                                                                      'grid_spacing', metadata.grid_spacing, ...
                                                                      'reference_frame', reference_frame);

            image = app.create_image(npal_vol, metadata, ImagingVol, OptChannelRefs);
            nwbfile.add_acquisition(image)
        end

        function [imaging_vol, orderOpticalChannels, OptChannels] = create_im_vol(app, device, metadata, gridSpacing, gridSpacingUnit, originCoords, originCoordsUnit, referenceFrame)
            
            if ~exist('gridSpacing', 'var')
                gridSpacing = [0.3208, 0.3208, 0.75];
            end

            if ~exist('gridSpacingUnit', 'var')
                gridSpacingUnit = 'micrometers';
            end

            if ~exist('originCoords', 'var')
                originCoords = [0, 0, 0];
            end

            if ~exist('originCoordsUnit', 'var')
                originCoordsUnit = 'micrometers';
            end

            if ~exist('referenceFrame', 'var')
                referenceFrame = 'Worm head';
            end
            
            OptChannels = struct([]);
            OptChanRefData = {};
            
            for eachChannel = 1:length(metadata.channels)
                OptChan = types.ndx_multichannel_volume.OpticalChannelPlus( ...
                    'name', metadata.channels{eachChannel}.fluorophore, ...
                    'description', metadata.channels{eachChannel}.filter, ...
                    'excitation_lambda', str2double(metadata.channels{eachChannel}.ex_lambda), ...
                    'excitation_range', [str2double(metadata.channels{eachChannel}.ex_low), str2double(metadata.channels{eachChannel}.ex_high)], ...
                    'emission_lambda', str2double(metadata.channels{eachChannel}.em_lambda), ...
                    'emission_range', [str2double(metadata.channels{eachChannel}.em_low), str2double(metadata.channels{eachChannel}.em_high)] ...
                    );
                
                OptChannels = [OptChannels, OptChan];
                OptChanRefData{end+1} = sprintf('%s-%s-%dnm', metadata.channels{eachChannel}.ex_lambda, metadata.channels{eachChannel}.em_lambda, str2double(metadata.channels{eachChannel}.em_high) - str2double(metadata.channels{eachChannel}.em_low));
            end
            
            orderOpticalChannels = types.ndx_multichannel_volume.OpticalChannelReferences( ...
                'name', 'order_optical_channels', ...
                'channels', OptChanRefData);

            imaging_vol = types.ndx_multichannel_volume.ImagingVolume( ...
                'name', 'ImagingVolume', ...
                'optical_channel_plus', OptChannels, ...
                'order_optical_channels', orderOpticalChannels, ...
                'description', 'NeuroPAL image of C elegans brain', ...
                'device', device, ...
                'location', metadata.worm_bodypart, ...
                'grid_spacing', gridSpacing, ...
                'grid_spacing_unit', gridSpacingUnit, ...
                'origin_coords', originCoords, ...
                'origin_coords_unit', originCoordsUnit, ...
                'reference_frame', referenceFrame);
        end

        function image = create_image(app, data, metadata, imaging_volume, opt_chan_refs)
            image = types.ndx_multichannel_volume.MultiChannelVolume( ...
                'name', 'NeuroPALImageRaw', ...
                'description', metadata.npal_volume_notes, ...
                'RGBW_channels', metadata.rgbw, ...
                'data', data.transpose(1, 0, 2, 3), ...
                'imaging_volume', imaging_volume ...
                );
        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, parent_app, image_neurons, neuron_activity, image_file, csvfile, image_prefs, image_data_zscored, image_um_scale, image_data)
            app.parent_app = parent_app;
            app.image_neurons = image_neurons;
            app.neuron_activity_by_name = neuron_activity;
            app.image_file = image_file;
            
            app.csvfile = csvfile;
            app.image_prefs = image_prefs;
            app.image_data = image_data;
            app.image_data_zscored = image_data_zscored;
            app.image_um_scale = image_um_scale;
            
            Program.GUIHandling.nwb_init(app);
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            d = uiprogressdlg(app.SaveasNWBFileUIFigure,'Title','Saving NWB file...','Indeterminate','off');
            GUI_prefs = Program.GUIPreferences.instance();

            if ~isempty(app.CustomFileName.Value)
                if ~endsWith(app.CustomFileName.Value, '.nwb')
                    path = fullfile(GUI_prefs.image_dir, [app.CustomFileName.Value, '.nwb']);
                else
                    path = fullfile(GUI_prefs.image_dir, app.CustomFileName.Value);
                end
            else
                [~, og_name, ~] = fileparts(app.image_file);
                path = fullfile(GUI_prefs.image_dir, [og_name, '.nwb']);
            end 

            code = DataHandling.writeNWB.write_order(app, path, d);
            close(d)

            switch code
                case 0
                    check = uiconfirm(app.SaveasNWBFileUIFigure, sprintf('Saved file to %s', path), 'Success!', 'Options', ['Close']);
        
                    % Options
                    if app.OpenDANDIaftersavingCheckBox.Value
                        web('https://www.dandiarchive.org/');
                    end

                    if strcmp(check, 'Close')
                        delete(app);
                    end

                otherwise
                    % TBD
            end
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            nwb_data = [];
            nwb_data.proceed = 0;
            app.parent_app.process_nwb_data(nwb_data);
            delete(app)
        end

        % Value changed function: CheckBox
        function CheckBoxValueChanged(app, event)
            app.CustomFileName.Visible = event.Source.Visible;
            app.CustomFileNameLabel.Visible = event.Source.Visible;
        end

        % Callback function
        function ButtonPushed(app, event)
            app.OpticalUITable.Data(end+1) = [app.F1,app.F2,app.F3];
        end

        % Button pushed function: AddHardwareDeviceButton
        function AddHardwareDeviceButtonPushed(app, event)
            device = struct('name', char(app.NameEditField.Value), 'manu', char(app.ManufacturerEditField.Value), 'desc', char(app.HardwareDescriptionTextArea.Value));
            Program.GUIHandling.device_handler(app, 'add', device);
        end

        % Button pushed function: EditButton
        function EditButtonPushed(app, event)
            Program.GUIHandling.device_handler(app, 'edit', app.DeviceUITable.Selection);
        end

        % Button pushed function: RemoveButton
        function RemoveButtonPushed(app, event)
            Program.GUIHandling.device_handler(app, 'remove', app.DeviceUITable.Selection);
        end

        % Button pushed function: AddOpticalChannelButton
        function AddOpticalChannelButtonPushed(app, event)
            channel = struct( ...
                'fluorophore', char(app.FluorophoreEditField.Value), ...
                'filter', char(app.FilterEditField.Value), ...
                'excitation_lambda', char(num2str(app.ExLambdaEditField.Value)), ...
                'excitation_filter_low', char(num2str(app.ExFilterLowEditField.Value)), ...
                'excitation_filter_high', char(num2str(app.ExFilterHighEditField.Value)), ...
                'emmission_lambda', char(num2str(app.EmLambdaEditField.Value)), ...
                'emmission_filter_low', char(num2str(app.EmFilterLowEditField.Value)), ...
                'emmission_filter_high', char(num2str(app.EmFilterHighEditField.Value)));

            Program.GUIHandling.channel_handler(app, 'add', channel);
        end

        % Button pushed function: EditButton_2
        function EditButton_2Pushed(app, event)
            Program.GUIHandling.channel_handler(app, 'edit', channel);
        end

        % Button pushed function: RemoveButton_2
        function RemoveButton_2Pushed(app, event)
            Program.GUIHandling.channel_handler(app, 'remove', app.OpticalUITable.Selection);
        end

        % Clicked callback: StimulusFileSelect
        function StimulusFileSelectClicked(app, event)
            [name, path, ~] = uigetfile(';*.txt;*.nwb', 'Select stimulus file.');
            stim_file = fullfile(path, name);

            app.parent_app.LoadStimuliButton.Tag = stim_file;

            app.StimulusFileSelect.Items{end+1} = stim_file;
            app.StimulusFileSelect.ItemsData{end+1} = stim_file;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create SaveasNWBFileUIFigure and hide until all components are created
            app.SaveasNWBFileUIFigure = uifigure('Visible', 'off');
            app.SaveasNWBFileUIFigure.Position = [100 100 415 658];
            app.SaveasNWBFileUIFigure.Name = 'Save as NWB File';
            app.SaveasNWBFileUIFigure.WindowStyle = 'alwaysontop';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.SaveasNWBFileUIFigure);
            app.GridLayout.ColumnWidth = {135, 250};
            app.GridLayout.RowHeight = {23, 70, 9, 'fit', 23, 395, 9, 65, 'fit'};
            app.GridLayout.RowSpacing = 2;

            % Create Tree
            app.Tree = uitree(app.GridLayout, 'checkbox');
            app.Tree.Editable = 'on';
            app.Tree.Layout.Row = 2;
            app.Tree.Layout.Column = [1 2];

            % Create NeuroPALVolumeNode
            app.NeuroPALVolumeNode = uitreenode(app.Tree);
            app.NeuroPALVolumeNode.Text = 'NeuroPAL Volume';

            % Create VideoVolumeNode
            app.VideoVolumeNode = uitreenode(app.Tree);
            app.VideoVolumeNode.Text = 'Video Volume';

            % Create TrackingROIsNode
            app.TrackingROIsNode = uitreenode(app.VideoVolumeNode);
            app.TrackingROIsNode.Text = 'Tracking ROIs';

            % Create NeuronsNode
            app.NeuronsNode = uitreenode(app.Tree);
            app.NeuronsNode.Text = 'Neurons';

            % Create NeuronalIdentitiesNode
            app.NeuronalIdentitiesNode = uitreenode(app.NeuronsNode);
            app.NeuronalIdentitiesNode.Text = 'Neuronal Identities';

            % Create NeuronalActivityNode
            app.NeuronalActivityNode = uitreenode(app.NeuronsNode);
            app.NeuronalActivityNode.Text = 'Neuronal Activity';

            % Create StimulusFileNode
            app.StimulusFileNode = uitreenode(app.NeuronalActivityNode);
            app.StimulusFileNode.Text = 'Stimulus File';

            % Create AvailableDataLabel
            app.AvailableDataLabel = uilabel(app.GridLayout);
            app.AvailableDataLabel.VerticalAlignment = 'bottom';
            app.AvailableDataLabel.FontWeight = 'bold';
            app.AvailableDataLabel.Layout.Row = 1;
            app.AvailableDataLabel.Layout.Column = 1;
            app.AvailableDataLabel.Text = 'Available Data';

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.BorderType = 'none';
            app.Panel.Layout.Row = [8 9];
            app.Panel.Layout.Column = [1 2];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.Panel);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout2.Padding = [0 0 0 0];

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout2);
            app.Panel_2.BorderType = 'none';
            app.Panel_2.Layout.Row = 1;
            app.Panel_2.Layout.Column = [3 4];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.Panel_2);
            app.GridLayout3.ColumnWidth = {156, '1x'};
            app.GridLayout3.RowHeight = {23};
            app.GridLayout3.ColumnSpacing = 0;

            % Create OpenDANDIaftersavingCheckBox
            app.OpenDANDIaftersavingCheckBox = uicheckbox(app.GridLayout3);
            app.OpenDANDIaftersavingCheckBox.Text = 'Open DANDI after saving.';
            app.OpenDANDIaftersavingCheckBox.Layout.Row = 1;
            app.OpenDANDIaftersavingCheckBox.Layout.Column = 1;

            % Create Hyperlink
            app.Hyperlink = uihyperlink(app.GridLayout3);
            app.Hyperlink.VerticalAlignment = 'top';
            app.Hyperlink.FontSize = 9;
            app.Hyperlink.Layout.Row = 1;
            app.Hyperlink.Layout.Column = 2;
            app.Hyperlink.URL = 'https://www.dandiarchive.org/';
            app.Hyperlink.Text = '(?)';

            % Create SaveButton
            app.SaveButton = uibutton(app.GridLayout2, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Layout.Row = 2;
            app.SaveButton.Layout.Column = [1 2];
            app.SaveButton.Text = 'Save';

            % Create CancelButton
            app.CancelButton = uibutton(app.GridLayout2, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Layout.Row = 2;
            app.CancelButton.Layout.Column = [3 4];
            app.CancelButton.Text = 'Cancel';

            % Create Panel_5
            app.Panel_5 = uipanel(app.GridLayout2);
            app.Panel_5.BorderType = 'none';
            app.Panel_5.Layout.Row = 1;
            app.Panel_5.Layout.Column = [1 2];

            % Create GridLayout3_2
            app.GridLayout3_2 = uigridlayout(app.Panel_5);
            app.GridLayout3_2.ColumnWidth = {14, 5, '1x'};
            app.GridLayout3_2.RowHeight = {23};
            app.GridLayout3_2.ColumnSpacing = 0;

            % Create CheckBox
            app.CheckBox = uicheckbox(app.GridLayout3_2);
            app.CheckBox.ValueChangedFcn = createCallbackFcn(app, @CheckBoxValueChanged, true);
            app.CheckBox.Layout.Row = 1;
            app.CheckBox.Layout.Column = 1;

            % Create CustomFileNameLabel
            app.CustomFileNameLabel = uilabel(app.GridLayout3_2);
            app.CustomFileNameLabel.Layout.Row = 1;
            app.CustomFileNameLabel.Layout.Column = [2 3];
            app.CustomFileNameLabel.Text = ' Custom File Name.';

            % Create CustomFileName
            app.CustomFileName = uieditfield(app.GridLayout3_2, 'text');
            app.CustomFileName.Visible = 'off';
            app.CustomFileName.Placeholder = 'data.nwb';
            app.CustomFileName.Layout.Row = 1;
            app.CustomFileName.Layout.Column = 3;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = [5 7];
            app.TabGroup.Layout.Column = [1 2];

            % Create AuthorTab
            app.AuthorTab = uitab(app.TabGroup);
            app.AuthorTab.Title = 'Author';

            % Create AuthorGrid
            app.AuthorGrid = uigridlayout(app.AuthorTab);
            app.AuthorGrid.ColumnWidth = {135, 230};
            app.AuthorGrid.RowHeight = {23, 23, 9, 23, 23, 9, 23, '1x', 9, 23, 23};
            app.AuthorGrid.RowSpacing = 5;
            app.AuthorGrid.Padding = [10 15 10 10];

            % Create AuthorLaboratoryEditFieldLabel
            app.AuthorLaboratoryEditFieldLabel = uilabel(app.AuthorGrid);
            app.AuthorLaboratoryEditFieldLabel.VerticalAlignment = 'bottom';
            app.AuthorLaboratoryEditFieldLabel.FontWeight = 'bold';
            app.AuthorLaboratoryEditFieldLabel.Layout.Row = 1;
            app.AuthorLaboratoryEditFieldLabel.Layout.Column = 1;
            app.AuthorLaboratoryEditFieldLabel.Text = 'Author / Laboratory';

            % Create AuthorLaboratoryEditField
            app.AuthorLaboratoryEditField = uieditfield(app.AuthorGrid, 'text');
            app.AuthorLaboratoryEditField.Tag = 'credit';
            app.AuthorLaboratoryEditField.Placeholder = '(e.g. "Lorem Ipsum Labs")';
            app.AuthorLaboratoryEditField.Layout.Row = 2;
            app.AuthorLaboratoryEditField.Layout.Column = [1 2];

            % Create InstitutionalAffiliationEditFieldLabel
            app.InstitutionalAffiliationEditFieldLabel = uilabel(app.AuthorGrid);
            app.InstitutionalAffiliationEditFieldLabel.VerticalAlignment = 'bottom';
            app.InstitutionalAffiliationEditFieldLabel.FontWeight = 'bold';
            app.InstitutionalAffiliationEditFieldLabel.Layout.Row = 4;
            app.InstitutionalAffiliationEditFieldLabel.Layout.Column = 1;
            app.InstitutionalAffiliationEditFieldLabel.Text = 'Institutional Affiliation';

            % Create InstitutionalAffiliationEditField
            app.InstitutionalAffiliationEditField = uieditfield(app.AuthorGrid, 'text');
            app.InstitutionalAffiliationEditField.Tag = 'institution';
            app.InstitutionalAffiliationEditField.Placeholder = '(e.g. "Sample University")';
            app.InstitutionalAffiliationEditField.Layout.Row = 5;
            app.InstitutionalAffiliationEditField.Layout.Column = [1 2];

            % Create DatadescriptionTextAreaLabel
            app.DatadescriptionTextAreaLabel = uilabel(app.AuthorGrid);
            app.DatadescriptionTextAreaLabel.VerticalAlignment = 'bottom';
            app.DatadescriptionTextAreaLabel.FontWeight = 'bold';
            app.DatadescriptionTextAreaLabel.Layout.Row = 7;
            app.DatadescriptionTextAreaLabel.Layout.Column = 1;
            app.DatadescriptionTextAreaLabel.Text = 'Data description';

            % Create DatadescriptionTextArea
            app.DatadescriptionTextArea = uitextarea(app.AuthorGrid);
            app.DatadescriptionTextArea.Tag = 'data_description';
            app.DatadescriptionTextArea.Placeholder = '(e.g. description of experiment, notes, etc.)';
            app.DatadescriptionTextArea.Layout.Row = 8;
            app.DatadescriptionTextArea.Layout.Column = [1 2];

            % Create RelatedPublicationsLabel
            app.RelatedPublicationsLabel = uilabel(app.AuthorGrid);
            app.RelatedPublicationsLabel.FontWeight = 'bold';
            app.RelatedPublicationsLabel.Layout.Row = 10;
            app.RelatedPublicationsLabel.Layout.Column = 1;
            app.RelatedPublicationsLabel.Text = 'Related Publications';

            % Create RelatedPublications
            app.RelatedPublications = uieditfield(app.AuthorGrid, 'text');
            app.RelatedPublications.Tag = 'related_publication';
            app.RelatedPublications.Placeholder = '(e.g. a DOI, a link, etc.)';
            app.RelatedPublications.Layout.Row = 11;
            app.RelatedPublications.Layout.Column = [1 2];

            % Create WormTab
            app.WormTab = uitab(app.TabGroup);
            app.WormTab.Title = 'Worm';

            % Create WormGrid
            app.WormGrid = uigridlayout(app.WormTab);
            app.WormGrid.ColumnWidth = {135, '1x'};
            app.WormGrid.RowHeight = {25, 25, 2, 25, 25, 25, 2, 25, 25, '1x'};
            app.WormGrid.Padding = [5 10 5 10];

            % Create StrainEditField_2Label_2
            app.StrainEditField_2Label_2 = uilabel(app.WormGrid);
            app.StrainEditField_2Label_2.HorizontalAlignment = 'right';
            app.StrainEditField_2Label_2.Layout.Row = 8;
            app.StrainEditField_2Label_2.Layout.Column = 1;
            app.StrainEditField_2Label_2.Text = 'Strain';

            % Create StrainEditField
            app.StrainEditField = uieditfield(app.WormGrid, 'text');
            app.StrainEditField.Tag = 'strain';
            app.StrainEditField.Layout.Row = 8;
            app.StrainEditField.Layout.Column = 2;

            % Create WormIdentifierEditFieldLabel
            app.WormIdentifierEditFieldLabel = uilabel(app.WormGrid);
            app.WormIdentifierEditFieldLabel.HorizontalAlignment = 'right';
            app.WormIdentifierEditFieldLabel.Layout.Row = 1;
            app.WormIdentifierEditFieldLabel.Layout.Column = 1;
            app.WormIdentifierEditFieldLabel.Text = 'Worm Identifier';

            % Create WormIdentifierEditField
            app.WormIdentifierEditField = uieditfield(app.WormGrid, 'text');
            app.WormIdentifierEditField.Tag = 'identifier';
            app.WormIdentifierEditField.HorizontalAlignment = 'right';
            app.WormIdentifierEditField.Placeholder = '0000';
            app.WormIdentifierEditField.Layout.Row = 1;
            app.WormIdentifierEditField.Layout.Column = 2;

            % Create SessionDateDatePicker_2Label
            app.SessionDateDatePicker_2Label = uilabel(app.WormGrid);
            app.SessionDateDatePicker_2Label.HorizontalAlignment = 'right';
            app.SessionDateDatePicker_2Label.Layout.Row = 2;
            app.SessionDateDatePicker_2Label.Layout.Column = 1;
            app.SessionDateDatePicker_2Label.Text = 'Session Date';

            % Create SessionDateDatePicker
            app.SessionDateDatePicker = uidatepicker(app.WormGrid);
            app.SessionDateDatePicker.Tag = 'session_date';
            app.SessionDateDatePicker.Layout.Row = 2;
            app.SessionDateDatePicker.Layout.Column = 2;

            % Create AgeDropDown_2Label
            app.AgeDropDown_2Label = uilabel(app.WormGrid);
            app.AgeDropDown_2Label.HorizontalAlignment = 'right';
            app.AgeDropDown_2Label.Layout.Row = 4;
            app.AgeDropDown_2Label.Layout.Column = 1;
            app.AgeDropDown_2Label.Text = 'Age';

            % Create AgeDropDown
            app.AgeDropDown = uidropdown(app.WormGrid);
            app.AgeDropDown.Items = {'Adult', 'L4', 'L3', 'L2', 'L1', '3-Fold'};
            app.AgeDropDown.Tag = 'age';
            app.AgeDropDown.Layout.Row = 4;
            app.AgeDropDown.Layout.Column = 2;
            app.AgeDropDown.Value = 'Adult';

            % Create SexDropDown_2Label
            app.SexDropDown_2Label = uilabel(app.WormGrid);
            app.SexDropDown_2Label.HorizontalAlignment = 'right';
            app.SexDropDown_2Label.Layout.Row = 5;
            app.SexDropDown_2Label.Layout.Column = 1;
            app.SexDropDown_2Label.Text = 'Sex';

            % Create SexDropDown
            app.SexDropDown = uidropdown(app.WormGrid);
            app.SexDropDown.Items = {'XX', 'XO'};
            app.SexDropDown.Tag = 'sex';
            app.SexDropDown.Layout.Row = 5;
            app.SexDropDown.Layout.Column = 2;
            app.SexDropDown.Value = 'XX';

            % Create CultivationtempCEditField_2Label
            app.CultivationtempCEditField_2Label = uilabel(app.WormGrid);
            app.CultivationtempCEditField_2Label.HorizontalAlignment = 'right';
            app.CultivationtempCEditField_2Label.Layout.Row = 9;
            app.CultivationtempCEditField_2Label.Layout.Column = 1;
            app.CultivationtempCEditField_2Label.Text = 'Cultivation temp (°C)';

            % Create CultivationtempCEditField
            app.CultivationtempCEditField = uieditfield(app.WormGrid, 'numeric');
            app.CultivationtempCEditField.Tag = 'cultivation_temp';
            app.CultivationtempCEditField.Layout.Row = 9;
            app.CultivationtempCEditField.Layout.Column = 2;

            % Create BodypartDropDownLabel
            app.BodypartDropDownLabel = uilabel(app.WormGrid);
            app.BodypartDropDownLabel.HorizontalAlignment = 'right';
            app.BodypartDropDownLabel.Layout.Row = 6;
            app.BodypartDropDownLabel.Layout.Column = 1;
            app.BodypartDropDownLabel.Text = 'Body part';

            % Create BodyDropDown
            app.BodyDropDown = uidropdown(app.WormGrid);
            app.BodyDropDown.Items = {'Whole Worm', 'Head', 'Midbody', 'Anterior Midbody', 'Central Midbody', 'Posterior Midbody', 'Tail'};
            app.BodyDropDown.Tag = 'body_part';
            app.BodyDropDown.Layout.Row = 6;
            app.BodyDropDown.Layout.Column = 2;
            app.BodyDropDown.Value = 'Whole Worm';

            % Create NotesTextAreaLabel
            app.NotesTextAreaLabel = uilabel(app.WormGrid);
            app.NotesTextAreaLabel.HorizontalAlignment = 'right';
            app.NotesTextAreaLabel.VerticalAlignment = 'top';
            app.NotesTextAreaLabel.Layout.Row = 10;
            app.NotesTextAreaLabel.Layout.Column = 1;
            app.NotesTextAreaLabel.Text = 'Notes';

            % Create SubjectNotesTextArea
            app.SubjectNotesTextArea = uitextarea(app.WormGrid);
            app.SubjectNotesTextArea.Tag = 'notes';
            app.SubjectNotesTextArea.Layout.Row = 10;
            app.SubjectNotesTextArea.Layout.Column = 2;

            % Create MicroscopeTab
            app.MicroscopeTab = uitab(app.TabGroup);
            app.MicroscopeTab.Title = 'Microscope';

            % Create GridLayout4_2
            app.GridLayout4_2 = uigridlayout(app.MicroscopeTab);
            app.GridLayout4_2.ColumnWidth = {135, 230};
            app.GridLayout4_2.RowHeight = {23, 23, 23, 23, 23, 45, 35, 5, 23, '1x', 23};
            app.GridLayout4_2.RowSpacing = 5;
            app.GridLayout4_2.Padding = [10 10 10 5];

            % Create NameEditFieldLabel
            app.NameEditFieldLabel = uilabel(app.GridLayout4_2);
            app.NameEditFieldLabel.VerticalAlignment = 'bottom';
            app.NameEditFieldLabel.FontWeight = 'bold';
            app.NameEditFieldLabel.Layout.Row = 1;
            app.NameEditFieldLabel.Layout.Column = [1 2];
            app.NameEditFieldLabel.Text = 'Name';

            % Create NameEditField
            app.NameEditField = uieditfield(app.GridLayout4_2, 'text');
            app.NameEditField.Placeholder = '(e.g. "Spinning Disk Confocal")';
            app.NameEditField.Layout.Row = 2;
            app.NameEditField.Layout.Column = [1 2];

            % Create ManufacturerEditFieldLabel
            app.ManufacturerEditFieldLabel = uilabel(app.GridLayout4_2);
            app.ManufacturerEditFieldLabel.VerticalAlignment = 'bottom';
            app.ManufacturerEditFieldLabel.FontWeight = 'bold';
            app.ManufacturerEditFieldLabel.Layout.Row = 3;
            app.ManufacturerEditFieldLabel.Layout.Column = 1;
            app.ManufacturerEditFieldLabel.Text = 'Manufacturer';

            % Create ManufacturerEditField
            app.ManufacturerEditField = uieditfield(app.GridLayout4_2, 'text');
            app.ManufacturerEditField.Placeholder = '(e.g. Nikon)';
            app.ManufacturerEditField.Layout.Row = 4;
            app.ManufacturerEditField.Layout.Column = [1 2];

            % Create HardwareDescriptionTextAreaLabel
            app.HardwareDescriptionTextAreaLabel = uilabel(app.GridLayout4_2);
            app.HardwareDescriptionTextAreaLabel.VerticalAlignment = 'bottom';
            app.HardwareDescriptionTextAreaLabel.FontWeight = 'bold';
            app.HardwareDescriptionTextAreaLabel.Layout.Row = 5;
            app.HardwareDescriptionTextAreaLabel.Layout.Column = 1;
            app.HardwareDescriptionTextAreaLabel.Text = 'Hardware Description';

            % Create HardwareDescriptionTextArea
            app.HardwareDescriptionTextArea = uitextarea(app.GridLayout4_2);
            app.HardwareDescriptionTextArea.Placeholder = '(e.g. Ti-e 60x Objective, 1.2 NA Nikon CFI Plan Apochromat VC 60XC WI)';
            app.HardwareDescriptionTextArea.Layout.Row = 6;
            app.HardwareDescriptionTextArea.Layout.Column = [1 2];

            % Create AddHardwareDeviceButton
            app.AddHardwareDeviceButton = uibutton(app.GridLayout4_2, 'push');
            app.AddHardwareDeviceButton.ButtonPushedFcn = createCallbackFcn(app, @AddHardwareDeviceButtonPushed, true);
            app.AddHardwareDeviceButton.Layout.Row = 7;
            app.AddHardwareDeviceButton.Layout.Column = [1 2];
            app.AddHardwareDeviceButton.Text = 'Add Hardware Device';

            % Create Panel_18
            app.Panel_18 = uipanel(app.GridLayout4_2);
            app.Panel_18.BorderWidth = 0;
            app.Panel_18.Layout.Row = 11;
            app.Panel_18.Layout.Column = [1 2];

            % Create GridLayout13
            app.GridLayout13 = uigridlayout(app.Panel_18);
            app.GridLayout13.RowHeight = {'1x'};
            app.GridLayout13.Padding = [0 0 0 0];

            % Create RemoveButton
            app.RemoveButton = uibutton(app.GridLayout13, 'push');
            app.RemoveButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveButtonPushed, true);
            app.RemoveButton.Layout.Row = 1;
            app.RemoveButton.Layout.Column = 2;
            app.RemoveButton.Text = 'Remove';

            % Create EditButton
            app.EditButton = uibutton(app.GridLayout13, 'push');
            app.EditButton.ButtonPushedFcn = createCallbackFcn(app, @EditButtonPushed, true);
            app.EditButton.Layout.Row = 1;
            app.EditButton.Layout.Column = 1;
            app.EditButton.Text = 'Edit';

            % Create DeviceUITable
            app.DeviceUITable = uitable(app.GridLayout4_2);
            app.DeviceUITable.ColumnName = {'Name'; 'Manufacturer'; 'Description'};
            app.DeviceUITable.ColumnWidth = {60, 100, 'auto'};
            app.DeviceUITable.RowName = {};
            app.DeviceUITable.SelectionType = 'row';
            app.DeviceUITable.ColumnEditable = true;
            app.DeviceUITable.Layout.Row = 10;
            app.DeviceUITable.Layout.Column = [1 2];
            app.DeviceUITable.FontSize = 10;

            % Create DeviceManufacturerEditFieldLabel_2
            app.DeviceManufacturerEditFieldLabel_2 = uilabel(app.GridLayout4_2);
            app.DeviceManufacturerEditFieldLabel_2.VerticalAlignment = 'bottom';
            app.DeviceManufacturerEditFieldLabel_2.FontWeight = 'bold';
            app.DeviceManufacturerEditFieldLabel_2.Layout.Row = 9;
            app.DeviceManufacturerEditFieldLabel_2.Layout.Column = [1 2];
            app.DeviceManufacturerEditFieldLabel_2.Text = 'Device List';

            % Create ChannelsTab
            app.ChannelsTab = uitab(app.TabGroup);
            app.ChannelsTab.Title = 'Channels';

            % Create GridLayout15
            app.GridLayout15 = uigridlayout(app.ChannelsTab);
            app.GridLayout15.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout15.RowHeight = {23, 23, 23, 23, 15, 15, 19, 30, 5, 23, '1x', 23};
            app.GridLayout15.RowSpacing = 5;
            app.GridLayout15.Padding = [10 10 10 5];

            % Create FluorophoreEditFieldLabel
            app.FluorophoreEditFieldLabel = uilabel(app.GridLayout15);
            app.FluorophoreEditFieldLabel.VerticalAlignment = 'bottom';
            app.FluorophoreEditFieldLabel.FontWeight = 'bold';
            app.FluorophoreEditFieldLabel.Layout.Row = 1;
            app.FluorophoreEditFieldLabel.Layout.Column = [1 2];
            app.FluorophoreEditFieldLabel.Text = 'Fluorophore';

            % Create FluorophoreEditField
            app.FluorophoreEditField = uieditfield(app.GridLayout15, 'text');
            app.FluorophoreEditField.Placeholder = '(e.g. "mTagBFP2")';
            app.FluorophoreEditField.Layout.Row = 2;
            app.FluorophoreEditField.Layout.Column = [1 6];

            % Create FilterEditFieldLabel
            app.FilterEditFieldLabel = uilabel(app.GridLayout15);
            app.FilterEditFieldLabel.VerticalAlignment = 'bottom';
            app.FilterEditFieldLabel.FontWeight = 'bold';
            app.FilterEditFieldLabel.Layout.Row = 3;
            app.FilterEditFieldLabel.Layout.Column = 1;
            app.FilterEditFieldLabel.Text = 'Filter';

            % Create FilterEditField
            app.FilterEditField = uieditfield(app.GridLayout15, 'text');
            app.FilterEditField.Placeholder = '(e.g. "Semrock FF01-445/45-25 Brightline")';
            app.FilterEditField.Layout.Row = 4;
            app.FilterEditField.Layout.Column = [1 6];

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.GridLayout15);
            app.GridLayout6.ColumnWidth = {62, '1x', 70, 25};
            app.GridLayout6.RowHeight = {23, '1x'};
            app.GridLayout6.ColumnSpacing = 0;
            app.GridLayout6.RowSpacing = 0;
            app.GridLayout6.Padding = [0 0 0 0];
            app.GridLayout6.Layout.Row = [10 11];
            app.GridLayout6.Layout.Column = [1 6];

            % Create OpticalChannelReferencesLabel
            app.OpticalChannelReferencesLabel = uilabel(app.GridLayout6);
            app.OpticalChannelReferencesLabel.FontWeight = 'bold';
            app.OpticalChannelReferencesLabel.Layout.Row = 1;
            app.OpticalChannelReferencesLabel.Layout.Column = [1 2];
            app.OpticalChannelReferencesLabel.Text = 'Optical Channel References';

            % Create OpticalUITable
            app.OpticalUITable = uitable(app.GridLayout6);
            app.OpticalUITable.ColumnName = {'Protein'; 'Filter'; 'Ex. λ'; 'Ex. Low'; 'Ex. High'; 'Em. λ'; 'Em. Low'; 'Em. High'};
            app.OpticalUITable.RowName = {};
            app.OpticalUITable.SelectionType = 'row';
            app.OpticalUITable.ColumnEditable = true;
            app.OpticalUITable.Layout.Row = 2;
            app.OpticalUITable.Layout.Column = [1 4];
            app.OpticalUITable.FontSize = 10;

            % Create AddOpticalChannelButton
            app.AddOpticalChannelButton = uibutton(app.GridLayout15, 'push');
            app.AddOpticalChannelButton.ButtonPushedFcn = createCallbackFcn(app, @AddOpticalChannelButtonPushed, true);
            app.AddOpticalChannelButton.Layout.Row = 8;
            app.AddOpticalChannelButton.Layout.Column = [1 6];
            app.AddOpticalChannelButton.Text = 'Add Optical Channel';

            % Create Panel_20
            app.Panel_20 = uipanel(app.GridLayout15);
            app.Panel_20.BorderWidth = 0;
            app.Panel_20.Layout.Row = 12;
            app.Panel_20.Layout.Column = [1 6];

            % Create GridLayout16
            app.GridLayout16 = uigridlayout(app.Panel_20);
            app.GridLayout16.RowHeight = {'1x'};
            app.GridLayout16.Padding = [0 0 0 0];

            % Create EditButton_2
            app.EditButton_2 = uibutton(app.GridLayout16, 'push');
            app.EditButton_2.ButtonPushedFcn = createCallbackFcn(app, @EditButton_2Pushed, true);
            app.EditButton_2.Layout.Row = 1;
            app.EditButton_2.Layout.Column = 1;
            app.EditButton_2.Text = 'Edit';

            % Create RemoveButton_2
            app.RemoveButton_2 = uibutton(app.GridLayout16, 'push');
            app.RemoveButton_2.ButtonPushedFcn = createCallbackFcn(app, @RemoveButton_2Pushed, true);
            app.RemoveButton_2.Layout.Row = 1;
            app.RemoveButton_2.Layout.Column = 2;
            app.RemoveButton_2.Text = 'Remove';

            % Create Panel_23
            app.Panel_23 = uipanel(app.GridLayout15);
            app.Panel_23.BorderType = 'none';
            app.Panel_23.Layout.Row = [5 7];
            app.Panel_23.Layout.Column = [1 3];

            % Create GridLayout18
            app.GridLayout18 = uigridlayout(app.Panel_23);
            app.GridLayout18.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout18.RowHeight = {15, 15, 17};
            app.GridLayout18.ColumnSpacing = 5;
            app.GridLayout18.RowSpacing = 5;
            app.GridLayout18.Padding = [2.5 0 2.5 0];
            app.GridLayout18.BackgroundColor = [0.902 0.902 0.902];

            % Create EditField_7Label
            app.EditField_7Label = uilabel(app.GridLayout18);
            app.EditField_7Label.HorizontalAlignment = 'center';
            app.EditField_7Label.WordWrap = 'on';
            app.EditField_7Label.Layout.Row = 2;
            app.EditField_7Label.Layout.Column = 1;
            app.EditField_7Label.Text = 'λ';

            % Create ExLambdaEditField
            app.ExLambdaEditField = uieditfield(app.GridLayout18, 'numeric');
            app.ExLambdaEditField.HorizontalAlignment = 'center';
            app.ExLambdaEditField.Layout.Row = 3;
            app.ExLambdaEditField.Layout.Column = 1;

            % Create FilterLowEditFieldLabel
            app.FilterLowEditFieldLabel = uilabel(app.GridLayout18);
            app.FilterLowEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterLowEditFieldLabel.Layout.Row = 2;
            app.FilterLowEditFieldLabel.Layout.Column = 2;
            app.FilterLowEditFieldLabel.Text = 'Filter Low';

            % Create ExFilterLowEditField
            app.ExFilterLowEditField = uieditfield(app.GridLayout18, 'numeric');
            app.ExFilterLowEditField.HorizontalAlignment = 'center';
            app.ExFilterLowEditField.Layout.Row = 3;
            app.ExFilterLowEditField.Layout.Column = 2;

            % Create FilterHighEditFieldLabel
            app.FilterHighEditFieldLabel = uilabel(app.GridLayout18);
            app.FilterHighEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterHighEditFieldLabel.Layout.Row = 2;
            app.FilterHighEditFieldLabel.Layout.Column = 3;
            app.FilterHighEditFieldLabel.Text = 'Filter High';

            % Create ExFilterHighEditField
            app.ExFilterHighEditField = uieditfield(app.GridLayout18, 'numeric');
            app.ExFilterHighEditField.HorizontalAlignment = 'center';
            app.ExFilterHighEditField.Layout.Row = 3;
            app.ExFilterHighEditField.Layout.Column = 3;

            % Create ExcitationLabel
            app.ExcitationLabel = uilabel(app.GridLayout18);
            app.ExcitationLabel.BackgroundColor = [0.8 0.8 0.8];
            app.ExcitationLabel.HorizontalAlignment = 'center';
            app.ExcitationLabel.FontWeight = 'bold';
            app.ExcitationLabel.Layout.Row = 1;
            app.ExcitationLabel.Layout.Column = [1 3];
            app.ExcitationLabel.Text = 'Excitation';

            % Create Panel_24
            app.Panel_24 = uipanel(app.GridLayout15);
            app.Panel_24.BorderType = 'none';
            app.Panel_24.Layout.Row = [5 7];
            app.Panel_24.Layout.Column = [4 6];

            % Create GridLayout18_2
            app.GridLayout18_2 = uigridlayout(app.Panel_24);
            app.GridLayout18_2.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout18_2.RowHeight = {15, 15, 17};
            app.GridLayout18_2.ColumnSpacing = 5;
            app.GridLayout18_2.RowSpacing = 5;
            app.GridLayout18_2.Padding = [2.5 0 2.5 0];
            app.GridLayout18_2.BackgroundColor = [0.902 0.902 0.902];

            % Create EditField_9Label
            app.EditField_9Label = uilabel(app.GridLayout18_2);
            app.EditField_9Label.HorizontalAlignment = 'center';
            app.EditField_9Label.WordWrap = 'on';
            app.EditField_9Label.Layout.Row = 2;
            app.EditField_9Label.Layout.Column = 1;
            app.EditField_9Label.Text = 'λ';

            % Create EmLambdaEditField
            app.EmLambdaEditField = uieditfield(app.GridLayout18_2, 'numeric');
            app.EmLambdaEditField.HorizontalAlignment = 'center';
            app.EmLambdaEditField.Layout.Row = 3;
            app.EmLambdaEditField.Layout.Column = 1;

            % Create FilterLowEditField_2Label
            app.FilterLowEditField_2Label = uilabel(app.GridLayout18_2);
            app.FilterLowEditField_2Label.HorizontalAlignment = 'center';
            app.FilterLowEditField_2Label.Layout.Row = 2;
            app.FilterLowEditField_2Label.Layout.Column = 2;
            app.FilterLowEditField_2Label.Text = 'Filter Low';

            % Create EmFilterLowEditField
            app.EmFilterLowEditField = uieditfield(app.GridLayout18_2, 'numeric');
            app.EmFilterLowEditField.HorizontalAlignment = 'center';
            app.EmFilterLowEditField.Layout.Row = 3;
            app.EmFilterLowEditField.Layout.Column = 2;

            % Create FilterHighEditField_2Label
            app.FilterHighEditField_2Label = uilabel(app.GridLayout18_2);
            app.FilterHighEditField_2Label.HorizontalAlignment = 'center';
            app.FilterHighEditField_2Label.Layout.Row = 2;
            app.FilterHighEditField_2Label.Layout.Column = 3;
            app.FilterHighEditField_2Label.Text = 'Filter High';

            % Create EmFilterHighEditField
            app.EmFilterHighEditField = uieditfield(app.GridLayout18_2, 'numeric');
            app.EmFilterHighEditField.HorizontalAlignment = 'center';
            app.EmFilterHighEditField.Layout.Row = 3;
            app.EmFilterHighEditField.Layout.Column = 3;

            % Create EmissionLabel_2
            app.EmissionLabel_2 = uilabel(app.GridLayout18_2);
            app.EmissionLabel_2.BackgroundColor = [0.8 0.8 0.8];
            app.EmissionLabel_2.HorizontalAlignment = 'center';
            app.EmissionLabel_2.FontWeight = 'bold';
            app.EmissionLabel_2.Layout.Row = 1;
            app.EmissionLabel_2.Layout.Column = [1 3];
            app.EmissionLabel_2.Text = 'Emission';

            % Create NotesTab
            app.NotesTab = uitab(app.TabGroup);
            app.NotesTab.Title = 'Notes';

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.NotesTab);
            app.GridLayout7.ColumnWidth = {'1x'};
            app.GridLayout7.RowHeight = {'1x'};
            app.GridLayout7.Padding = [0 0 0 0];
            app.GridLayout7.BackgroundColor = [0.902 0.902 0.902];

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.GridLayout7);
            app.TabGroup2.TabLocation = 'right';
            app.TabGroup2.Layout.Row = 1;
            app.TabGroup2.Layout.Column = 1;

            % Create NPALVolumeTab
            app.NPALVolumeTab = uitab(app.TabGroup2);
            app.NPALVolumeTab.Title = 'NPAL Volume';

            % Create NPALVolumeGrid
            app.NPALVolumeGrid = uigridlayout(app.NPALVolumeTab);
            app.NPALVolumeGrid.ColumnWidth = {10, 35, 'fit', 35, 'fit', 35, 15, '1x'};
            app.NPALVolumeGrid.RowHeight = {19, 'fit', 23, 23, 23, '1x'};
            app.NPALVolumeGrid.ColumnSpacing = 1;
            app.NPALVolumeGrid.RowSpacing = 5;
            app.NPALVolumeGrid.Padding = [10 10 10 5];

            % Create HardwareDeviceDropDownLabel
            app.HardwareDeviceDropDownLabel = uilabel(app.NPALVolumeGrid);
            app.HardwareDeviceDropDownLabel.VerticalAlignment = 'bottom';
            app.HardwareDeviceDropDownLabel.FontWeight = 'bold';
            app.HardwareDeviceDropDownLabel.Layout.Row = 3;
            app.HardwareDeviceDropDownLabel.Layout.Column = [1 7];
            app.HardwareDeviceDropDownLabel.Text = 'Hardware Device';

            % Create NpalHardwareDeviceDropDown
            app.NpalHardwareDeviceDropDown = uidropdown(app.NPALVolumeGrid);
            app.NpalHardwareDeviceDropDown.Items = {};
            app.NpalHardwareDeviceDropDown.Tag = 'device';
            app.NpalHardwareDeviceDropDown.FontWeight = 'bold';
            app.NpalHardwareDeviceDropDown.Placeholder = 'Select device...';
            app.NpalHardwareDeviceDropDown.Layout.Row = 4;
            app.NpalHardwareDeviceDropDown.Layout.Column = [1 8];
            app.NpalHardwareDeviceDropDown.Value = {};

            % Create GridSpacingLabel
            app.GridSpacingLabel = uilabel(app.NPALVolumeGrid);
            app.GridSpacingLabel.VerticalAlignment = 'bottom';
            app.GridSpacingLabel.FontWeight = 'bold';
            app.GridSpacingLabel.Layout.Row = 1;
            app.GridSpacingLabel.Layout.Column = [1 8];
            app.GridSpacingLabel.Text = 'Grid Spacing';

            % Create EditField
            app.EditField = uieditfield(app.NPALVolumeGrid, 'numeric');
            app.EditField.Tag = 'grid_x';
            app.EditField.HorizontalAlignment = 'center';
            app.EditField.Layout.Row = 2;
            app.EditField.Layout.Column = 2;

            % Create EditField_2
            app.EditField_2 = uieditfield(app.NPALVolumeGrid, 'numeric');
            app.EditField_2.Tag = 'grid_y';
            app.EditField_2.HorizontalAlignment = 'center';
            app.EditField_2.Layout.Row = 2;
            app.EditField_2.Layout.Column = 4;

            % Create EditField_3
            app.EditField_3 = uieditfield(app.NPALVolumeGrid, 'numeric');
            app.EditField_3.Tag = 'grid_z';
            app.EditField_3.HorizontalAlignment = 'center';
            app.EditField_3.Layout.Row = 2;
            app.EditField_3.Layout.Column = 6;

            % Create Label
            app.Label = uilabel(app.NPALVolumeGrid);
            app.Label.HorizontalAlignment = 'right';
            app.Label.VerticalAlignment = 'top';
            app.Label.FontSize = 15;
            app.Label.Layout.Row = 2;
            app.Label.Layout.Column = 1;
            app.Label.Text = '[';

            % Create Label_2
            app.Label_2 = uilabel(app.NPALVolumeGrid);
            app.Label_2.FontSize = 15;
            app.Label_2.Layout.Row = 2;
            app.Label_2.Layout.Column = 7;
            app.Label_2.Text = ']';

            % Create Label_3
            app.Label_3 = uilabel(app.NPALVolumeGrid);
            app.Label_3.HorizontalAlignment = 'center';
            app.Label_3.FontSize = 15;
            app.Label_3.Layout.Row = 2;
            app.Label_3.Layout.Column = 3;
            app.Label_3.Text = ',';

            % Create Label_4
            app.Label_4 = uilabel(app.NPALVolumeGrid);
            app.Label_4.HorizontalAlignment = 'center';
            app.Label_4.FontSize = 15;
            app.Label_4.Layout.Row = 2;
            app.Label_4.Layout.Column = 5;
            app.Label_4.Text = ',';

            % Create EditField_4
            app.EditField_4 = uieditfield(app.NPALVolumeGrid, 'text');
            app.EditField_4.Tag = 'grid_unit';
            app.EditField_4.Layout.Row = 2;
            app.EditField_4.Layout.Column = 8;
            app.EditField_4.Value = 'micrometers';

            % Create VolumeDescriptionLabel
            app.VolumeDescriptionLabel = uilabel(app.NPALVolumeGrid);
            app.VolumeDescriptionLabel.VerticalAlignment = 'bottom';
            app.VolumeDescriptionLabel.FontWeight = 'bold';
            app.VolumeDescriptionLabel.Layout.Row = 5;
            app.VolumeDescriptionLabel.Layout.Column = [1 8];
            app.VolumeDescriptionLabel.Text = 'Volume Description';

            % Create NpalNotes
            app.NpalNotes = uieditfield(app.NPALVolumeGrid, 'text');
            app.NpalNotes.Tag = 'description';
            app.NpalNotes.Placeholder = 'Insert description here...';
            app.NpalNotes.Layout.Row = 6;
            app.NpalNotes.Layout.Column = [1 8];

            % Create VideoVolumeTab
            app.VideoVolumeTab = uitab(app.TabGroup2);
            app.VideoVolumeTab.Title = 'Video Volume';

            % Create VideoVolumeGrid
            app.VideoVolumeGrid = uigridlayout(app.VideoVolumeTab);
            app.VideoVolumeGrid.RowHeight = {23, 23, 1, 23, '1x', 1, 23, '1x'};
            app.VideoVolumeGrid.RowSpacing = 5;
            app.VideoVolumeGrid.Padding = [10 10 10 5];

            % Create VideoHardwareDeviceLabel
            app.VideoHardwareDeviceLabel = uilabel(app.VideoVolumeGrid);
            app.VideoHardwareDeviceLabel.VerticalAlignment = 'bottom';
            app.VideoHardwareDeviceLabel.FontWeight = 'bold';
            app.VideoHardwareDeviceLabel.Layout.Row = 1;
            app.VideoHardwareDeviceLabel.Layout.Column = [1 2];
            app.VideoHardwareDeviceLabel.Text = 'Video Hardware Device';

            % Create VideoHardwareDeviceDropDown
            app.VideoHardwareDeviceDropDown = uidropdown(app.VideoVolumeGrid);
            app.VideoHardwareDeviceDropDown.Items = {};
            app.VideoHardwareDeviceDropDown.Tag = 'device';
            app.VideoHardwareDeviceDropDown.FontWeight = 'bold';
            app.VideoHardwareDeviceDropDown.Placeholder = 'Select Device';
            app.VideoHardwareDeviceDropDown.Layout.Row = 2;
            app.VideoHardwareDeviceDropDown.Layout.Column = [1 2];
            app.VideoHardwareDeviceDropDown.Value = {};

            % Create NpalNotes_3
            app.NpalNotes_3 = uieditfield(app.VideoVolumeGrid, 'text');
            app.NpalNotes_3.Tag = 'tracking_notes';
            app.NpalNotes_3.Placeholder = 'Insert notes here...';
            app.NpalNotes_3.Layout.Row = 8;
            app.NpalNotes_3.Layout.Column = [1 2];

            % Create TrackingNotesLabel
            app.TrackingNotesLabel = uilabel(app.VideoVolumeGrid);
            app.TrackingNotesLabel.VerticalAlignment = 'bottom';
            app.TrackingNotesLabel.FontWeight = 'bold';
            app.TrackingNotesLabel.Layout.Row = 7;
            app.TrackingNotesLabel.Layout.Column = [1 2];
            app.TrackingNotesLabel.Text = 'Tracking Notes';

            % Create VideoVolumeDescriptionLabel
            app.VideoVolumeDescriptionLabel = uilabel(app.VideoVolumeGrid);
            app.VideoVolumeDescriptionLabel.VerticalAlignment = 'bottom';
            app.VideoVolumeDescriptionLabel.FontWeight = 'bold';
            app.VideoVolumeDescriptionLabel.Layout.Row = 4;
            app.VideoVolumeDescriptionLabel.Layout.Column = [1 2];
            app.VideoVolumeDescriptionLabel.Text = 'Video Volume Description';

            % Create NpalNotes_2
            app.NpalNotes_2 = uieditfield(app.VideoVolumeGrid, 'text');
            app.NpalNotes_2.Tag = 'description';
            app.NpalNotes_2.Placeholder = 'Insert description here...';
            app.NpalNotes_2.Layout.Row = 5;
            app.NpalNotes_2.Layout.Column = [1 2];

            % Create NeuronDataTab
            app.NeuronDataTab = uitab(app.TabGroup2);
            app.NeuronDataTab.Title = 'Neuron Data';

            % Create NeuronDataGrid
            app.NeuronDataGrid = uigridlayout(app.NeuronDataTab);
            app.NeuronDataGrid.RowHeight = {23, '1x', 'fit', 23, '1x', 23, 23};
            app.NeuronDataGrid.RowSpacing = 5;
            app.NeuronDataGrid.Padding = [10 10 10 5];

            % Create NeuronalActivityDescription
            app.NeuronalActivityDescription = uieditfield(app.NeuronDataGrid, 'text');
            app.NeuronalActivityDescription.Tag = 'activity_description';
            app.NeuronalActivityDescription.Placeholder = 'Insert description here...';
            app.NeuronalActivityDescription.Layout.Row = 5;
            app.NeuronalActivityDescription.Layout.Column = [1 2];

            % Create NeuronalActivityDescriptionLabel
            app.NeuronalActivityDescriptionLabel = uilabel(app.NeuronDataGrid);
            app.NeuronalActivityDescriptionLabel.VerticalAlignment = 'bottom';
            app.NeuronalActivityDescriptionLabel.FontWeight = 'bold';
            app.NeuronalActivityDescriptionLabel.Layout.Row = 4;
            app.NeuronalActivityDescriptionLabel.Layout.Column = [1 2];
            app.NeuronalActivityDescriptionLabel.Text = 'Neuronal Activity Description';

            % Create StimulusFileSelect
            app.StimulusFileSelect = uidropdown(app.NeuronDataGrid);
            app.StimulusFileSelect.Items = {};
            app.StimulusFileSelect.Tag = 'stim_file';
            app.StimulusFileSelect.Placeholder = 'Select file...';
            app.StimulusFileSelect.Layout.Row = 7;
            app.StimulusFileSelect.Layout.Column = [1 2];
            app.StimulusFileSelect.ClickedFcn = createCallbackFcn(app, @StimulusFileSelectClicked, true);
            app.StimulusFileSelect.Value = {};

            % Create StimulusFileLabel
            app.StimulusFileLabel = uilabel(app.NeuronDataGrid);
            app.StimulusFileLabel.VerticalAlignment = 'bottom';
            app.StimulusFileLabel.FontWeight = 'bold';
            app.StimulusFileLabel.Layout.Row = 6;
            app.StimulusFileLabel.Layout.Column = 1;
            app.StimulusFileLabel.Text = 'Stimulus File';

            % Create NeuroPALIDsDescriptionLabel
            app.NeuroPALIDsDescriptionLabel = uilabel(app.NeuronDataGrid);
            app.NeuroPALIDsDescriptionLabel.VerticalAlignment = 'bottom';
            app.NeuroPALIDsDescriptionLabel.FontWeight = 'bold';
            app.NeuroPALIDsDescriptionLabel.Layout.Row = 1;
            app.NeuroPALIDsDescriptionLabel.Layout.Column = [1 2];
            app.NeuroPALIDsDescriptionLabel.Text = 'NeuroPAL IDs Description';

            % Create NeuroPALIDsDescription
            app.NeuroPALIDsDescription = uieditfield(app.NeuronDataGrid, 'text');
            app.NeuroPALIDsDescription.Tag = 'id_description';
            app.NeuroPALIDsDescription.Placeholder = 'Insert description here...';
            app.NeuroPALIDsDescription.Layout.Row = 2;
            app.NeuroPALIDsDescription.Layout.Column = [1 2];

            % Create MetadataLabel
            app.MetadataLabel = uilabel(app.GridLayout);
            app.MetadataLabel.VerticalAlignment = 'bottom';
            app.MetadataLabel.FontWeight = 'bold';
            app.MetadataLabel.Layout.Row = 4;
            app.MetadataLabel.Layout.Column = [1 2];
            app.MetadataLabel.Text = 'Metadata';

            % Show the figure after all components are created
            app.SaveasNWBFileUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = nwbsave_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.SaveasNWBFileUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.SaveasNWBFileUIFigure)
        end
    end
end