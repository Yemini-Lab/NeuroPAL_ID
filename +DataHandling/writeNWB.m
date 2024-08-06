classdef writeNWB
    % Functions responsible for handling our dynamic GUI solutions.

    properties(Constant, Access=public)
    end

    methods (Static)

        function code = write_order(app, path, progress)
            % Full-shot NWB save routine

            if ~exist('progress', 'var')
                progress = struct();
            end

            % Grab NWB-compatible metadata from nwbsave.mlapp
            progress.Message = 'Parsing metadata...';
            [ctx, device_table, optical_table] = Program.GUIHandling.read_gui(app);

            % Grab data flags from visualize_light.mlapp so we know which
            % parts of the save routine to skip.
            progress.Message = 'Checking flags...';
            ctx.flags = Program.GUIHandling.global_grab('NeuroPAL ID', 'data_flags');

            % Grab NWB-compatible data from visualize_light.mlapp
            progress.Message = 'Loading volume data...';
            ctx.colormap.data = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_data');
            ctx.video.info = Program.GUIHandling.global_grab('NeuroPAL ID', 'video_info');

            ctx.neurons.colormap = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_neurons');
            ctx.neurons.video = Methods.ChunkyMethods.stream_neurons('annotations');
            ctx.neurons.activity_data = Program.GUIHandling.global_grab('NeuroPAL ID', 'activity_table');

            % Build nwb file.
            progress.Message = 'Initializing file...';
            ctx.build = struct();
            ctx.build.file = DataHandling.writeNWB.create_file(ctx);
            
            % Initialize variable to store devices objects.
            devices = [];

            progress.Message = 'Parsing hardware data...';
            % Iterate over hardware devices
            for eachDevice=1:size(device_table, 1)

                % Get relevant name, description, & manufacturer.
                name = device_table(eachDevice, 1);
                desc = device_table(eachDevice, 2);
                manu = device_table(eachDevice, 3);

                % Create device object & add to device array.
                new_device = DataHandling.writeNWB.create_device(name, desc, manu);
                devices = [devices; new_device];

                % If current device was selected as colormap microscope,
                % save the object for later.
                if strcmp(name, ctx.colormap.device)
                    ctx.colormap.device = new_device;
                end

                if strcmp(name, ctx.video.device)
                    ctx.video.device = new_device;
                end
            end

            % Create optical channel objects.
            progress.Message = 'Parsing channel data...';
            ctx.optical_metadata = DataHandling.writeNWB.create_channels(optical_table);
            
            % Initialize struct to store NWB modules.
            progress.Message = 'Building modules...';

            % Create processing module & assign all objects containing work product.
            %ctx.build.file.processing.nwbdatainterface = types.untyped.Set(ctx.optical_metadata.order, ctx.optical_metadata.channels);

            % Create required volume objects.
            if ctx.flags.NeuroPAL_Volume
                progress.Message = 'Populating NeuroPAL volume...';
                ctx.colormap.imaging_volume = DataHandling.writeNWB.create_volume('colormap', 'imaging', ctx);
                ctx.build.file.acquisition.set('NeuroPALImVol', ctx.colormap.imaging_volume);
    
                ctx.colormap.multichannel_volume = DataHandling.writeNWB.create_volume('colormap', 'multichannel', ctx);
                ctx.build.file.acquisition.set('NeuroPALImageRaw', ctx.colormap.multichannel_volume);
                
                progress.Message = 'Populating NeuroPAL settings...';
                gammas = types.hdmf_common.VectorData( ...
                    'description', 'channel gamma values', ...
                    'data', ctx.colormap.prefs.gamma);

                RGBW = types.hdmf_common.VectorData( ...
                    'description', 'RGBW channel indices', ...
                    'data', ctx.colormap.prefs.RGBW);

                ctx.colormap.settings = types.hdmf_common.DynamicTable( ...
                    'description', 'NeuroPAL_ID Settings', ...
                    'colnames', {'gammas', 'RGBW'}, ...
                    'gammas', gammas, ...
                    'RGBW', RGBW);

                ctx.build.file.processing.set('NeuroPAL_ID', ctx.colormap.settings);
            end

            if ctx.flags.Neurons || ctx.flags.Neuronal_Identities
                progress.Message = 'Populating neuronal identities...';
                ctx.neurons.colormap = DataHandling.writeNWB.create_segmentation('colormap', ctx);
                ctx.build.file.processing.set('NeuroPALNeurons', ctx.neurons.colormap);
            end

            if ctx.flags.Video_Volume
                progress.Message = 'Populating video volume...';
                ctx.video.imaging_volume = DataHandling.writeNWB.create_volume('video', 'imaging', ctx);
                ctx.build.file.processing.set('CalciumImVol', ctx.video.imaging_volume);
    
                ctx.video.multichannel_volume = DataHandling.writeNWB.create_volume('video', 'multichannel', ctx);
                ctx.build.file.processing.set('CalciumImageSeries', ctx.video.multichannel_volume);
            end

            if ctx.flags.Tracking_ROIs
                progress.Message = 'Populating tracking ROIs...';
                ctx.neurons.video = DataHandling.writeNWB.create_segmentation('video', ctx);
                ctx.build.file.processing.set(ctx.neurons.video.name, ctx.neurons.video);
            end

            if ctx.flags.Neuronal_Activity
                progress.Message = 'Populating neuronal activity...';
                ctx.neurons.activity = DataHandling.writeNWB.create_traces(ctx);
                ctx.build.file.processing.set(ctx.neurons.activity.name, ctx.neurons.activity);
            end

            if ctx.flags.Stimulus_Files
                progress.Message = 'Populating stimuli...';
                switch class(ctx.neurons.stim_file)
                    case {'char', 'string'}
                        ctx.neurons.stim_table = DataHandling.readStimFile(ctx.neurons.stim_file);
                    case 'table'
                        ctx.neurons.stim_table = ctx.neurons.stim_file;
                end

                ctx.neurons.stim_table = types.core.AnnotationSeries( ...
                    'name', 'StimulusInfo', ...
                    'description', 'Denotes which stimulus was released on which frames.', ...
                    'timestamps', ctx.neurons.stim_table{:, 1}, ...
                    'data', ctx.neurons.stim_table{:, 2});

                ctx.build.file.processing.set(ctx.neurons.stim_table, ctx.neurons.stim_table);
            end


            % Check if NWB file to be saved already exists.
            progress.Message = 'Writing to file...';
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
            device = types.core.Device(...
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
            for eachChannel = 1:size(optical_table, 1)
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

        function nwb_volume = create_volume(preset, module, ctx)
            switch module
                case 'imaging'
                    nwb_volume = types.ndx_multichannel_volume.ImagingVolume( ...
                        'optical_channel_plus', ctx.optical_metadata.channels, ...
                        'order_optical_channels', ctx.optical_metadata.order, ...
                        'description', ctx.(preset).description, ...
                        'device', ctx.(preset).device, ...
                        'location', ctx.worm.body_part, ...
                        'grid_spacing', ctx.(preset).grid_spacing.values, ...
                        'grid_spacing_unit', ctx.(preset).grid_spacing.unit, ...
                        'origin_coords', [0, 0, 0], ...
                        'origin_coords_unit', ctx.(preset).grid_spacing.unit, ...
                        'reference_frame', ['Worm ', ctx.worm.body_part]);
                case 'multichannel'
                    if strcmp(preset, 'colormap')
                        nwb_volume = types.ndx_multichannel_volume.MultiChannelVolume( ...
                            'description', ctx.(preset).description, ...
                            'RGBW_channels', ctx.(preset).prefs.RGBW, ...
                            'data', ctx.colormap.data, ...
                            'imaging_volume', ctx.colormap.imaging_volume);
                    elseif strcmp(preset, 'video')
                        video_preview = Program.GUIHandling.global_grab('NeuroPAL ID', 'retrieve_frame');

                        data_pipe = types.untyped.DataPipe( ...
                            'data', video_preview, ...
                            'maxSize', [ctx.(preset).data.nx ctx.(preset).data.ny ctx.(preset).data.nc ctx.(preset).data.nz ctx.(preset).data.nt], ...
                            'axis', 2);

                        nwb_volume = types.ndx_multichannel_volume.MultiChannelVolume( ...
                            'description', ctx.(preset).description, ...
                            'data', data_pipe, ...
                            'scan_line_rate', ctx.(preset).scan_rate, ...
                            'dimension', data_pipe, ...
                            'resolution', 1, ...
                            'rate', ctx.(preset).scan_rate, ...
                            'imaging_volume', ctx.(preset).imaging_volume);
                    end
            end
        end

        function obj = create_segmentation(preset, ctx)
            switch preset
                case 'colormap'
                    obj = types.ndx_multichannel_volume.VolumeSegmentation( ...
                        'name', 'VolumeSegmentation', ...
                        'description', ctx.neurons.id_description, ...
                        'imaging_volume', ctx.(preset).imaging_volume);

                    voxel_mask = [];
                    for n=1:length(ctx.neurons.(preset).neurons)
                        positions = ctx.neurons.(preset).neurons(n).position;
                        
                        x = positions(1);
                        y = positions(2);
                        z = positions(3);
                        id = ctx.neurons.(preset).neurons(n).annotation;
                        neuron = [x y z {id}];
        
                        voxel_mask = [voxel_mask neuron];
                    end
        
                    voxel_mask = types.hdmf_common.VectorData('data', voxel_mask);
                    obj.voxel_mask = voxel_mask;

                case 'video'
                    obj = types.core.PlaneSegmentation( ...
                        'name', 'TrackedNeurons', ...
                        'description', ctx.video.tracking_notes, ...
                        'imaging_plane', ctx.video.imaging_volume);

                    voxel_mask = [];
                    for n=1:length(ctx.neurons.(preset).labels)
                        positions = ctx.neurons.positions(n);
                        
                        x = positions(1);
                        y = positions(2);
                        z = positions(3);
                        t = positions(4);
                        id = ctx.neurons.labels(n);
                        neuron = [x y z t {id}];
        
                        voxel_mask = [voxel_mask neuron];
                    end
        
                    obj.voxel_mask = voxel_mask;

            end
        end

        function obj = create_traces(ctx)
            roi_table_region = types.hdmf_common.DynamicTableRegion( ...
                'table', types.untyped.ObjectView(ctx.neurons.video), ...
                'description', ctx.video.tracking_description, ...
                'data', (0:length(ctx.neurons.video)));

            obj = types.core.RoiResponseSeries( ...
                'name', 'SignalCalciumImResponseSeries', ...
                'rois', roi_table_region, ...
                'data', ctx.neurons.activity_data, ...
                'data_unit', 'lumens', ...
                'starting_time_rate', 1.0, ...
                'starting_time', 0.0);
        end
    end
end