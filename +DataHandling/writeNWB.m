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

            % Initialize MatNWB with compatible schema version
            try
                % Clear any cached schemas and regenerate with compatible version
                fprintf('DEBUG: Initializing MatNWB with compatible schema...\n');
                generateCore('2.6.0');
                generateExtension('/Users/adamg/neuroPAL/ndx-multichannel-volume/spec/ndx-multichannel-volume.namespace.yaml');
                fprintf('DEBUG: Successfully initialized NWB 2.6.0 with ndx-multichannel-volume\n');
            catch ME
                fprintf('DEBUG: Failed to set specific schema, using defaults: %s\n', ME.message);
            end

            % Grab NWB-compatible metadata from nwbsave.mlapp
            progress.Message = 'Parsing metadata...';
            [ctx, device_table, optical_table] = Program.GUIHandling.read_gui(app);

            % Grab data flags from visualize_light.mlapp so we know which
            % parts of the save routine to skip.
            progress.Message = 'Checking flags...';
            ctx.flags = Program.GUIHandling.global_grab('NeuroPAL ID', 'data_flags');
            
            % Debug: Print all flags
            fprintf('\n=== DEBUG: Data Flags ===\n');
            if isstruct(ctx.flags)
                flag_names = fieldnames(ctx.flags);
                for i = 1:length(flag_names)
                    fprintf('Flag %s = %d\n', flag_names{i}, ctx.flags.(flag_names{i}));
                end
            else
                fprintf('Warning: ctx.flags is not a struct: %s\n', class(ctx.flags));
            end
            fprintf('========================\n\n');

            % Grab NWB-compatible data from visualize_light.mlapp
            progress.Message = 'Loading volume data...';
            
            % Check what data is actually available
            colormap_data = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_data');
            video_info = Program.GUIHandling.global_grab('NeuroPAL ID', 'video_info');
            
            fprintf('=== DEBUG: Available Data ===\n');
            fprintf('colormap_data: %s (size: %s)\n', class(colormap_data), mat2str(size(colormap_data)));
            fprintf('video_info: %s\n', class(video_info));
            fprintf('============================\n\n');
            
            % Determine what data types we have
            has_colormap = ~isempty(colormap_data);
            has_video = ~isempty(video_info);
            
            if ~has_colormap && ~has_video
                error('No image or video data available');
            end
            
            % Validate required context fields
            required_ctx_fields = {'worm', 'author'};
            for field = required_ctx_fields
                if ~isfield(ctx, field{1})
                    error('Missing required context field: %s', field{1});
                end
            end
            
            % Only populate data structures for available data types
            if has_colormap
                ctx.colormap.data = colormap_data;
                ctx.neurons.image_neurons = Program.GUIHandling.global_grab('NeuroPAL ID', 'image_neurons');
                
                % Debug: Check if we got neuron data
                if isempty(ctx.neurons.image_neurons)
                    fprintf('Warning: No neuron data found from global_grab\n');
                else
                    fprintf('Found neuron data with %d neurons\n', length(ctx.neurons.image_neurons.neurons));
                end
                
                % Validate colormap data structure
                if ~isnumeric(colormap_data) || ndims(colormap_data) < 3
                    error('Invalid colormap data format');
                end
            end
            
            if has_video
                ctx.video.info = video_info;
                ctx.neurons.video = Methods.ChunkyMethods.stream_neurons('annotations');
                ctx.neurons.activity_data = Program.GUIHandling.global_grab('NeuroPAL ID', 'activity_table');
                
                % Validate video info structure
                if ~isstruct(video_info)
                    error('Video info must be a structure');
                end
            end

            % Build nwb file.
            progress.Message = 'Initializing file...';
            ctx.build = struct();
            ctx.build.file = DataHandling.writeNWB.create_file(ctx);
            ctx.build.modules = struct();
            
            % Initialize variable to store devices objects.
            devices = [];

            progress.Message = 'Parsing hardware data...';
            % Iterate over hardware devices
            for eachDevice=1:size(device_table, 1)
                
                % Get relevant name, description, & manufacturer, ensuring they are char arrays
                name = char(device_table{eachDevice, 1});
                desc = char(device_table{eachDevice, 2});
                manu = char(device_table{eachDevice, 3});

                % Create device object & add to device array.
                new_device = DataHandling.writeNWB.create_device(name, desc, manu);
                ctx.build.file.general_devices.set(name, new_device);

                % If current device was selected as colormap microscope,
                % save the object for later (only if we have colormap data).
                if has_colormap && strcmp(strtrim(char(name)), strtrim(char(ctx.colormap.device)))
                    ctx.colormap.device = new_device;
                end

                if has_video && strcmp(strtrim(char(name)), strtrim(char(ctx.video.device)))
                    ctx.video.device = new_device;
                end
            end

            % Create optical channel objects.
            progress.Message = 'Parsing channel data...';
            ctx.optical_metadata = DataHandling.writeNWB.create_channels(optical_table);
            
            % Initialize struct to store NWB modules.
            progress.Message = 'Building modules...';

            % Create processing module & assign all objects containing work product.
            ctx.build.processing_modules = struct( ...
                'CalciumActivity', types.core.ProcessingModule('description', 'Calcium time series metadata, segmentation, and fluorescence data.'), ...
                'ProgramSettings', types.core.ProcessingModule('description', 'Various NeuroPAL_ID settings which specify how the colormap is processed once loaded into the program.'));

            % Create required volume objects only if we have the corresponding data.
            if has_colormap && ctx.flags.NeuroPAL_Volume
                progress.Message = 'Populating NeuroPAL volume...';
                ctx.colormap.imaging_volume = DataHandling.writeNWB.create_volume('colormap', 'imaging', ctx);
                
                % Initialize acquisition module if it doesn't exist
                if ~isfield(ctx.build.modules, 'acquisition')
                    ctx.build.modules.acquisition = struct();
                end
                ctx.build.modules.acquisition.NeuroPALImVol = ctx.colormap.imaging_volume;

                ctx.colormap.multichannel_volume = DataHandling.writeNWB.create_volume('colormap', 'multichannel', ctx);
                ctx.build.modules.acquisition.NeuroPALImageRaw = ctx.colormap.multichannel_volume;
                
                progress.Message = 'Populating NeuroPAL settings...';
                gammas = types.hdmf_common.VectorData( ...
                    'description', 'channel gamma values', ...
                    'data', ctx.colormap.prefs.gamma);

                ctx.colormap.settings = types.hdmf_common.DynamicTable( ...
                    'description', 'NeuroPAL_ID Settings', ...
                    'colnames', {'gammas'}, ...
                    'gammas', gammas, ...
                    'id', types.hdmf_common.ElementIdentifiers('data', 0:length(gammas)-1));

                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.NeuroPAL_IDSettings = ctx.colormap.settings;
            end

            % Always save neuron data if it exists, regardless of flags
            if has_colormap && ~isempty(ctx.neurons.image_neurons) && ~isempty(ctx.neurons.image_neurons.neurons)
                progress.Message = 'Populating neuronal identities...';
                fprintf('=== DEBUG: NEURON DATA PROCESSING ===\n');
                fprintf('Number of neurons found: %d\n', length(ctx.neurons.image_neurons.neurons));
                
                % Sample first neuron for debugging
                if length(ctx.neurons.image_neurons.neurons) > 0
                    first_neuron = ctx.neurons.image_neurons.neurons(1);
                    fprintf('First neuron data:\n');
                    fprintf('  annotation: "%s" (type: %s)\n', char(first_neuron.annotation), class(first_neuron.annotation));
                    fprintf('  position: [%g, %g, %g]\n', first_neuron.position(1), first_neuron.position(2), first_neuron.position(3));
                    fprintf('  has color: %s\n', logical(~isempty(first_neuron.color)));
                    fprintf('  deterministic_id: "%s" (type: %s)\n', char(first_neuron.deterministic_id), class(first_neuron.deterministic_id));
                    if ~isempty(first_neuron.probabilistic_ids)
                        fprintf('  probabilistic_ids: %s (type: %s, length: %d)\n', ...
                            strjoin(cellfun(@char, first_neuron.probabilistic_ids, 'UniformOutput', false), ', '), ...
                            class(first_neuron.probabilistic_ids), length(first_neuron.probabilistic_ids));
                    else
                        fprintf('  probabilistic_ids: empty\n');
                    end
                    % Check covariance data
                    if ~isempty(first_neuron.covariance)
                        fprintf('  covariance: %s, has NaN: %s\n', mat2str(size(first_neuron.covariance)), any(isnan(first_neuron.covariance(:))));
                        fprintf('  covariance sample: [%g, %g, %g; %g, %g, %g; %g, %g, %g]\n', first_neuron.covariance(:)');
                    else
                        fprintf('  covariance: empty\n');
                    end
                    % Check annotation status
                    if ~isempty(first_neuron.is_annotation_on)
                        fprintf('  is_annotation_on: %g\n', first_neuron.is_annotation_on);
                    else
                        fprintf('  is_annotation_on: empty (will default to ON)\n');
                    end
                end
                
                % Only create segmentation if flags allow it
                if (ctx.flags.Neurons || ctx.flags.Neuronal_Identities)
                    ctx.neurons.colormap = DataHandling.writeNWB.create_segmentation('colormap', ctx);
                    fprintf('Created segmentation data\n');
                end
                
                % Always store neuron annotations and metadata in NWB file when neuron data exists
                fprintf('Creating neuron annotations...\n');
                ctx.neurons.annotations = DataHandling.writeNWB.create_neuron_annotations(ctx);
                
                fprintf('Creating detection parameters...\n');
                ctx.neurons.detection_params = DataHandling.writeNWB.create_detection_params(ctx);
                
                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                
                % Add segmentation only if it was created
                if isfield(ctx.neurons, 'colormap') && ~isempty(ctx.neurons.colormap)
                    ctx.build.modules.processing.ColormapNeurons = ctx.neurons.colormap;
                    fprintf('Added segmentation to processing modules\n');
                end
                
                % Add neuron annotations and detection parameters only if they were created
                if ~isempty(ctx.neurons.annotations)
                    ctx.build.modules.processing.NeuronAnnotations = ctx.neurons.annotations;
                    fprintf('✓ Added neuron annotations processing module to NWB file\n');
                    
                    % Debug: check structure of annotations module
                    ann_mod = ctx.neurons.annotations;
                    fprintf('Annotations module type: %s\n', class(ann_mod));
                    if isprop(ann_mod, 'dynamictable') && ~isempty(ann_mod.dynamictable)
                        tables = ann_mod.dynamictable.keys;
                        fprintf('Dynamic tables in annotations module: %s\n', strjoin(tables, ', '));
                    end
                else
                    fprintf('⚠ Warning: Neuron annotations module is empty!\n');
                end
                
                if ~isempty(ctx.neurons.detection_params)
                    ctx.build.modules.processing.DetectionParameters = ctx.neurons.detection_params;
                    fprintf('✓ Added detection parameters processing module to NWB file\n');
                    
                    % Debug: check structure of detection params module
                    det_mod = ctx.neurons.detection_params;
                    fprintf('Detection params module type: %s\n', class(det_mod));
                    if isprop(det_mod, 'dynamictable') && ~isempty(det_mod.dynamictable)
                        tables = det_mod.dynamictable.keys;
                        fprintf('Dynamic tables in detection params module: %s\n', strjoin(tables, ', '));
                    end
                else
                    fprintf('⚠ Warning: Detection parameters module is empty!\n');
                end
                
                fprintf('✓ Successfully processed neuron annotation data for NWB file\n');
                fprintf('=====================================\n\n');
            else
                if has_colormap
                    if isempty(ctx.neurons.image_neurons)
                        fprintf('Debug: No neuron data available for NWB export\n');
                    elseif isempty(ctx.neurons.image_neurons.neurons)
                        fprintf('Debug: Neuron object exists but contains no neurons\n');
                    end
                end
            end

            if has_video && ctx.flags.Video_Volume
                progress.Message = 'Populating video volume...';
                ctx.video.imaging_volume = DataHandling.writeNWB.create_volume('video', 'imaging', ctx);
                
                % Initialize acquisition module if it doesn't exist
                if ~isfield(ctx.build.modules, 'acquisition')
                    ctx.build.modules.acquisition = struct();
                end
                ctx.build.modules.acquisition.CalciumImVol = ctx.video.imaging_volume;

                ctx.video.multichannel_volume = DataHandling.writeNWB.create_volume('video', 'multichannel', ctx);
                ctx.build.modules.acquisition.CalciumImageSeries = ctx.video.multichannel_volume;
            end

            if has_video && ctx.flags.Tracking_ROIs
                progress.Message = 'Populating tracking ROIs...';
                ctx.neurons.video = DataHandling.writeNWB.create_segmentation('video', ctx);
                
                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.TrackedNeuronROIs = ctx.neurons.video;
            end

            if has_video && ctx.flags.Neuronal_Activity
                progress.Message = 'Populating neuronal activity...';
                ctx.neurons.activity = DataHandling.writeNWB.create_traces(ctx);
                
                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.ActivityTraces = ctx.neurons.activity;
            end

            if ctx.flags.Stimulus_Files
                progress.Message = 'Populating stimuli...';
                switch class(ctx.neurons.stim_file)
                    case {'char', 'string'}
                        ctx.neurons.stim_table = DataHandling.readStimFile(ctx.neurons.stim_file);
                    case 'table'
                        ctx.neurons.stim_table = ctx.neurons.stim_file;
                end

                stim_series = types.core.AnnotationSeries( ...
                    'name', 'StimulusInfo', ...
                    'description', 'Denotes which stimulus was released on which frames.', ...
                    'timestamps', ctx.neurons.stim_table{:, 1}, ...
                    'data', ctx.neurons.stim_table{:, 2});

                % Initialize processing module if it doesn't exist
                if ~isfield(ctx.build.modules, 'processing')
                    ctx.build.modules.processing = struct();
                end
                ctx.build.modules.processing.StimulusInfo = stim_series;
            end

            % Check if NWB file to be saved already exists.
            progress.Message = 'Writing to file...';
            
            module_names = fieldnames(ctx.build.modules);
            processing_names = fieldnames(ctx.build.processing_modules);
            for mod=1:length(module_names)
                parent = module_names{mod};
                obj_struct = ctx.build.modules.(parent);
                obj_names = fieldnames(obj_struct);

                for obj=1:length(obj_names)
                    obj_name = obj_names{obj};
                    obj_data = obj_struct.(obj_name);

                    switch class(obj_data)
                        case {'types.ndx_multichannel_volume.MultiChannelVolume', 'types.ndx_multichannel_volume.MultiChannelVolumeSeries'}
                            ctx.build.file.(parent).set(obj_name, obj_data);

                        case 'types.ndx_multichannel_volume.ImagingVolume'
                            ctx.build.file.general_optophysiology.set(obj_name, obj_data);

                        case {'types.hdmf_common.DynamicTable', 'types.core.PlaneSegmentation', 'types.ndx_multichannel_volume.VolumeSegmentation'}
                            if any(ismember('gammas', obj_data.colnames))
                                ctx.build.processing_modules.('ProgramSettings').dynamictable.set(obj_name, obj_data);
                            else
                                ctx.build.processing_modules.('CalciumActivity').dynamictable.set(obj_name, obj_data);
                            end

                        case 'types.core.ProcessingModule'
                            % Handle ProcessingModule directly - add it to the file's processing modules
                            ctx.build.file.processing.set(obj_name, obj_data);
                            fprintf('Added ProcessingModule "%s" directly to file\n', obj_name);

                        case {'types.core.NWBDataInterface', 'types.core.TimeSeries', 'types.core.RoiResponseSeries'}
                            ctx.build.processing_modules.('CalciumActivity').nwbdatainterface.set(obj_name, obj_data);

                        otherwise
                            fprintf('Unhandled object type for %s: %s\n', obj_name, class(obj_data));
                    end
                end
            end

            for proc=1:length(processing_names)
                name = processing_names{proc};
                module = ctx.build.processing_modules.(name);
                ctx.build.file.processing.set(name, module);
            end

            % Fix imaging plane device references before export
            try
                ctx.build.file = DataHandling.writeNWB.fix_imaging_plane_export(ctx.build.file);
            catch ME
                warning('Could not fix imaging plane references: %s', ME.message);
            end

            % Export NWB file with error handling
            try
                if ~exist(path, "file")
                    % Save new file
                    progress.Message = 'Exporting NWB file...';
                    
                    % Debug: List all processing modules before export
                    fprintf('\n=== DEBUG: Processing modules in file ===\n');
                    if ~isempty(ctx.build.file.processing)
                        proc_keys = ctx.build.file.processing.keys;
                        fprintf('Processing modules: %s\n', strjoin(proc_keys, ', '));
                        for i = 1:length(proc_keys)
                            key = proc_keys{i};
                            mod = ctx.build.file.processing.get(key);
                            fprintf('Module "%s" type: %s\n', key, class(mod));
                            if isprop(mod, 'dynamictable') && ~isempty(mod.dynamictable)
                                dt_keys = mod.dynamictable.keys;
                                fprintf('  DynamicTables: %s\n', strjoin(dt_keys, ', '));
                            end
                        end
                    else
                        fprintf('No processing modules found!\n');
                    end
                    fprintf('==========================================\n\n');
                    
                    nwbExport(ctx.build.file, path);
                    fprintf('Successfully saved NWB file: %s\n', path);
                    
                    % Verify data was saved by reading it back
                    fprintf('\n=== VERIFICATION: Reading back saved data ===\n');
                    try
                        saved_nwb = nwbRead(path);
                        if any(ismember(saved_nwb.processing.keys, 'NeuronAnnotations'))
                            fprintf('✓ NeuronAnnotations found in saved file\n');
                            ann_mod = saved_nwb.processing.get('NeuronAnnotations');
                            if any(ismember(ann_mod.dynamictable.keys, 'NeuronAnnotations'))
                                ann_table = ann_mod.dynamictable.get('NeuronAnnotations');
                                fprintf('✓ NeuronAnnotations table has %d rows\n', ann_table.height);
                            else
                                fprintf('⚠ NeuronAnnotations table not found in module\n');
                            end
                        else
                            fprintf('⚠ NeuronAnnotations not found in saved file!\n');
                        end
                        
                        if any(ismember(saved_nwb.processing.keys, 'DetectionParameters'))
                            fprintf('✓ DetectionParameters found in saved file\n');
                        else
                            fprintf('⚠ DetectionParameters not found in saved file!\n');
                        end
                    catch verify_ME
                        fprintf('⚠ Could not verify saved data: %s\n', verify_ME.message);
                    end
                    fprintf('============================================\n\n');
                    
                    % No longer create companion ID file - all data is in NWB
                    fprintf('All neuron data saved within NWB file - no companion ID file needed.\n');
                else
                    % Merge with existing file
                    progress.Message = 'Merging with existing NWB file...';
                    warning('File %s already exists. Creating merged file with "-new" suffix.', path);
                    
                    existing_nwb = nwbRead(path);
                    
                    % Merge data structures safely
                    if ~isempty(ctx.build.file.acquisition)
                        existing_nwb.acquisition = types.untyped.Set(existing_nwb.acquisition, ctx.build.file.acquisition);
                    end
                    if ~isempty(ctx.build.file.processing)
                        existing_nwb.processing = types.untyped.Set(existing_nwb.processing, ctx.build.file.processing);
                    end
                    if ~isempty(ctx.build.file.general_subject)
                        existing_nwb.general_subject = ctx.build.file.general_subject;
                    end
                    
                    new_path = strrep(path, '.nwb', '-new.nwb');
                    nwbExport(existing_nwb, new_path);
                    fprintf('Successfully saved merged NWB file: %s\n', new_path);
                    
                    % No longer create companion ID file for merged file
                    fprintf('All neuron data saved within merged NWB file - no companion ID file needed.\n');
                end
            catch ME
                error('Failed to export NWB file: %s\nStack trace:\n%s', ME.message, getReport(ME));
            end

            % Return code 0 to indicate that there were no issues.
            code = 0;
        end

        function nwb_file = create_file(ctx)
            session_date = datetime(posixtime(ctx.worm.session_date),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');

            % Force use of a compatible NWB schema version
            try
                % Try to use NWB 2.6.0 which should be more compatible
                generateCore('2.6.0');
                fprintf('DEBUG: Using NWB schema version 2.6.0\n');
            catch
                % Fall back to default if 2.6.0 is not available
                try
                    generateCore('2.5.0');
                    fprintf('DEBUG: Using NWB schema version 2.5.0\n');
                catch
                    fprintf('DEBUG: Using default NWB schema version\n');
                end
            end

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
                
                % Use str2double instead of deprecated str2num
                try
                    ex_range = [str2double(ex_low{1}), str2double(ex_high{1})];
                catch
                    warning('Could not parse excitation range for channel %d, using defaults', eachChannel);
                    ex_range = [400, 500]; % Default range
                end

                em_lambda = optical_table(eachChannel, 6);
                em_low = optical_table(eachChannel, 7);
                em_high = optical_table(eachChannel, 8);
                
                try
                    em_range = [str2double(em_low{1}), str2double(em_high{1})];
                catch
                    warning('Could not parse emission range for channel %d, using defaults', eachChannel);
                    em_range = [500, 600]; % Default range
                end
            
                OptChan = types.ndx_multichannel_volume.OpticalChannelPlus( ...
                    'name', name, ...
                    'description', desc, ...
                    'excitation_lambda', ex_lambda, ...
                    'excitation_range', ex_range, ...
                    'emission_lambda', em_lambda, ...
                    'emission_range', em_range ...
                    );
                
                OptChannels = [OptChannels, OptChan];
                
                % Create reference string with proper error handling
                try
                    bandwidth = str2double(em_high{1}) - str2double(em_low{1});
                    new_line = sprintf('%s-%s-%dnm', ex_lambda{1}, em_lambda{1}, round(bandwidth));
                catch
                    new_line = sprintf('%s-%s-default', ex_lambda{1}, em_lambda{1});
                end
                OptChanRefData = [OptChanRefData, new_line];
            end           
            
            orderOpticalChannels = types.ndx_multichannel_volume.OpticalChannelReferences( ...
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
                        'opticalchannelplus', ctx.optical_metadata.channels, ...
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
                        original_data = ctx.(preset).data;
                        if isa(original_data, 'double')
                            % Get data range and determine appropriate scaling
                            data_min = min(original_data(:));
                            data_max = max(original_data(:));
                            
                            % Use more conservative scaling to preserve precision
                            % Scale to uint16 range unless data requires larger range
                            if data_max > data_min
                                data_range = data_max - data_min;
                                if data_range <= 1.0
                                    % Normalized data (0-1), scale to uint16
                                    scaled_data = (original_data - data_min) / data_range * 65535;
                                    converted_data = uint16(round(scaled_data));
                                else
                                    % Larger range, use uint32 for better precision
                                    scaled_data = (original_data - data_min) / data_range * 4294967295;
                                    converted_data = uint32(round(scaled_data));
                                end
                            else
                                % Constant data
                                converted_data = uint16(zeros(size(original_data)));
                            end
                        else
                            % Already integer type, convert to uint64 for consistency
                            converted_data = uint64(original_data);
                        end
                        
                        nwb_volume = types.ndx_multichannel_volume.MultiChannelVolume( ...
                            'description', ctx.(preset).description, ...
                            'RGBW_channels', ctx.(preset).prefs.RGBW, ...
                            'data', converted_data, ...
                            'imaging_volume', types.untyped.SoftLink('/general/optophysiology/NeuroPALImVol'));
                    elseif strcmp(preset, 'video')
                        rf_app = Program.GUIHandling.get_parent_app(Program.GUIHandling.global_grab('NeuroPAL ID', 'CELL_ID'));
                        
                        % Validate video info fields
                        required_fields = {'ny', 'nx', 'nz', 'nc', 'nt'};
                        for field = required_fields
                            if ~isfield(ctx.(preset).info, field{1}) || isempty(ctx.(preset).info.(field{1}))
                                error('Missing required video info field: %s', field{1});
                            end
                        end
                        
                        % Initialize DataPipe with the first frame
                        try
                            fprintf('DEBUG: Initializing video export (Frame 1/%d)...\n', ctx.(preset).info.nt);
                            first_frame = rf_app.retrieve_frame(1);
                            
                            % Ensure frame has correct dimensions (x, y, z, c)
                            % DataPipe expects (x, y, z, c, t)
                            
                            data_pipe = types.untyped.DataPipe( ...
                                'data', uint64(first_frame), ...
                                'maxSize', [ctx.(preset).info.ny ctx.(preset).info.nx ctx.(preset).info.nz ctx.(preset).info.nc ctx.(preset).info.nt], ...
                                'axis', 5);
                                
                            % Iteratively append the rest of the frames
                            if ctx.(preset).info.nt > 1
                                progress.Message = 'Exporting video frames...';
                                for t = 2:ctx.(preset).info.nt
                                    if mod(t, 10) == 0
                                        fprintf('DEBUG: Exporting frame %d/%d\n', t, ctx.(preset).info.nt);
                                        % Update progress bar if available (assuming progress is a uiprogressdlg or similar)
                                        % progress.Value = t / ctx.(preset).info.nt; 
                                    end
                                    
                                    frame = rf_app.retrieve_frame(t);
                                    data_pipe.append(uint64(frame));
                                end
                            end
                            fprintf('DEBUG: Video export complete.\n');
                            
                        catch ME
                            warning('Video export failed: %s', ME.message);
                            % Fallback to empty or partial data if export fails
                            if ~exist('data_pipe', 'var')
                                data_pipe = types.untyped.DataPipe( ...
                                    'data', uint64(zeros([ctx.(preset).info.ny ctx.(preset).info.nx ctx.(preset).info.nz ctx.(preset).info.nc 1])), ...
                                    'maxSize', [ctx.(preset).info.ny ctx.(preset).info.nx ctx.(preset).info.nz ctx.(preset).info.nc ctx.(preset).info.nt], ...
                                    'axis', 5);
                            end
                        end

                        if ~isfield(ctx.(preset), 'scan_rate')
                            ctx.(preset).scan_line_rate = 1;
                            ctx.(preset).scan_rate = 1;
                        end

                        nwb_volume = types.ndx_multichannel_volume.MultiChannelVolumeSeries( ...
                            'description', ctx.(preset).description, ...
                            'data', data_pipe, ...
                            'device', ctx.(preset).device, ...
                            'imaging_volume', types.untyped.SoftLink('/general/optophysiology/CalciumImVol'));
                    end
            end
        end

        function obj = create_segmentation(preset, ctx)
            switch preset
                case 'colormap'        
                    positions = ctx.neurons.image_neurons.get_positions;
                    
                    % Create proper SoftLink references
                    imaging_volume_link = types.untyped.SoftLink('/general/optophysiology/NeuroPALImVol');
                    
                    obj = types.ndx_multichannel_volume.VolumeSegmentation( ...
                        'colnames', {'voxel_mask'}, ...
                        'description', ctx.neurons.id_description, ...
                        'voxel_mask', types.hdmf_common.VectorData('description', 'Neuron ROIs', 'data', positions'), ...
                        'id', types.hdmf_common.ElementIdentifiers('data', 0:length(positions')-1), ...
                        'imaging_volume', imaging_volume_link, ...
                        'imaging_plane', imaging_volume_link);

                    labels = {};
                    for n=1:length(ctx.neurons.image_neurons.neurons)
                        labels{end+1} = ctx.neurons.image_neurons.neurons(n).annotation;
                    end

                    obj.addColumn('neuron_ids', types.hdmf_common.VectorData('description', 'Neuron IDs', 'data', labels'));

                case 'video'
                    positions = ctx.neurons.(preset).positions;
                    
                    % Create proper SoftLink reference for video
                    video_imaging_volume_link = types.untyped.SoftLink('/general/optophysiology/CalciumImVol');
                    
                    obj = types.core.PlaneSegmentation( ...
                        'name', 'TrackedNeurons', ...
                        'colnames', {'voxel_mask', 'labels'}, ...
                        'description', ctx.video.tracking_notes, ...
                        'voxel_mask', types.hdmf_common.VectorData('description', 'Neuron ROIs', 'data', positions'), ...
                        'labels', types.hdmf_common.VectorData('description', 'Neuron IDs', 'data', ctx.neurons.(preset).labels), ...
                        'id', types.hdmf_common.ElementIdentifiers('data', 0:length(positions')-1), ...
                        'imaging_plane', video_imaging_volume_link);
            end
        end

        function obj = create_traces(ctx)
            % Validate activity data exists
            if isempty(ctx.neurons.activity_data)
                error('No activity data available for trace creation');
            end
            
            % Validate video segmentation exists
            if isempty(ctx.neurons.video)
                error('No video segmentation available for trace creation');
            end
            
            % Create table region with proper indexing
            num_rois = length(ctx.neurons.video);
            roi_indices = 0:(num_rois-1);  % 0-based indexing for NWB
            
            roi_table_region = types.hdmf_common.DynamicTableRegion( ...
                'table', types.untyped.ObjectView(ctx.neurons.video), ...
                'description', ctx.video.tracking_notes, ...
                'data', roi_indices);

            % Convert activity data and validate dimensions
            activity_array = table2array(ctx.neurons.activity_data);
            if size(activity_array, 2) ~= num_rois
                warning('Activity data dimensions do not match number of ROIs. Adjusting...');
                % Take minimum to avoid index errors
                min_size = min(size(activity_array, 2), num_rois);
                activity_array = activity_array(:, 1:min_size);
                roi_indices = roi_indices(1:min_size);
                roi_table_region.data = roi_indices;
            end

            obj = types.core.RoiResponseSeries( ...
                'name', 'SignalCalciumImResponseSeries', ...
                'rois', roi_table_region, ...
                'data', activity_array, ...
                'data_unit', 'lumens', ...
                'starting_time_rate', 1.0, ...
                'starting_time', 0.0);
        end

        function nwb_obj = fix_imaging_plane_export(nwb_obj)
            % Fix imaging plane device references before export
            
            try
                % Ensure general optophysiology structure exists
                if ~isprop(nwb_obj, 'general_optophysiology') || isempty(nwb_obj.general_optophysiology)
                    return;
                end
                
                imaging_planes = nwb_obj.general_optophysiology;
                
                % Ensure devices exist
                if ~isprop(nwb_obj, 'general_devices') || isempty(nwb_obj.general_devices)
                    % Create a default device if none exists
                    device = types.core.Device('description', 'Default imaging device');
                    nwb_obj.general_devices = types.untyped.Set();
                    nwb_obj.general_devices.set('default_device', device);
                    default_device_ref = types.untyped.SoftLink('/general/devices/default_device');
                else
                    devices = nwb_obj.general_devices;
                    device_keys = keys(devices);
                    if ~isempty(device_keys)
                        % Use reference to existing device
                        default_device_ref = types.untyped.SoftLink(['/general/devices/' device_keys{1}]);
                    else
                        % Create a default device
                        device = types.core.Device('description', 'Default imaging device');
                        devices.set('default_device', device);
                        default_device_ref = types.untyped.SoftLink('/general/devices/default_device');
                    end
                end
                
                % Fix each imaging plane's device reference
                if isa(imaging_planes, 'types.untyped.Set')
                    plane_keys = keys(imaging_planes);
                    for i = 1:length(plane_keys)
                        plane = imaging_planes.get(plane_keys{i});
                        if isempty(plane.device) || ~isa(plane.device, 'types.untyped.SoftLink')
                            fprintf('Fixing device reference for imaging plane: %s\n', plane_keys{i});
                            plane.device = default_device_ref;
                        end
                    end
                end
                
            catch ME
                warning('Could not fix imaging plane device references: %s', ME.message);
                fprintf('Stack trace:\n');
                for i = 1:length(ME.stack)
                    fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
                end
            end
        end

        function create_companion_id_file(nwb_path, progress)
            %CREATE_COMPANION_ID_FILE DEPRECATED - Create companion _ID.mat file for saved NWB file
            %
            % This function is deprecated. Neuron data is now stored directly in the NWB file
            % using the ndx-multichannel-volume extension.
            
            warning('create_companion_id_file is deprecated. All neuron data is now stored within the NWB file.');
            fprintf('No companion ID file created. All data is contained within the NWB file.\n');
        end
        
        function annotations_module = create_neuron_annotations(ctx)
            %CREATE_NEURON_ANNOTATIONS Create neuron annotations data structure for NWB file
            %
            % This function creates a comprehensive data structure containing all neuron
            % annotation data that was previously stored in the companion ID file.
            
            neurons = ctx.neurons.image_neurons;
            if isempty(neurons)
                fprintf('Warning: No neurons object found in ctx.neurons.image_neurons\n');
                annotations_module = [];
                return;
            end
            
            if isempty(neurons.neurons)
                fprintf('Warning: Neurons object exists but contains no neurons\n');
                annotations_module = [];
                return;
            end
            
            fprintf('Creating neuron annotations for %d neurons\n', length(neurons.neurons));
            
            % Extract neuron annotation data
            num_neurons = length(neurons.neurons);
            annotations = cell(num_neurons, 1);
            annotation_confidences = zeros(num_neurons, 1);
            is_annotation_on = ones(num_neurons, 1); % Default to ON (1) instead of OFF (0)
            is_emphasized = false(num_neurons, 1);
            deterministic_ids = cell(num_neurons, 1);
            probabilistic_ids_str = cell(num_neurons, 1); % Store as JSON-like strings
            probabilistic_probs = zeros(num_neurons, 7);
            ranks = zeros(num_neurons, 1);
            positions = zeros(num_neurons, 3);
            colors = zeros(num_neurons, 4);
            color_readouts = zeros(num_neurons, 4);
            baselines = zeros(num_neurons, 4);
            covariances = zeros(3, 3, num_neurons);
            aligned_xyzRGBs = zeros(num_neurons, 6);
            
            for i = 1:num_neurons
                n = neurons.neurons(i);
                
                % User annotations
                if isempty(n.annotation)
                    annotations{i} = '';
                else
                    annotations{i} = char(string(n.annotation));
                end
                
                if isempty(n.annotation_confidence)
                    annotation_confidences(i) = 0;
                else
                    annotation_confidences(i) = n.annotation_confidence;
                end
                
                % Force neurons to be ON if they have annotations
                % Only set to OFF if explicitly intended to be hidden
                if ~isempty(n.annotation) && ~strcmp(n.annotation, '')
                    % If neuron has an annotation, it should be ON
                    is_annotation_on(i) = 1;
                elseif ~isempty(n.is_annotation_on) && ~isnan(n.is_annotation_on)
                    is_annotation_on(i) = double(n.is_annotation_on); % Convert to double
                else
                    is_annotation_on(i) = 1; % Default to ON instead of OFF
                end
                
                if isempty(n.is_emphasized)
                    is_emphasized(i) = false;
                else
                    is_emphasized(i) = logical(n.is_emphasized);
                end
                
                % Auto ID data
                if isempty(n.deterministic_id)
                    deterministic_ids{i} = '';
                else
                    deterministic_ids{i} = char(string(n.deterministic_id));
                end
                
                if ~isempty(n.probabilistic_ids)
                    % Convert cell array of IDs to a JSON-like string for storage
                    id_strings = cell(length(n.probabilistic_ids), 1);
                    for j = 1:length(n.probabilistic_ids)
                        id_strings{j} = char(string(n.probabilistic_ids{j}));
                    end
                    probabilistic_ids_str{i} = strjoin(id_strings, '|'); % Use | as separator
                else
                    probabilistic_ids_str{i} = '';
                end
                if ~isempty(n.probabilistic_probs)
                    num_prob_probs = min(length(n.probabilistic_probs), 7);
                    probabilistic_probs(i, 1:num_prob_probs) = n.probabilistic_probs(1:num_prob_probs);
                end
                % Handle rank - ensure it's a scalar
                if ~isempty(n.rank)
                    if isscalar(n.rank)
                        ranks(i) = n.rank;
                    else
                        ranks(i) = n.rank(1); % Take first element if it's an array
                    end
                else
                    ranks(i) = 0; % Default value
                end
                
                % Neuron properties - add safety checks
                if ~isempty(n.position) && length(n.position) >= 3
                    positions(i, :) = n.position(1:3);
                else
                    positions(i, :) = [0, 0, 0]; % Default position
                end
                
                if ~isempty(n.color) && length(n.color) >= 4
                    colors(i, :) = n.color(1:4);
                else
                    colors(i, :) = [0, 0, 0, 0]; % Default color
                end
                
                if ~isempty(n.color_readout) && length(n.color_readout) >= 4
                    color_readouts(i, :) = n.color_readout(1:4);
                else
                    color_readouts(i, :) = [0, 0, 0, 0]; % Default readout
                end
                
                if ~isempty(n.baseline) && length(n.baseline) >= 4
                    baselines(i, :) = n.baseline(1:4);
                else
                    baselines(i, :) = [0, 0, 0, 0]; % Default baseline
                end
                
                if ~isempty(n.covariance) && size(n.covariance, 1) == 3 && size(n.covariance, 2) == 3
                    covariances(:, :, i) = n.covariance;
                else
                    % Create default identity matrix if covariance is empty or wrong size
                    covariances(:, :, i) = eye(3);
                end
                if ~isempty(n.aligned_xyzRGB) && length(n.aligned_xyzRGB) >= 6
                    aligned_xyzRGBs(i, :) = n.aligned_xyzRGB(1:6);
                end
            end
            
            % Create NWB data structures for neuron annotations
            fprintf('DEBUG: Creating DynamicTable with data types:\n');
            fprintf('  annotations: %s (length: %d)\n', class(annotations), length(annotations));
            fprintf('  annotation_confidences: %s (size: %s)\n', class(annotation_confidences), mat2str(size(annotation_confidences)));
            fprintf('  is_annotation_on: %s (size: %s)\n', class(is_annotation_on), mat2str(size(is_annotation_on)));
            fprintf('  is_emphasized: %s (size: %s)\n', class(is_emphasized), mat2str(size(is_emphasized)));
            fprintf('  deterministic_ids: %s (length: %d)\n', class(deterministic_ids), length(deterministic_ids));
            fprintf('  probabilistic_ids_str: %s (length: %d)\n', class(probabilistic_ids_str), length(probabilistic_ids_str));
            fprintf('  probabilistic_probs: %s (size: %s)\n', class(probabilistic_probs), mat2str(size(probabilistic_probs)));
            fprintf('  ranks: %s (size: %s)\n', class(ranks), mat2str(size(ranks)));
            
            % Check first few elements of cell arrays
            if ~isempty(annotations)
                fprintf('  First annotation: "%s" (class: %s)\n', annotations{1}, class(annotations{1}));
            end
            if ~isempty(deterministic_ids)
                fprintf('  First deterministic_id: "%s" (class: %s)\n', deterministic_ids{1}, class(deterministic_ids{1}));
            end
            if ~isempty(probabilistic_ids_str)
                fprintf('  First probabilistic_ids_str: "%s" (class: %s)\n', probabilistic_ids_str{1}, class(probabilistic_ids_str{1}));
            end
            
            % Debug: Check annotation status after processing
            fprintf('DEBUG: Annotation status summary:\n');
            fprintf('  Neurons set to ON: %d\n', sum(is_annotation_on == 1));
            fprintf('  Neurons set to OFF: %d\n', sum(is_annotation_on == 0));
            fprintf('  Neurons with annotations: %d\n', sum(~cellfun(@isempty, annotations) & ~strcmp(annotations, '')));
            
            % Debug covariance data before reshaping
            fprintf('DEBUG: Covariances before reshaping: %s\n', mat2str(size(covariances)));
            if ~any(isnan(covariances(:)))
                fprintf('  Covariances contain valid data\n');
            else
                fprintf('  WARNING: Covariances contain NaN values!\n');
                fprintf('  Non-NaN count: %d out of %d\n', sum(~isnan(covariances(:))), numel(covariances));
            end
            
            % Reshape for storage: [3,3,N] -> [N,9] 
            covariances_for_storage = reshape(permute(covariances, [3, 1, 2]), [num_neurons, 9]);
            fprintf('DEBUG: Covariances after reshaping for storage: %s\n', mat2str(size(covariances_for_storage)));
            
            annotations_table = types.hdmf_common.DynamicTable( ...
                'description', 'Neuron annotation data including user IDs and auto IDs', ...
                'colnames', {'user_annotation', 'annotation_confidence', 'is_annotation_on', 'is_emphasized', ...
                           'deterministic_id', 'probabilistic_ids', 'probabilistic_probs', 'rank'}, ...
                'user_annotation', types.hdmf_common.VectorData('description', 'User neuron annotations', 'data', annotations), ...
                'annotation_confidence', types.hdmf_common.VectorData('description', 'User confidence in annotations', 'data', annotation_confidences), ...
                'is_annotation_on', types.hdmf_common.VectorData('description', 'Whether neuron annotation is ON/OFF', 'data', is_annotation_on), ...
                'is_emphasized', types.hdmf_common.VectorData('description', 'Whether neuron is emphasized (e.g., for mutations)', 'data', is_emphasized), ...
                'deterministic_id', types.hdmf_common.VectorData('description', 'Deterministic neuron IDs from auto-ID', 'data', deterministic_ids), ...
                'probabilistic_ids', types.hdmf_common.VectorData('description', 'Probabilistic neuron IDs from auto-ID (pipe-separated)', 'data', probabilistic_ids_str), ...
                'probabilistic_probs', types.hdmf_common.VectorData('description', 'Probabilities for probabilistic IDs', 'data', probabilistic_probs), ...
                'rank', types.hdmf_common.VectorData('description', 'Neuron ranking based on auto-ID confidence', 'data', ranks), ...
                'id', types.hdmf_common.ElementIdentifiers('data', 0:num_neurons-1));
            
            % Create neuron properties table
            properties_table = types.hdmf_common.DynamicTable( ...
                'description', 'Neuron physical properties and measurements', ...
                'colnames', {'positions', 'colors', 'color_readouts', 'baselines', 'covariances', 'aligned_xyzRGB'}, ...
                'positions', types.hdmf_common.VectorData('description', 'Neuron 3D positions (x,y,z)', 'data', positions), ...
                'colors', types.hdmf_common.VectorData('description', 'Neuron RGBW colors', 'data', colors), ...
                'color_readouts', types.hdmf_common.VectorData('description', 'Neuron color readouts', 'data', color_readouts), ...
                'baselines', types.hdmf_common.VectorData('description', 'Neuron baseline values', 'data', baselines), ...
                'covariances', types.hdmf_common.VectorData('description', 'Neuron covariance matrices (Nx9 format: each row is a flattened 3x3 matrix)', 'data', covariances_for_storage), ...
                'aligned_xyzRGB', types.hdmf_common.VectorData('description', 'Aligned neuron positions and colors', 'data', aligned_xyzRGBs), ...
                'id', types.hdmf_common.ElementIdentifiers('data', 0:num_neurons-1));
            
            % Create processing module to hold both tables
            annotations_module = types.core.ProcessingModule( ...
                'description', 'Neuron annotations and properties data');
            annotations_module.dynamictable.set('NeuronAnnotations', annotations_table);
            annotations_module.dynamictable.set('NeuronProperties', properties_table);
            
            % Add atlas version if available
            if isfield(neurons, 'atlas_version') && ~isempty(neurons.atlas_version)
                atlas_info = types.hdmf_common.VectorData( ...
                    'description', 'Atlas version information', ...
                    'data', neurons.atlas_version);
                annotations_module.nwbdatainterface.set('AtlasVersion', atlas_info);
            end
        end
        
        function detection_module = create_detection_params(ctx)
            %CREATE_DETECTION_PARAMS Create detection parameters data structure for NWB file
            %
            % This function creates a data structure containing neuron detection parameters
            % that were previously stored in the companion ID file as mp_params.
            
            % Get current app instance to access detection parameters
            app = Program.app;
            
            % Get mp_params (matching pursuit parameters)
            if isfield(app, 'mp_params') && ~isempty(app.mp_params)
                mp_params = app.mp_params;
            else
                % Create default mp_params if not available
                mp_params = struct();
                mp_params.hnsz = [7, 7, 3]; % Default half neighborhood size
                mp_params.k = 0; % Will be set to actual neuron count
                mp_params.exclusion_radius = 1.5;
                mp_params.min_eig_thresh = 0.1;
            end
            
            % Update k parameter to reflect current neuron count
            if isfield(ctx.neurons, 'image_neurons') && ~isempty(ctx.neurons.image_neurons) && ~isempty(ctx.neurons.image_neurons.neurons)
                mp_params.k = length(ctx.neurons.image_neurons.neurons);
            end
            
            % Create parameter data structures
            param_names = fieldnames(mp_params);
            param_descriptions = containers.Map();
            param_descriptions('hnsz') = 'Half neighborhood size for neuron detection [x,y,z]';
            param_descriptions('k') = 'Number of detected neurons';
            param_descriptions('exclusion_radius') = 'Exclusion radius for nearby neuron removal';
            param_descriptions('min_eig_thresh') = 'Minimum eigenvalue threshold for detection';
            
            % Convert parameters to a format suitable for NWB
            param_data = cell(length(param_names), 1);
            param_desc = cell(length(param_names), 1);
            
            fprintf('DEBUG: Detection parameters data types:\n');
            
            for i = 1:length(param_names)
                param_name = param_names{i};
                param_value = mp_params.(param_name);
                
                % Convert to string representation for storage
                if isnumeric(param_value)
                    if length(param_value) > 1
                        param_data{i} = char(mat2str(param_value));
                    else
                        param_data{i} = char(num2str(param_value));
                    end
                else
                    param_data{i} = char(string(param_value));
                end
                
                if param_descriptions.isKey(param_name)
                    param_desc{i} = char(param_descriptions(param_name));
                else
                    param_desc{i} = char(sprintf('Detection parameter: %s', param_name));
                end
                
                fprintf('  %s: "%s" (type: %s)\n', param_name, param_data{i}, class(param_data{i}));
            end
            
            % Ensure param_names are also character arrays
            param_names_char = cellfun(@char, param_names, 'UniformOutput', false);
            
            fprintf('  param_names_char: %s (length: %d)\n', class(param_names_char), length(param_names_char));
            fprintf('  param_data: %s (length: %d)\n', class(param_data), length(param_data));
            fprintf('  param_desc: %s (length: %d)\n', class(param_desc), length(param_desc));
            
            % Create detection parameters table
            detection_table = types.hdmf_common.DynamicTable( ...
                'description', 'Neuron detection and matching pursuit parameters', ...
                'colnames', {'parameter_name', 'parameter_value', 'parameter_description'}, ...
                'parameter_name', types.hdmf_common.VectorData('description', 'Detection parameter names', 'data', param_names_char), ...
                'parameter_value', types.hdmf_common.VectorData('description', 'Detection parameter values', 'data', param_data), ...
                'parameter_description', types.hdmf_common.VectorData('description', 'Description of detection parameters', 'data', param_desc), ...
                'id', types.hdmf_common.ElementIdentifiers('data', 0:length(param_names_char)-1));
            
            % Add program version information
            version = Program.ProgramInfo.version;
            version_char = char(string(version)); % Ensure it's a character array
            version_table = types.hdmf_common.DynamicTable( ...
                'description', 'NeuroPAL_ID software version information', ...
                'colnames', {'software_version'}, ...
                'software_version', types.hdmf_common.VectorData('description', 'NeuroPAL_ID software version', 'data', {version_char}), ...
                'id', types.hdmf_common.ElementIdentifiers('data', 0));
            
            % Create processing module to hold detection parameters
            detection_module = types.core.ProcessingModule( ...
                'description', 'Neuron detection parameters and software version');
            detection_module.dynamictable.set('DetectionParameters', detection_table);
            detection_module.dynamictable.set('SoftwareVersion', version_table);
        end
    end
end