classdef writeNWB
    % Functions responsible for handling our dynamic GUI solutions.

    properties(Constant, Access=public)
    end

    methods (Static)

        function code = write_order(app, path, progress)
            % Full-shot NWB save routine

            % Grab NWB-compatible metadata from nwbsave.mlapp
            ctx = Program.GUIHandling.read_gui(app);

            % Grab data flags from visualize_light.mlapp so we know which
            % parts of the save routine to skip.
            ctx.flags = Program.GUIHandling.global_grab('NeuroPAL ID', 'data_flags');

            % Grab NWB-compatible data from visualize_light.mlapp
            ctx.colormap.data = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_data');
            ctx.video.info = Program.GUIHandling.global_grab('NeuroPAL ID', 'video_info');

            % Build nwb file.
            ctx.build = struct();
            ctx.build.file = DataHandling.writeNWB.create_file(ctx);
            
            % Initialize variable to store devices objects.
            devices = [];

            % Iterate over hardware devices
            for eachDevice=1:length(ctx.device_table)

                % Get relevant name, description, & manufacturer.
                name = ctx.device_table(eachDevice, 1);
                desc = ctx.device_table(eachDevice, 2);
                manu = ctx.device_table(eachDevice, 3);

                % Create device object & add to device array.
                devices = [devices; DataHandling.writeNWB.create_device(name, desc, manu)];

                % If current device was selected as colormap microscope,
                % save the object for later.
                if strcmp(name, ctx.colormap.device)
                    ctx.colormap.device = new_device;
                end
            end

            % Create optical channel objects.
            ctx.optical_metadata = DataHandling.writeNWB.create_channels(ctx.optical_table);

            % Create required volume objects.
            ctx.colormap.imaging_volume = DataHandling.writeNWB.create_volume(nwb_file, 'imaging', ctx);
            ctx.colormap.multichannel_volume = DataHandling.writeNWB.create_volume(nwb_file, 'multichannel', ctx);
            
            % Initialize struct to store NWB modules.
            ctx.build.modules = struct();

            % Create acquisition module & assign raw volume objects.
            ctx.build.modules.acquisition = DataHandling.writeNWB.create_module('acquisition', ctx);
            ctx.build.file.acquisition.set('NeuroPALImageRaw', ctx.colormap.multichannel_volume);
            ctx.build.file.acquisition.set('ImagingVolume', ctx.colormap.imaging_volume);

            % Create processing module & assign all objects containing work product.
            ctx.build.modules.processing = DataHandling.writeNWB.create_module('processing', ctx);
            ctx.build.modules.processing.nwbdatainterface = types.untyped.Set(ctx.optical_metadata.order, ctx.optical_metadata.channels);
            ctx.build.file.processing.set('NeuroPAL', ctx.build.modules.processing);

            % Check if NWB file to be saved already exists.
            if ~exist(path, "file")
                % If not, save.
                nwbExport(ctx.build.file, path);

            else
                % If it does, save file after appending a "-new" suffix.
                existing_nwb = nwbRead(path);
                existing_nwb.acquisition = types.untyped.Set(existing_nwb.acquisition, nwbfile.acquisition);
                existing_nwb.processing = types.untyped.Set(existing_nwb.processing, nwbfile.processing);
                existing_nwb.general_subject = nwbfile.general_subject;
                nwbExport(nwbfile, strrep(path, '.nwb', '-new.nwb'))

            end

            % Return code 0 to indicate that there were no issues.
            code = 0;
        end

        function nwb_file = create_file(ctx)
            session_date = datetime(posixtime(ctx.worm.session_date),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');

            nwb_file = NwbFile( ...
                'session_description', ctx.author.data_description, ...
                'identifier', ctx.worm.identifier, ...
                'session_start_time', session_date, ...
                'general_lab', ctx.author.credit, ...
                'general_institution', ctx.author.institution, ...
                'general_related_publications', ctx.author.related_publication);

            % Populate subject data
            nwb_file.general_subject = types.ndx_multichannel_volume.CElegansSubject(...
                'subject_id', ctx.worm.identifier, ...
                'age', ctx.worm.age, ...
                'date_of_birth', session_date, ...
                'growth_stage', ctx.worm.age, ...
                'cultivation_temp', ctx.worm.cultivation_temp, ...
                'description', ctx.worm.notes, ...
                'species', 'http://purl.obolibrary.org/obo/NCBITaxon_6239', ...
                'sex', ctx.worm.sex, ...
                'strain', ctx.worm.strain);
        end

        function device = create_device(name, description, manufacturer)
            new_device = types.core.Device(...
                    'name', name, ...
                    'description', description, ...
                    'manufacturer', manufacturer ...
                    );
        end

        function nwb_module = create_module(module, ctx)
            switch module
                case 'acquisition'
                    nwb_module = types.core.AcquisitionModule( ...
                        'name', 'NeuroPAL', ...
                        'description', ctx.colormap.notes);
                case 'processing'
                    nwb_module = types.core.ProcessingModule( ...
                        'name', 'NeuroPAL', ...
                        'description', ctx.colormap.notes);
            end
        end

        function optical_metadata = create_channels(optical_table)
            % Populate channel data
            OptChannels = [];
            OptChanRefData = [];
            
            % Populate device data
            for eachChannel = 1:length(optical_table)
                name = optical_table(eachChannel, 1);
                desc = optical_table(eachChannel, 2);

                ex_lambda = optical_table(eachChannel, 3);
                ex_low = optical_table(eachChannel, 4);
                ex_high = optical_table(eachChannel, 5);
                ex_range = [str2num(ex_low{1}), str2num(ex_high{1})];

                em_lambda = optical_table(eachChannel, 6);
                em_low = optical_table(eachChannel, 7);
                em_high = optical_table(eachChannel, 8);
                em_range = [str2num(em_low{1}), str2num(em_high{1})];
            
                OptChan = types.ndx_multichannel_volume.OpticalChannelPlus( ...
                    'name', name, ...
                    'description', desc, ...
                    'excitation_lambda', ex_lambda, ...
                    'excitation_range', ex_range, ...
                    'emission_lambda', em_lambda, ...
                    'emission_range', em_range ...
                    );
                
                OptChannels = [OptChannels, OptChan];
                new_line = sprintf('%s-%s-%dnm', ex_lambda{1}, em_lambda{1}, str2num(em_high{1}) - str2num(em_low{1}));
                OptChanRefData = [OptChanRefData, new_line];
            end           
            
            orderOpticalChannels = types.ndx_multichannel_volume.OpticalChannelReferences( ...
                'name', 'order_optical_channels', ...
                'channels', OptChanRefData);

            optical_metadata = struct( ...
                'channels', OptChannels, ...
                'reference_data', OptChanRefData, ...
                'order', orderOpticalChannels);
        end

        function nwb_volume = create_volume(module, ctx)
            switch module
                case 'imaging'
                    nwb_volume = types.ndx_multichannel_volume.ImagingVolume( ...
                        'name', 'ImagingVolume', ...
                        'optical_channel_plus', ctx.optical_metadata.channels, ...
                        'order_optical_channels', ctx.optical_metadata.order, ...
                        'description', ctx.colormap.description, ...
                        'device', ctx.colormap.device, ...
                        'location', ctx.worm.body_part, ...
                        'grid_spacing', ctx.colormap.grid_spacing.values, ...
                        'grid_spacing_unit', ctx.colormap.grid_spacing.unit, ...
                        'origin_coords', [0, 0, 0], ...
                        'origin_coords_unit', ctx.colormap.grid_spacing.unit, ...
                        'reference_frame', ['Worm ', ctx.worm.body_part]);
                case 'multichannel'
                    nwb_volume = types.ndx_multichannel_volume.MultiChannelVolume( ...
                        'name', 'NeuroPALImageRaw', ...
                        'description', ctx.colormap.description, ...
                        'RGBW_channels', ctx.colormap.prefs.rgbw, ...
                        'data', ctx.colormap.data, ...
                        'imaging_volume', ctx.colormap.imaging_volume);
                case 'video'
                    % TBD
            end
        end


    end
end