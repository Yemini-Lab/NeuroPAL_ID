classdef NeuroPALImage
    %NEUROPALIMAGE Convert various image formats to a NeuroPAL format.
    %
    %   NeuroPAL files contain 4 variable:
    %      data = the image data (x,y,z,c)
    %      info = the image information
    %           scale = pixel scale in microns (x,y,z)
    %           RGBW = the (R,G,B,W) color channel indices (nan = no data)
    %           GFP = the GFP color channel index(s) (can be empty)
    %           DIC = the DIC channel index (can be empty)
    %           gamma = the gamma correction for the image
    %      prefs = the user preferences
    %           RGBW = the (R,G,B,W) color channel indices (nan = no data)
    %           GFP = the GFP color channel index(s) (can be empty)
    %           DIC = the DIC channel index (can be empty)
    %           gamma = the gamma correction for the image
    %           rotate.horizontal = rotate horizontal?
    %           rotate.vertical = rotate vertical?
    %      worm = the worm information
    %           body = 'Whole Worm', 'Head', 'Midbody', 'Anterior Midbody'.
    %                  'Central Midbody', 'Posterior Midbody', or 'Tail'
    %           age = 'Adult', 'L4', L3', 'L2, 'L1', or '3-Fold'
    %           sex = 'XX' or 'XO'
    %           strain = strain name
    %           notes = experimental notes
    %      mp = matching pursuit (neuron detection) parameters
    %      neurons = the neurons in the image
    
    
    %% Public methods.
    methods (Static)
        function [data, info, prefs, worm, mp, neurons, np_file, id_file] = open(file)
            %OPEN Open an image in NeuroPAL format.
            %
            % Input:
            %   file = the NeuroPAL format filename
            %
            % Output:
            %   data = the image data
            %   info = the image information
            %   prefs = the user preferences
            %   worm = the worm information
            %   mp = matching pursuit (neuron detection) parameters
            %   neurons = the neurons in the image
            %	np_file = the NeuroPAL image file
            %	id_file = the NeuroPAL ID file

            % Initialize the packages.
            import DataHandling.*;

            % Is the user accidentally trying to open the ID file?
            id_file_ext = '_ID.mat';
            if endsWith(file, id_file_ext)
                file = strrep(file, id_file_ext, '.mat');
            end
            
            % Get the file extension.
            [~, ~, ext] = fileparts(file);
            if isempty(ext)
                error('Unknown image format: "%s"', file);
            end
            ext = lower(ext);
            
            % Determine the NeuroPAL filename.
            np_file = strrep(file, ext, '.mat');
            
            % Is the file already in NeuroPAL format?
            if ~exist(np_file,'file')
                Program.Handlers.dialogue.add_task(sprintf('Converting %s file to NeuroPAL_ID file...', ext));
                switch lower(ext)
                    case '.mat' % NeuroPAL format
                        error('File not found: "%s"', file);
                    case '.czi' % Zeiss format
                        NeuroPALImage.convertCZI(file);
                    case '.nd2' % Nikon format
                        DataHandling.Helpers.nd2.to_npal(file);
                        % NeuroPALImage.convertND2(file);
                    case {'.lif'} % Leica format
                        NeuroPALImage.convertAny(file);
                    case {'.ims'} % Imaris format
                        NeuroPALImage.convertAny(file);
                    case {'.tif','.tiff'} % TIFF format
                        NeuroPALImage.convertAny(file);
                    case {'.h5'} % Vlab format
                        NeuroPALImage.convertAny(file);   
                    case {'.nwb'} % NWB  format
                        NeuroPALImage.convertNWB(file);
                    otherwise % Unknown format
                        error('Unknown image format: "%s"', file);
                end
                Program.Handlers.dialogue.resolve();
            end
            
            % Did we manage to convert the file?
            if ~exist(np_file,'file')
                error('Cannot read/convert: "%"', np_file);
            end
            
            % Load the file.
            [data, info, prefs, worm, mp, neurons, id_file] = ...
                NeuroPALImage.loadNP(np_file);

            Program.Validation.fill_channels(data);
        end

    end
    
    
    %% Private variables.
    properties (Constant, Access = private)

        % Default gamma values.
        gamma_default = 0.8;
        CZI_gamma_default = 0.5;
    end
    
    
    %% Private methods.
    methods (Static, Access = private)
        
        function [data, info, prefs, worm, mp, neurons, id_file] = loadNP(image_file)
            %LOADNP Load an image in NeuroPAL format.
            %
            % Input:
            %   image_file = the NeuroPAL image filename
            %
            % Output:
            %   id_file = the NeuroPAL ID filename
            %   data = the image data
            %   info = the image information
            %   prefs = the user preferences
            %   worm = the worm information
            %   mp = matching pursuit (neuron detection) parameters
            %   neurons = the neurons in the image
            
            % Initialize the packages.
            import Program.*;
            import DataHandling.*;

            Program.Handlers.dialogue.step('Loading NeuroPAL_ID file...');
            
            % Open the image file.
            np_data = load(image_file);
            if ~isfield(np_data, 'data') || ...
                    ~isfield(np_data, 'info') || ...
                    ~isfield(np_data, 'prefs')
                error('Misformatted NeuroPAL file: "%s"', image_file);
            end
            
            % Setup the image file contents.
            data = np_data.data;
            info = np_data.info;
            prefs = np_data.prefs;
            worm = [];
            if isfield(np_data, 'worm')
                worm = np_data.worm;
            end
            
            % Get the image file version.
            version = 0;
            if isfield(np_data, 'version')
                version = np_data.version;
            end
            
            % Check the image file version.
            if version < 1
                
                % Correct the worm info.
                worm.body = prefs.body_part;
                worm.age = 'Adult';
                worm.sex = 'XX';
                worm.strain = '';
                worm.notes = '';
                prefs = rmfield(prefs, 'body_part');
                
                % Update the file version.
                version = ProgramInfo.version;
                save(image_file, 'version', 'prefs', 'worm', '-append', '-v7.3');
            end
            
            % Open the ID file or try to load neuron data from associated NWB file.
            version = 0;
            mp = [];
            mp.hnsz = round(round(3./info.scale')/2)*2+1;
            if size(mp.hnsz,1) > 1
                mp.hnsz = mp.hnsz';
            end
            mp.k = 0;
            mp.exclusion_radius = 1.5;
            mp.min_eig_thresh = 0.1;
            sp = [];
            neurons = [];
            id_file = strrep(image_file, '.mat', '_ID.mat');
            
            % First, try to load from NWB file if it exists and companion ID file doesn't
            nwb_file = strrep(image_file, '.mat', '.nwb');
            if exist(nwb_file, 'file') && ~exist(id_file, 'file')
                try
                    fprintf('Attempting to load neuron data from NWB file: %s\n', nwb_file);
                    nwb_data = nwbRead(nwb_file);
                    [neurons_from_nwb, mp_from_nwb] = DataHandling.NeuroPALImage.loadNeuronDataFromNWB(nwb_data, worm.body, info.scale);
                    
                    if ~isempty(neurons_from_nwb) || ~isempty(mp_from_nwb)
                        if ~isempty(neurons_from_nwb)
                            neurons = neurons_from_nwb;
                        end
                        if ~isempty(mp_from_nwb)
                            mp = mp_from_nwb;
                        end
                        version = ProgramInfo.version;
                        fprintf('Successfully loaded neuron data from NWB file\n');
                    end
                catch ME
                    warning('Failed to load neuron data from NWB file: %s', ME.message);
                end
            end
            
            % If we didn't get data from NWB, try the traditional ID file approach
            if isempty(neurons) && exist(id_file, 'file')
                
                % Load the neurons file.
                id_data = load(id_file);
                
                % Get the ID file version.
                if isfield(id_data, 'version')
                    version = id_data.version;
                end
                
                % Setup the file contents.
                mp = id_data.mp_params;

                % Check the ID file version.
                % Version > 1.
                if version > 1
                    neurons = id_data.neurons;
                    
                % Version 1.
                elseif version == 1
                    
                    % Create the neurons.
                    sp = id_data.sp;
                    neurons = Neurons.Image(sp, worm.body, 'scale', info.scale);
                    
                    % Update the file version.
                    version = ProgramInfo.version;
                    mp_params = mp;
                    save(id_file, 'version', 'neurons', 'mp_params', '-v7.3');
                
                % No version.
                elseif version < 1
                    
                    % Are there any neurons?
                    sp = id_data.sp;
                    if ~isempty(sp)
                        
                        % Correct the neuron colors.
                        if ~isfield(sp, 'color_readout')
                            
                            % Set the neuron patch size.
                            patch_hsize = [3,3,0];
                            
                            % Compute the data.
                            data_RGBW = double(data(:,:,:,prefs.RGBW));
                            data_zscored = ...
                                Methods.Preprocess.zscore_frame(double(data_RGBW));
                            
                            % Read the patch colors.
                            num_neurons = size(sp.color,1);
                            sp.color_readout = nan(num_neurons,4);
                            for i = 1:num_neurons
                                patch = Methods.Utils.subcube(data_zscored, ...
                                    round(sp.mean(i,:)), patch_hsize);
                                sp.color_readout(i,:) = ...
                                    nanmedian(reshape(patch, ...
                                    [numel(patch)/size(patch, 4), size(patch, 4)]));
                            end
                        end
                        
                        % Clean up the old sp fields.
                        if isfield(sp, 'mean')
                            sp.positions = sp.mean;
                            sp.covariances = sp.cov;
                            sp = rmfield(sp, {'mean', 'cov'});
                        end
                    end
                    
                    % Create the neurons.
                    neurons = Neurons.Image(sp, worm.body, 'scale', info.scale);
                    
                    % Clean up the old mp fields.
                    if ~isfield(mp, 'exclusion_radius')
                        old_mp = mp;
                        mp  = [];
                        mp.hnsz = old_mp.hnsz;
                        mp.k = old_mp.k;
                        mp.exclusion_radius = 1.5;
                        mp.min_eig_thresh = 0.1;
                    end
                    mp_params = mp;
                    
                    % Update the file version.
                    version = ProgramInfo.version;
                    save(id_file, 'version', 'neurons', 'mp_params', '-v7.3');
                end
            end
        end

        function np_file = convertCZI(czi_file)
            %CONVERTCZI Convert a CZI file to NeuroPAL format.
            %
            % czi_file = the CZI file to convert
            % np_file = the NeuroPAL format file
            
            % Initialize the packages.
            import Program.*;
            import DataHandling.*;
            
            % Open the file.
            np_file = [];
            [image_data, ~] = DataHandling.imreadCZI(czi_file);
            data = image_data.data;
            
            % Fix the image orientation and scale.
            % Note: image dimensions are different than matrix dimensions
            % images = (height, width, depth) and matrices = (x,y,z). To
            % convert between the two, we need to switch dimensions 1 and 2.
            data_order = 1:ndims(data);
            data_order(1) = 2;
            data_order(2) = 1;
            data = permute(data, data_order);
            image_data.scale(1) = image_data.scale(2);
            image_data.scale(2) = image_data.scale(2);
            
            % Setup the NP file data.
            info.file = czi_file;
            info.scale = image_data.scale * 1000000; % convert to microns
            info.DIC = image_data.dicChannel;
            
            % Determine the color channels.
            colors = image_data.colors;
            colors = round(colors/max(colors(:)));
            info.RGBW = nan(4,1);
            info.GFP = nan;
            for i = 1:size(colors,1)
                switch char(colors(i,:))
                    case [1,0,0] % red
                        info.RGBW(1) = i;
                    case [0,1,0] % green
                        info.RGBW(2) = i;
                    case [0,0,1] % blue
                        info.RGBW(3) = i;
                    case [1,1,1] % white
                        if i ~= info.DIC
                            info.RGBW(4) = i;
                        end
                    otherwise % GFP
                        info.GFP = i;
                end
            end
            
            % Did we find the GFP channel?
            if isnan(info.GFP) && size(colors,1) > 4
                
                % Assume the first unused channel is GFP.
                unused = setdiff(1:size(colors,1), info.RGBW);
                info.GFP = unused(1);
            end
            
            % Determine the gamma.
            %info.gamma = 1;
            %keys = lower(meta_data.keys);
            %gamma_i = find(contains(keys, 'gamma'),1);
            %if ~isempty(gamma_i)
            %    info.gamma = str2double(meta_data.values(gamma_i));
            %end
            info.gamma = DataHandling.NeuroPALImage.CZI_gamma_default;
            
            % Initialize the user preferences.
            prefs.RGBW = info.RGBW;
            prefs.DIC = info.DIC;
            prefs.GFP = info.GFP;
            prefs.gamma = info.gamma;
            prefs.rotate.horizontal = false;
            prefs.rotate.vertical = false;
            prefs.z_center = ceil(size(data,3) / 2);
            prefs.is_Z_LR = true;
            prefs.is_Z_flip = true;
            
            % Initialize the worm info.
            worm.body = 'Head';
            worm.age = 'Adult';
            worm.sex = 'XX';
            worm.strain = '';
            worm.notes = '';
                
            % Save the CZI file to our MAT file format.
            np_file = strrep(czi_file, 'czi', 'mat');
            version = ProgramInfo.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');
        end
        
        function np_file = convertND2(nd2_file)
            %CONVERTND2 Convert an ND2 file to NeuroPAL format.
            %
            % nd2_file = the ND2 file to convert
            % np_file = the NeuroPAL format file

            np_file = DataHandling.Helpers.nd2.convert_to( ...
                'npal', nd2_file);
        end

        function np_file = convertNWB(nwb_file)
            %CONVERTNWB Convert an NWB file to NeuroPAL format.
            %
            % nwb_file = the NWB file to convert
            % np_file = the NeuroPAL format file
            
            % Initialize the packages.
            import Program.*;
            import DataHandling.*;
            
            % Open the file.
            np_file = [];
            image_data = nwbRead(nwb_file);
            data = image_data.acquisition.get('NeuroPALImageRaw').data.load();
        
            data_order = 1:ndims(data);

            if size(data, 4) ~= min(size(data))
                data_order(1) = 3;
                data_order(2) = 4;
                data_order(3) = 2;
                data_order(4) = 1;
                %data_order(1) = 2;
                %data_order(2) = 1;
                data = permute(data, data_order);
            end
            
            %image_data.scale(1) = image_data.scale(2);
            %image_data.scale(2) = image_data.scale(2);
                    
            % Setup the NP file data.
            info.file = nwb_file;
            
            if strcmp(class(image_data.acquisition.get('NeuroPALImageRaw').imaging_volume), 'types.untyped.SoftLink')
                imagingVolume = image_data.acquisition.get('NeuroPALImageRaw').imaging_volume.deref(image_data);
            else
                imagingVolume = image_data.acquisition.get('NeuroPALImageRaw').imaging_volume;
            end

            grid_spacing_data = imagingVolume.grid_spacing.load();
            info.scale = grid_spacing_data;
            info.DIC = nan;
                    
            % Determine the color channels.
            %colors = image_data.colors;
            %colors = round(colors/max(colors(:)));
            npalraw = image_data.acquisition.get('NeuroPALImageRaw');
            rgbw = npalraw.RGBW_channels.load();

            if min(rgbw) <= 0
                info.RGBW = rgbw+1;
            else
                info.RGBW = rgbw;
            end

            if size(data, 4) < size(info.RGBW(~isnan(info.RGBW)), 1)
                info.RGBW = info.RGBW(1:size(data, 4));
            end

            info.GFP = nan;

            if any(ismember(image_data.processing.keys, 'NeuroPAL'))
                if any(ismember(image_data.processing.get('NeuroPAL').dynamictable.keys, 'NeuroPAL_ID'))
                    gammas = image_data.processing.get('NeuroPAL').dynamictable.get('NeuroPAL_ID').vectordata.get('gammas').data.load();
                    info.gamma = gammas';
                else
                    info.gamma = NeuroPALImage.gamma_default;
                end
            else
                info.gamma = NeuroPALImage.gamma_default;
            end

            % Did we find the GFP channel?
            if isnan(info.GFP) && size(data,4) > 4
                % Assume the first unused channel is GFP.
                unused = setdiff(1:size(data,4), info.RGBW);
                info.GFP = unused(1);
            end

            % Initialize the worm info.
            valid_locations = {'Whole Worm', 'Head', 'Midbody', 'Anterior Midbody', 'Central Midbody', 'Posterior Midbody', 'Tail'};
            nwb_loc = lower(imagingVolume.location);
            for j = 1:length(valid_locations)
                list_str = lower(valid_locations{j});
                if contains(list_str, nwb_loc)
                    worm.body = valid_locations{j};
                    break;
                end
            end

            valid_ages = {'Adult', 'L4', 'L3', 'L2', 'L1'};
            if ~any(strcmp(valid_ages, image_data.general_subject.growth_stage))
                worm.age = 'Adult';
            else
                worm.age = image_data.general_subject.growth_stage;
            end

            valid_sexes = {'XX', 'XO'}; % Isn't Massachusetts supposed to be deep blue?
            if ~any(strcmp(valid_sexes, image_data.general_subject.sex))
                male_syns = {'M','Male', 'm', 'male'};
                if ~any(strcmp(male_syns, image_data.general_subject.sex))
                    worm.sex = 'XX';
                else
                    worm.sex = 'XO';
                end
            else
                worm.sex = image_data.general_subject.sex;
            end

            worm.strain = image_data.general_subject.strain;

            if strcmp(class(image_data.general_subject.description), 'types.untyped.DataStub')
                worm.notes = image_data.general_subject.description.load();
            else
                worm.notes = image_data.general_subject.description;
            end

            % Initialize the user preferences.
            prefs.RGBW = info.RGBW;
            prefs.DIC = info.DIC;
            prefs.GFP = info.GFP;
            prefs.gamma = info.gamma;
            prefs.rotate.horizontal = false;
            prefs.rotate.vertical = false;
            prefs.z_center = ceil(size(data,3) / 2);
            prefs.is_Z_LR = true;
            prefs.is_Z_flip = true;

            % Save the NWB file to our MAT file format.
            np_file = strrep(nwb_file, '.nwb', '.mat');
            version = ProgramInfo.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');
            
            % Try to load neuron data and detection parameters from NWB file
            [neurons, mp_params] = DataHandling.NeuroPALImage.loadNeuronDataFromNWB(image_data, worm.body, info.scale);
            
            % Note: Neuron data is now stored directly in NWB file - no companion ID file created
        end
        
        function [neurons, mp_params] = loadNeuronDataFromNWB(nwb_data, body_part, scale)
            %LOADNEURONDATAFROMNWB Load neuron annotations and detection parameters from NWB file
            %
            % This function extracts neuron data that was previously stored in companion ID files
            % but is now embedded within the NWB file using the ndx-multichannel-volume extension.
            %
            % Input:
            %   nwb_data = NWB file object loaded with nwbRead
            %   body_part = worm body part ('Head', 'Tail', etc.)
            %   scale = image scale for neuron creation
            %
            % Output:
            %   neurons = Neurons.Image object with loaded neuron data
            %   mp_params = detection parameters structure
            
            neurons = [];
            mp_params = [];
            
            try
                % Check if neuron annotation data exists in the NWB file
                if ~any(ismember(nwb_data.processing.keys, 'NeuronAnnotations'))
                    fprintf('No NeuronAnnotations processing module found in NWB file\n');
                    return;
                end
                
                neuron_module = nwb_data.processing.get('NeuronAnnotations');
                fprintf('Found NeuronAnnotations processing module\n');
                
                % Load neuron annotations table
                if any(ismember(neuron_module.dynamictable.keys, 'NeuronAnnotations'))
                    annotations_table = neuron_module.dynamictable.get('NeuronAnnotations');
                    
                    % Extract annotation data
                    user_annotations = annotations_table.vectordata.get('user_annotation').data.load();
                    annotation_confidences = annotations_table.vectordata.get('annotation_confidence').data.load();
                    is_annotation_on = annotations_table.vectordata.get('is_annotation_on').data.load();
                    is_emphasized = annotations_table.vectordata.get('is_emphasized').data.load();
                    deterministic_ids = annotations_table.vectordata.get('deterministic_id').data.load();
                    probabilistic_ids_str = annotations_table.vectordata.get('probabilistic_ids').data.load();
                    probabilistic_probs = annotations_table.vectordata.get('probabilistic_probs').data.load();
                    ranks = annotations_table.vectordata.get('rank').data.load();
                    
                    % Convert pipe-separated probabilistic IDs back to matrix format
                    % (The Neuron constructor expects probabilistic_ids as a matrix where each row is a neuron)
                    fprintf('DEBUG: Converting %d probabilistic ID strings to matrix format...\n', length(probabilistic_ids_str));
                    
                    % First, convert strings to cell arrays
                    prob_id_cells = cell(length(probabilistic_ids_str), 1);
                    max_ids = 0;
                    for i = 1:length(probabilistic_ids_str)
                        if ~isempty(probabilistic_ids_str{i})
                            split_ids = split(probabilistic_ids_str{i}, '|');
                            % Ensure each ID is a character vector, not string
                            prob_id_cells{i} = cellfun(@char, split_ids, 'UniformOutput', false);
                            max_ids = max(max_ids, length(prob_id_cells{i}));
                            if i == 1
                                fprintf('DEBUG: First prob IDs: %s -> %s\n', probabilistic_ids_str{i}, strjoin(prob_id_cells{i}, ', '));
                                fprintf('DEBUG: First ID type: %s\n', class(prob_id_cells{i}{1}));
                            end
                        else
                            prob_id_cells{i} = {};
                        end
                    end
                    
                    % Convert to matrix format (pad with empty strings)
                    if max_ids > 0
                        probabilistic_ids = cell(length(probabilistic_ids_str), max_ids);
                        for i = 1:length(probabilistic_ids_str)
                            for j = 1:length(prob_id_cells{i})
                                probabilistic_ids{i, j} = prob_id_cells{i}{j};
                            end
                            % Fill remaining columns with empty strings
                            for j = (length(prob_id_cells{i}) + 1):max_ids
                                probabilistic_ids{i, j} = '';
                            end
                        end
                        fprintf('DEBUG: Created probabilistic_ids matrix of size %dx%d\n', size(probabilistic_ids, 1), size(probabilistic_ids, 2));
                    else
                        probabilistic_ids = {};
                    end
                    
                    num_neurons = length(user_annotations);
                    fprintf('Found %d neurons in annotations table\n', num_neurons);
                    
                    % Debug: Check the annotation status values
                    fprintf('DEBUG: Sample is_annotation_on values: [%g, %g, %g, %g, %g]\n', ...
                        is_annotation_on(1), is_annotation_on(2), is_annotation_on(3), is_annotation_on(4), is_annotation_on(5));
                    fprintf('DEBUG: Unique is_annotation_on values: %s\n', mat2str(unique(is_annotation_on)));
                else
                    fprintf('No NeuronAnnotations table found in processing module\n');
                    return;
                end
                
                % Load neuron properties table
                if any(ismember(neuron_module.dynamictable.keys, 'NeuronProperties'))
                    properties_table = neuron_module.dynamictable.get('NeuronProperties');
                    
                    % Extract property data
                    positions = properties_table.vectordata.get('positions').data.load();
                    colors = properties_table.vectordata.get('colors').data.load();
                    color_readouts = properties_table.vectordata.get('color_readouts').data.load();
                    baselines = properties_table.vectordata.get('baselines').data.load();
                    covariances_flat = properties_table.vectordata.get('covariances').data.load();
                    aligned_xyzRGBs = properties_table.vectordata.get('aligned_xyzRGB').data.load();
                    
                    fprintf('DEBUG: Loaded property data shapes:\n');
                    fprintf('  positions: %s\n', mat2str(size(positions)));
                    fprintf('  colors: %s\n', mat2str(size(colors)));
                    fprintf('  color_readouts: %s\n', mat2str(size(color_readouts)));
                    fprintf('  baselines: %s\n', mat2str(size(baselines)));
                    fprintf('  covariances_flat: %s\n', mat2str(size(covariances_flat)));
                    fprintf('  aligned_xyzRGBs: %s\n', mat2str(size(aligned_xyzRGBs)));
                    
                    % Debug: Check actual position values
                    if ~isempty(positions) && size(positions, 1) >= 3
                        fprintf('DEBUG: Sample position values:\n');
                        for debug_i = 1:min(3, size(positions, 1))
                            fprintf('  Neuron %d positions: [%.3f, %.3f, %.3f]\n', debug_i, ...
                                positions(debug_i, 1), positions(debug_i, 2), positions(debug_i, 3));
                        end
                        fprintf('  Position data type: %s\n', class(positions));
                        fprintf('  Position range: X=[%.3f, %.3f], Y=[%.3f, %.3f], Z=[%.3f, %.3f]\n', ...
                            min(positions(:,1)), max(positions(:,1)), ...
                            min(positions(:,2)), max(positions(:,2)), ...
                            min(positions(:,3)), max(positions(:,3)));
                    end
                    
                    % Reshape covariances from flat format back to 3x3xN
                    % The data was stored as reshape(permute(covariances, [3, 1, 2]), [num_neurons, 9])
                    % So we need to reshape back and permute to get [3, 3, N] format expected by Neurons.Neuron.unmarshall
                    if size(covariances_flat, 2) == 9 && size(covariances_flat, 1) == num_neurons
                        % Data is stored as [num_neurons x 9], reshape back to [num_neurons, 3, 3] then permute to [3, 3, num_neurons]
                        covariances_temp = reshape(covariances_flat, [num_neurons, 3, 3]);
                        covariances = permute(covariances_temp, [2, 3, 1]); % [3, 3, num_neurons]
                    elseif size(covariances_flat, 1) == 9 && size(covariances_flat, 2) == num_neurons
                        % Data is stored as [9 x num_neurons], transpose and reshape
                        covariances_temp = reshape(covariances_flat', [num_neurons, 3, 3]);
                        covariances = permute(covariances_temp, [2, 3, 1]); % [3, 3, num_neurons]
                    else
                        fprintf('WARNING: Unexpected covariance data shape, creating default covariances\n');
                        covariances = repmat(eye(3), [1, 1, num_neurons]);
                    end
                    
                    fprintf('DEBUG: Reshaped covariances: %s\n', mat2str(size(covariances)));
                    
                    % The Neurons.Neuron.unmarshall function expects covariances(i,:,:) to work
                    % This means we need covariances to be [num_neurons, 3, 3], not [3, 3, num_neurons]
                    covariances = permute(covariances, [3, 1, 2]); % Convert to [num_neurons, 3, 3]
                    fprintf('DEBUG: Final covariances for unmarshall: %s\n', mat2str(size(covariances)));
                    fprintf('Found neuron properties for %d neurons\n', num_neurons);
                else
                    fprintf('No NeuronProperties table found in processing module\n');
                    return;
                end
                
                % Create superpixels structure for Neurons.Image constructor
                sp = struct();
                sp.positions = positions;
                sp.color = colors;
                sp.color_readout = color_readouts;
                sp.baseline = baselines;
                sp.covariances = covariances;
                sp.aligned_xyzRGB = aligned_xyzRGBs;
                
                % Add annotation data
                sp.annotation = user_annotations;
                sp.annotation_confidence = annotation_confidences;
                sp.is_annotation_on = is_annotation_on;
                sp.is_emphasized = is_emphasized;
                
                % Add auto ID data
                sp.deterministic_id = deterministic_ids;
                sp.probabilistic_ids = probabilistic_ids;
                sp.probabilistic_probs = probabilistic_probs;
                sp.rank = ranks;
                
                % Debug the superpixels structure
                fprintf('DEBUG: Superpixels structure fields and sizes:\n');
                fields = fieldnames(sp);
                for i = 1:length(fields)
                    field = fields{i};
                    value = sp.(field);
                    if isnumeric(value)
                        fprintf('  %s: %s %s\n', field, class(value), mat2str(size(value)));
                    elseif iscell(value)
                        fprintf('  %s: %s (length: %d)\n', field, class(value), length(value));
                    else
                        fprintf('  %s: %s\n', field, class(value));
                    end
                end
                
                % Load atlas version if available
                if any(ismember(neuron_module.nwbdatainterface.keys, 'AtlasVersion'))
                    fprintf('DEBUG: Loading atlas version...\n');
                    atlas_version_data = neuron_module.nwbdatainterface.get('AtlasVersion');
                    sp.atlas_version = atlas_version_data.data.load();
                    fprintf('DEBUG: Loaded atlas version: %s\n', sp.atlas_version);
                else
                    fprintf('DEBUG: No atlas version found in NWB file\n');
                end
                
                % Create neurons object
                fprintf('DEBUG: Attempting to create Neurons.Image object...\n');
                fprintf('DEBUG: Using scale: [%.6f, %.6f, %.6f]\n', scale(1), scale(2), scale(3));
                fprintf('DEBUG: Using body_part: %s\n', body_part);
                try
                    neurons = Neurons.Image(sp, body_part, 'scale', scale);
                    fprintf('Successfully loaded %d neurons from NWB file\n', num_neurons);
                    
                    % Debug: Check the actual positions in the created neurons object
                    if ~isempty(neurons) && ~isempty(neurons.neurons) && length(neurons.neurons) >= 3
                        fprintf('DEBUG: Checking created neuron positions:\n');
                        for debug_i = 1:min(3, length(neurons.neurons))
                            pos = neurons.neurons(debug_i).position;
                            fprintf('  Created neuron %d position: [%.3f, %.3f, %.3f]\n', debug_i, pos(1), pos(2), pos(3));
                        end
                    end
                catch neuron_create_ME
                    fprintf('ERROR creating Neurons.Image: %s\n', neuron_create_ME.message);
                    fprintf('Stack trace: %s\n', getReport(neuron_create_ME));
                    
                    % Try to diagnose the covariance issue
                    fprintf('DEBUG: Investigating covariance issue...\n');
                    fprintf('  covariances size: %s\n', mat2str(size(sp.covariances)));
                    fprintf('  num_neurons: %d\n', num_neurons);
                    if size(sp.covariances, 3) ~= num_neurons
                        fprintf('  MISMATCH: covariances 3rd dimension (%d) != num_neurons (%d)\n', ...
                            size(sp.covariances, 3), num_neurons);
                        % Try to fix by creating default covariances
                        fprintf('  Creating default identity covariances...\n');
                        sp.covariances = repmat(eye(3), [1, 1, num_neurons]);
                        neurons = Neurons.Image(sp, body_part, 'scale', scale);
                        fprintf('Successfully created neurons with default covariances\n');
                    else
                        rethrow(neuron_create_ME);
                    end
                end
                
            catch ME
                warning('Could not load neuron annotation data from NWB file: %s', ME.message);
                fprintf('Stack trace: %s\n', getReport(ME));
                neurons = [];
            end
            
            try
                % Load detection parameters
                if any(ismember(nwb_data.processing.keys, 'DetectionParameters'))
                    detection_module = nwb_data.processing.get('DetectionParameters');
                    
                    if any(ismember(detection_module.dynamictable.keys, 'DetectionParameters'))
                        detection_table = detection_module.dynamictable.get('DetectionParameters');
                        
                        % Extract parameter data
                        param_names = detection_table.vectordata.get('parameter_name').data.load();
                        param_values = detection_table.vectordata.get('parameter_value').data.load();
                        
                        % Reconstruct mp_params structure
                        mp_params = struct();
                        for i = 1:length(param_names)
                            param_name = param_names{i};
                            param_value_str = param_values{i};
                            
                            % Convert string back to appropriate data type
                            if contains(param_value_str, '[') && contains(param_value_str, ']')
                                % Vector/matrix parameter
                                mp_params.(param_name) = str2num(param_value_str);
                            else
                                % Scalar parameter
                                param_value = str2double(param_value_str);
                                if ~isnan(param_value)
                                    mp_params.(param_name) = param_value;
                                else
                                    mp_params.(param_name) = param_value_str;
                                end
                            end
                        end
                        
                        fprintf('Loaded detection parameters from NWB file\n');
                    end
                end
                
            catch ME
                warning('Could not load detection parameters from NWB file: %s', ME.message);
                mp_params = [];
            end
        end
        
        function np_file = convertAny(any_file)
            %CONVERTANY Convert any file to NeuroPAL format.
            %
            % any_file = the ND2 file to convert
            % np_file = the NeuroPAL format file
            
            % Initialize the packages.
            import Program.*;
            import DataHandling.*;
            
            % Open the file.
            np_file = [];
            if strcmp(any_file(end-3:end), '.lif')
                [image_data, ~] = DataHandling.imreadLif(any_file);
            elseif strcmp(any_file(end-2:end), '.h5')
                [image_data, ~] = DataHandling.imreadVlab(any_file);
            else
                [image_data, ~] = DataHandling.imreadAny(any_file);
            end
            data = image_data.data;
            
            % Fix the image orientation and scale.
            % Note: image dimensions are different than matrix dimensions
            % images = (height, width, depth) and matrices = (x,y,z). To
            % convert between the two, we need to switch dimensions 1 and 2.
            data_order = 1:ndims(data);
            data_order(1) = 2;
            data_order(2) = 1;
            data = permute(data, data_order);
            image_data.scale(1) = image_data.scale(2);
            image_data.scale(2) = image_data.scale(2);
            
            % Setup the NP file data.
            info.file = any_file;
            info.scale = image_data.scale;
            info.DIC = image_data.dicChannel;
            
            % Determine the color channels.
            colors = image_data.colors;
            colors = round(colors/max(colors(:)));
            info.RGBW = nan(4,1);
            info.GFP = nan;
            for i = 1:size(colors,1)
                switch char(colors(i,:))
                    case [1,0,0] % red
                        info.RGBW(1) = i;
                    case [0,1,0] % green
                        info.RGBW(2) = i;
                    case [0,0,1] % blue
                        info.RGBW(3) = i;
                    case [1,1,1] % white
                        if i ~= info.DIC
                            info.RGBW(4) = i;
                        end
                    otherwise % GFP
                        info.GFP = i;
                end
            end
            
            % Did we find the GFP channel?
            if isnan(info.GFP) && size(colors,1) > 4
                
                % Assume the first unused channel is GFP.
                unused = setdiff(1:size(colors,1), info.RGBW);
                info.GFP = unused(1);
            end
            
            % Determine the gamma.
            %info.gamma = 1;
            %keys = lower(meta_data.keys);
            %gamma_i = find(contains(keys, 'gamma'),1);
            %if ~isempty(gamma_i)
            %    info.gamma = str2double(meta_data.values(gamma_i));
            %end
            info.gamma = DataHandling.NeuroPALImage.gamma_default;
            
            % Initialize the user preferences.
            prefs.RGBW = info.RGBW;
            prefs.DIC = info.DIC;
            prefs.GFP = info.GFP;
            prefs.gamma = info.gamma;
            prefs.rotate.horizontal = false;
            prefs.rotate.vertical = false;
            prefs.z_center = ceil(size(data,3) / 2);
            prefs.is_Z_LR = true;
            prefs.is_Z_flip = true;
            
            % Initialize the worm info.
            worm.body = 'Head';
            worm.age = 'Adult';
            worm.sex = 'XX';
            worm.strain = '';
            worm.notes = '';
            
            % Save the file to our MAT file format.
            suffix = strfind(any_file, '.');
            if isempty(suffix)
                suffix = length(any_file);
            end
            np_file = cat(2, any_file(1:(suffix(end) - 1)), '.mat');
            version = ProgramInfo.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');
        end
    end
end
