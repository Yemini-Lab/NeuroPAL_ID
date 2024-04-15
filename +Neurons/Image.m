classdef Image < handle
    %Image A list of neurons in a certain body part
    %   Detailed explanation goes here

    properties
        neurons = Neurons.Neuron.empty; % a list of the instances of Neuron class -> see Neuron.m
        bodypart = [] % a string consisting the name of the worm's body part - DEPRECATED,PLEASE USE "worm" INSTEAD!!!
        meta_data % key, value pairs for intermediate analysis
        scale = ones(1,3); % (x,y,z) scale
        atlas_version = []; % the atlas version used to ID the neurons
    end

    % Public methods.
    methods
        function obj = Image(superpixels, varargin)
            %Image Construct an instance of this class.
            %   superpixel: Matlab struct superpixels with variables mean, cov,
            %   color, basline, and potentially ids, rank, probabilistic
            %   ids, probabilistic probs, ... .
            %   bodypart: A string that represents which body part the
            %   current instance of this class corresponds to, examples are
            %   'head' and 'tail'.
            %   scale: image scale (x,y,z).
            %   meta_data: meta data

            % Initialize the data.
            %obj.bodypart = bodypart; DEPRECATED
            
            % Set the scale.
            if any(strcmp(varargin, 'scale'))
                obj.scale = varargin{find(strcmp(varargin, 'scale'))+1}(:)';
            end
            
            % Is there meta data?
            if any(strcmp(varargin, 'meta_data'))
                obj.meta_data= varargin{find(strcmp(varargin, 'meta_data'))+1};
            else
                obj.meta_data = containers.Map();
            end
            
            % Get the atlas version.
            if isfield(superpixels, 'atlas_version')
                obj.atlas_version = superpixels.atlas_version;
            end
            
            % Are there neurons?
            if isempty(superpixels)
                obj.neurons = Neurons.Neuron.empty;
                return;
            end

            % Unmarshall the neurons.
            for i = 1:size(superpixels.color,1)
                obj.neurons(i) = Neurons.Neuron.unmarshall(superpixels, i);
            end
        end
        
        
        %% ADD & DELETE NEURONS.
        
        function add_neuron(obj, volume, position, nsz, scale)
            %ADD_NEURON Add a neuron to the list of neurons.
            %   by running one iteration of Matching Pursuit.
            %   volume: the full z-scored image.
            %   position: the location in the neighbourhood of which the
            %   neuron should be added.
            %   nsz: the window size around the patch for the  new neuron.
            %   trunc: the truncation value of the Gaussian function used
            %   for fitting.

            try
                color = squeeze(volume(round(position(1)),round(position(2)),round(position(3)),:))';
            catch
                'test'
            end
            
            obj.scale = scale;
            if size(obj.scale,1) > size(obj.scale,2)
                obj.scale = obj.scale';
            end
            
            bpatch = Methods.Utils.subcube(volume, round(position), nsz);
            if isKey(obj.meta_data, 'auto_detect') && obj.meta_data('auto_detect')
                auto_detect = Methods.AutoDetect.instance();
                auto_detect.scale = scale;
                auto_detect.szext = size(volume);
                auto_detect.fsize = nsz;
                [~, sp] = auto_detect.fit_gaussian(double(bpatch), color, position);
            else
                sp             = [];
                sp.positions   = position;
                sp.color       = nan(1,size(volume,4));
                sp.baseline    = nan(1,size(volume,4));
                sp.covariances = nan(1,3,3);
            end
            cpatch = Methods.Utils.subcube(volume, round(sp.positions), [1,1,0]);
            
            % Construct the neuron.
            neuron = Neurons.Neuron;
            neuron.position = sp.positions;
            neuron.color = sp.color;
            neuron.baseline = sp.baseline;
            neuron.covariance = sp.covariances;
            neuron.color_readout = median(reshape(cpatch, [numel(cpatch)/size(cpatch, 4), size(cpatch, 4)]));
            obj.neurons(end+1) = neuron;
        end
        
        function del_neuron(obj, neuron_i)
            %DEL_NEURON Delete a neuron from the list of neurons.
            
            % Is the index in range?
            if neuron_i > length(obj.neurons)
                return;
            end
            
            % Delete the neuron.
            del_rank = obj.neurons(neuron_i).rank;
            obj.neurons(neuron_i) = [];
            
            % No ranks.
            if isempty(del_rank)
                return;
            end
            
            % Adjust the ranks.
            % Note: newly added neurons may have no rank.
            for i = 1:length(obj.neurons)
                neuron = obj.neurons(i);
                if neuron.rank > del_rank
                    neuron.rank = neuron.rank - 1;
                end
            end
        end
        
        function rank_neuron_max(obj, neuron_i)
            %RANK_NEURON_MAX Give a neuron the maximum rank.
            
            % Is the index in range?
            if neuron_i > length(obj.neurons)
                return;
            end
            
            % No ranks.
            if length(obj.get_ranks()) <= 1
                return;
            end
            
            % Adjust the ranks.
            % Note: newly added neurons may have no rank.
            neuron = obj.neurons(neuron_i);
            old_rank = neuron.rank;
            neuron.rank = [];
            for i = 1:length(obj.neurons)
                neuron = obj.neurons(i);
                if neuron.rank > old_rank
                    neuron.rank = neuron.rank - 1;
                end
            end
            
            % Give the neuron the maximum rank.
            obj.neurons(neuron_i).rank = max(obj.get_ranks()) + 1;
        end
        
        function unrank_neuron(obj, neuron_i)
            %UNRANK_NEURON Remove the neuron's rank.
            
            % Is the index in range?
            if neuron_i > length(obj.neurons)
                return;
            end
            
            % Unrank the neuron.
            neuron = obj.neurons(neuron_i);
            old_rank = neuron.rank;
            neuron.rank = [];
            neuron.deterministic_id = [];
            neuron.probabilistic_ids = [];
            neuron.probabilistic_probs = [];
            
            % No ranks.
            ranks = obj.get_ranks();
            if isempty(ranks)
                return;
            end
            
            % Adjust the ranks.
            % Note: newly added neurons may have no rank.
            for i = 1:length(obj.neurons)
                neuron = obj.neurons(i);
                if neuron.rank > old_rank
                    neuron.rank = neuron.rank - 1;
                end
            end
        end

        %% COUNT NEURONS.

        function num = num_neurons(obj)
            %NUM_NEURONS the number of neurons in the image
            num = length(obj.neurons);
        end
        function [index_neurons, tests] = getOutliers(obj, p)
            %index_neurons indexes the neurons that are outliers at the
            %significance level p.
            %tests containts the results of all individual tests performed,
            %for each of the outliers
            %test(i).global is the p-value of the global test (using color +
            %position), based on chi^2 with 6 df for the i-th outlier.
            %test(i).position_test and tests(i).color_test contain position and color specific 
            %tests.
            %
            %tests(i).position_test.global and tests(i).color_test.global are global tests 
            %based on chi^2 with 3 df.
            %
            %tests(i).position_test.individual and tests(i).color_test.individual contain
            %the 3 tests (each) forevery position and color coordinates, each based
            %on a chi^2 with one degree of freedom.
            
            t = nan*ones(obj.num_neurons(),1);
             for i =1:obj.num_neurons()
                 n=obj.neurons(i);
                 if(~isempty(n.outlier))
                 t(i) = n.outlier.global_test;
                 end
                 
             end
             
             index_neurons = find(t<p);
            for i=1:length(index_neurons)
                n = obj.neurons(index_neurons(i));
                tests(i).global_test = n.outlier.global_test;
                tests(i).position_test.global = n.outlier.position_test.global;
                tests(i).position_test.individual = n.outlier.position_test.individual;
                tests(i).color_test.global = n.outlier.color_test.global;
                tests(i).color_test.individual = n.outlier.color_test.individual;
            end
        end    

            
        function num = num_user_id_neurons(obj)
            %NUM_USER_ID_NEURONS the number of user ID'd neurons in the image
            num = sum(arrayfun(@(x) ~isempty(x.annotation), obj.neurons));
        end
        
        function num = num_user_unid_neurons(obj)
            %NUM_USER_UNID_NEURONS the number of user unID'd neurons in the image
            num = obj.num_neurons() - obj.num_user_id_neurons();
        end
        
        function num = num_auto_id_neurons(obj)
            %NUM_AUTO_ID_NEURONS the number of auto ID'd neurons in the image
            num = sum(arrayfun(@(x) ~isempty(x.deterministic_id), obj.neurons));
        end

        function is_fully_annotated = is_all_annotated(obj)
            %IS_ALL_ANNOTATED do all neurons have user annotations?
            is_fully_annotated = obj.num_neurons() == obj.num_user_id_neurons();
        end
        
        function is_annotated = is_any_annotated(obj)
            %IS_ANY_ANNOTATED do any of the neurons have user annotations?
            is_annotated = obj.num_auto_id_neurons() > 0;
        end

        function is_auto_IDd = is_any_auto_ID(obj)
            %IS_ANY_ANNOTATED do any of the neurons have user annotations?
            is_auto_IDd = obj.num_user_id_neurons() > 0;
        end
        
        
        %% NEURON POSITIONS, COLORS, & SHAPES.
        
        function positions = get_positions(obj)
            %GET_POSITIONS getter of neuron positions.
            positions = [];
            if isempty(obj.neurons)
                return;
            end
            positions = vertcat(obj.neurons.position);
        end
        
        function colors = get_colors(obj)
            %GET_COLORS getter of neuron colors.
            % *** NOTE: THIS FUNCTION MAY RETURN NANS!!!
            colors = [];
            if isempty(obj.neurons)
                return;
            end
            colors = vertcat(obj.neurons.color);
        end
        
        function colors = get_colors_readout(obj)
            %GET_COLORS_READOUT getter of neuron color readouts.
            colors = [];
            if isempty(obj.neurons)
                return;
            end
            colors = vertcat(obj.neurons.color_readout);
        end

        function baselines = get_baselines(obj)
            %GET_BASELINES getter of neuron baselines.
            % *** NOTE: THIS FUNCTION MAY RETURN NANS!!!
            baselines = [];
            if isempty(obj.neurons)
                return;
            end
            baselines = vertcat(obj.neurons.baseline);
        end

        function covariances = get_covariances(obj)
            %GET_COVARIANCES getter of neuron covariances.
            % *** NOTE: THIS FUNCTION MAY RETURN NANS!!!
            covariances = [];
            if isempty(obj.neurons)
                return;
            end
            covariances = vertcat(obj.neurons.covariance);
            %covariances = permute(cat(3, obj.neurons.covariance), [3,1,2]);
        end
        
        function truncations = get_truncations(obj)
            %GET_TRUNCATIONS getter of neuron truncations.
            % *** NOTE: THIS FUNCTION MAY RETURN NANS!!!
            truncations  = [];
            if isempty(obj.neurons)
                return;
            end
            truncations = vertcat(obj.neurons.truncation);
        end
        
        function update_colors(obj, data, old_RGBW, new_RGBW)
            %UPDATE_COLORS update the neuron colors.
            
            % Are there any neurons?
            if isempty(obj.neurons)
                return;
            end
            
            % Did the colors change?
            if isequaln(old_RGBW, new_RGBW)
                return;
            end
            
            % Determine the new data.
            data = data(:,:,:,new_RGBW);
            
            % Set the neuron patch size.
            patch_hsize = [3,3,0];
            
            % Update the color channels.
            for i = 1:length(obj.neurons)
                
                % Delete the old RGB data.
                neuron = obj.neurons(i);
                neuron.color = nan(1,4);
                neuron.baseline = nan(1,4);
                neuron.aligned_xyzRGB = [];
                
                % Compute the color.
                patch = Methods.Utils.subcube(data, ...
                    round(neuron.position), patch_hsize);
                neuron.color_readout = ...
                    nanmedian(reshape(patch, ...
                    [numel(patch)/size(patch, 4), size(patch, 4)]));
            end
        end
        
        %% USER ID'D NEURONS.
        
        function names = user_id_neuron_names(obj)
            %USER_ID_NEURON_NAMES get a list of the user ID neuron names
            names = {};
            for i = 1:length(obj.neurons)
                if ~isempty(obj.neurons(i).annotation)
                    names{end+1} = obj.neurons(i).annotation;
                end
            end
        end

        function neurons = user_id_neurons(obj)
            %USER_ID_NEURONS get a list of the user ID neurons
            id_neurons = arrayfun(@(x) ~isempty(x.annotation), obj.neurons);
            neurons = obj.neurons(id_neurons);
        end

        function [neuron, i] = find_user_id_neuron(obj, name)
            %FIND_USER_ID find a neuron by user ID name
            % Note: since this method only returns one neuron, it ignores
            % artifacts, mutations, and emphasized neurons as these can
            % exist as duplicates. Please use find_user_id_neurons to
            % search for multiple neurons.
            
            % Ignore artifacts and mutations.
            i = [];
            neuron = [];
            if strcmp(name, 'ARTIFACT') || strcmp(name, 'MUTATION')
                return;
            end
            
            % Find the neuron.
            for i = 1:length(obj.neurons)
                if ~obj.neurons(i).is_emphasized && ...
                        strcmp(name, obj.neurons(i).annotation)
                    neuron = obj.neurons(i);
                    return;
                end
            end
            i = [];
        end
        
        function [neurons, neurons_i] = find_user_id_neurons(obj, name, varargin)
            %FIND_USER_ID find multiple neurons by user ID name
            % Inputs:
            %  name = the name of the neuron to find
            %  [is_emphasized] = find emphasized neurons too?
            %                    default: false
            neurons = [];
            neurons_i = [];
            for i = 1:length(obj.neurons)
                if strncmp(name, obj.neurons(i).annotation, length(name))
                    neurons(end + 1) = obj.neurons(i);
                    neurons_i(end + 1) = i;
                end
            end
            
            % Remove emphasized neurons.
            % Note: emphasized neurons are used to emphasize mutations and
            % can exist as duplicates.
            if isempty(varargin) || ~varargin{1}
                remove_i = vertcat(neurons.is_emphasized);
                neurons = neurons(remove_i);
                neurons_i = neurons_i(remove_i);
            end
        end
        
        function annotations = get_annotations(obj)
            %GET_ANNOTATIONS getter of neuron annotations.
            % *** NOTE: THIS FUNCTION MAY RETURN < NUM(NEURONS)!!!
            annotations = [];
            if isempty(obj.neurons)
                return;
            end
            annotations = vertcat({obj.neurons.annotation})';
        end

        function is_annotations_on = get_is_annotations_on(obj)
            %GET_IS_ANNOTATIONS_ON getter of neuron is_annotation_ons.
            is_annotations_on = [];
            if isempty(obj.neurons)
                return;
            end
            is_annotations_on = vertcat(obj.neurons.is_annotation_on);
        end

        function annotation_confidences = get_annotation_confidences(obj)
            %GET_ANNOTATION_CONFIDENCES getter of neuron annotation_confidences.
            annotation_confidences = [];
            if isempty(obj.neurons)
                return;
            end
            annotation_confidences = vertcat(obj.neurons.annotation_confidence);
        end
        
        function is_emphasized = get_is_emphasized(obj)
            %GET_IS_EMPHASIZED getter of neuron is_emphasized.
            is_emphasized = [];
            if isempty(obj.neurons)
                return;
            end
            is_emphasized = vertcat(obj.neurons.is_emphasized);
        end
        
        function flipLR_annotations(obj)
            %FLIPLR_ANNOTATIONS flip the L/R annotation for all user IDs.
            for i = 1:length(obj.neurons)
                obj.neurons(i).annotation = ...
                    Neurons.NeuroPAL.flipLR(obj.neurons(i).annotation);
            end
        end
        
        function delete_annotations(obj)
            %DELETE_ANNOTATIONS delete all user IDs.
            for i = 1:length(obj.neurons)
                obj.neurons(i).delete_annotation();
            end
        end
        
        
        %% AUTO ID'D NEURONS.
        
        function add_deterministic_ids(obj, deterministic_ids)
            %ADD_DETERMINISTIC_IDS setter of neuron deterministic_ids.
            for i=1:length(obj.neurons)
                obj.neurons(i).deterministic_id = deterministic_ids{i};
            end
        end

        function deterministic_ids = get_deterministic_ids(obj)
            %GET_DETERMINISTIC_IDS getter of neuron deterministic_ids.
            % *** NOTE: THIS FUNCTION MAY RETURN < NUM(NEURONS)!!!
            deterministic_ids = vertcat({obj.neurons.deterministic_id});
        end

        function add_probabilistic_ids(obj, probabilistic_ids)
            %ADD_PROBABILISTIC_IDS setter of neuron probabilistic_ids.
            for i=1:length(obj.neurons)
                obj.neurons(i).probabilistic_ids = probabilistic_ids(i, :);
            end
        end

        function probabilistic_ids = get_probabilistic_ids(obj)
            %GET_PROBABILISTIC_IDS getter of neuron probabilistic_ids.
            % *** NOTE: THIS FUNCTION MAY RETURN < NUM(NEURONS)!!!
            probabilistic_ids = [];
            if isempty(obj.neurons)
                return;
            end
            probabilistic_ids = vertcat(obj.neurons.probabilistic_ids);
        end

        function add_probabilistic_probs(obj, probabilistic_probs)
            %ADD_PROBABILISTIC_PROBS setter of neuron probabilistic_probs.
            for i=1:length(obj.neurons)
                obj.neurons(i).probabilistic_probs = probabilistic_probs(i, :);
            end
        end

        function probabilistic_probs = get_probabilistic_probs(obj)
            %GET_PROBABILISTIC_PROBS getter of neuron probabilistic_probs.
            % *** NOTE: THIS FUNCTION MAY RETURN < NUM(NEURONS)!!!
            probabilistic_probs = [];
            if isempty(obj.neurons)
                return;
            end
            probabilistic_probs = vertcat(obj.neurons.probabilistic_probs);
        end
        
        function add_ranks(obj, ranks)
            %ADD_RANKS setter of neuron ranks.
            for i=1:length(obj.neurons)
                obj.neurons(i).rank = ranks(i);
            end
        end
        
        function [neuron, i] = find_rank(obj, rank_num)
            %FIND_RANK find the neuron with given rank.
            i = find(obj.get_ranks() == rank_num,1);
            neuron = obj.neurons(i);
        end

        function ranks = get_ranks(obj)
            %GET_RANKS getter of neuron ranks.
            % *** NOTE: THIS FUNCTION MAY RETURN < NUM(NEURONS)!!!
            ranks = [];
            if isempty(obj.neurons)
                return;
            end
            ranks = vertcat(obj.neurons.rank);
        end
        
        function delete_model_IDs(obj)
            %DELETE_MODEL_IDS delete all the model-predicted IDs.
            for i = 1:length(obj.neurons)
                obj.neurons(i).delete_model_ID();
            end
        end
        
        
        %% NEURON STATISTICAL ATLAS.
        
        function aligned_xyzRGBs = get_aligned_xyzRGBs(obj)
            %GET_ALIGNED_XYZRGBS getter of aligned neuron positions +  colors.
            % *** NOTE: THIS FUNCTION MAY RETURN < NUM(NEURONS)!!!
            aligned_xyzRGBs = [];
            if isempty(obj.neurons)
                return;
            end
            aligned_xyzRGBs = vertcat(obj.neurons.aligned_xyzRGB);
        end

        
        %% NEURON META DATA.
                
        function add_meta_data(obj, key, value)
            %ADD_META_DATA adding a (key,value) pair in the meta_data data
            %structure for intermediate analysis, examples are LL (log
            %likelihood) etc.
            obj.meta_data(key) = value;
        end

        function value = get_meta_data(obj, key)
            %GET_META_DATA returns the value paired with key.
            value = obj.meta_data(key);
        end
        
        
        %% FIND NEARBY NEURONS.
        
        function [neuron, i] = nearest_unannotated(obj, neuron_i)
            %NEAREST_UNANNOTATED find the nearest unannoted neuron

            % Find the unannotated neurons.
            unIDd_i = find(arrayfun(@(x) isempty(x.annotation), obj.neurons));
            unIDd_i = setdiff(unIDd_i, neuron_i);
            positions = round(vertcat(obj.neurons(unIDd_i).position));

            % No neurons found.
            neuron = [];
            i = [];
            if isempty(positions)
                return;
            end
            
            % Correct the positions for image scale. 
            % Gonzalo (me) transposed obj.scale because otherwise it
            % generates an error. To be checked whether this is the right
            % solution
            position = obj.neurons(neuron_i).position;
            position = position .* obj.scale;
            positions = positions .* obj.scale;
            
            % Find the nearest unannotated neuron in (x,y,z).
            [~,min_i] = min(sum((positions - position).^2,2));
            i = unIDd_i(min_i);
            neuron = obj.neurons(i);
        end

        function [neuron, i] = nearest_unannotated_z(obj, neuron_i)
            %NEAREST_UNANNOTATED_Z find the nearest unannoted neuron in z
            
            % Find the unannotated neurons.
            position = round(obj.neurons(neuron_i).position);
            unIDd_i = find(arrayfun(@(x) isempty(x.annotation), obj.neurons));
            positions = round(vertcat(obj.neurons(unIDd_i).position));
            
            % No neurons found.
            neuron = [];
            i = [];
            if isempty(positions)
                return;
            end
            
            % Find the nearest unannotated neuron in z.
            [~, min_z_i] = min(abs(positions(:,3) - position(3)));
            min_z = positions(min_z_i,3);
            min_z_i = find(positions(:,3) == min_z);
            
            % Find the nearest unannotated neuron in (x,y).
            [~, min_xy_i] = min(sum(positions(min_z_i,1:2).^2) - sum(position(1:2).^2));
            i = unIDd_i(min_z_i(min_xy_i));
            neuron = obj.neurons(i);
        end
        
        
        %% ROTATE THE IMAGE, NEURONS, OR BOTH.
        
        function rot_image = rotate_X_180(obj, rot_image)
            %ROTATE_X_180 Rotate everything 180 degrees around the x-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 180 degrees around the x-axis
            obj.rotate_neurons_X_180(rot_image);
            rot_image = obj.rotate_image_X_180(rot_image);
        end

        function rot_image = rotate_Y_180(obj, rot_image)
            %ROTATE_Y_180 Rotate everything image 180 degrees around the y-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 180 degrees around the y-axis
            obj.rotate_neurons_Y_180(rot_image);
            rot_image = obj.rotate_image_Y_180(rot_image);
        end
        
        function rotate_neurons_X_180(obj, rot_image)
            %ROTATE_NEURONS_X_180 Rotate the neurons 180 degrees around the x-axis
            %   image: the image to rotate
            for i=1:length(obj.neurons)
                position =  obj.neurons(i).position;
                obj.neurons(i).position(2) = size(rot_image,2) - position(2) + 1;
                obj.neurons(i).position(3) = size(rot_image,3) - position(3) + 1;
            end
        end
        
        function rotate_neurons_Y_180(obj, rot_image)
            %ROTATE_NEURONS_Y_180 Rotate the neurons 180 degrees around the y-axis
            %   image: the image to rotate
            for i=1:length(obj.neurons)
                position =  obj.neurons(i).position;
                obj.neurons(i).position(1) = size(rot_image,1) - position(1) + 1;
                obj.neurons(i).position(3) = size(rot_image,3) - position(3) + 1;
            end
        end
        
        function rot_image = rotate_image_X_180(obj, rot_image)
            %ROTATE_IMAGE_X_180 Rotate an image 180 degrees around the x-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 180 degrees around the x-axis
            rot_image = rot_image(:,end:-1:1,end:-1:1,:,:);
        end
        
        function rot_image = rotate_image_Y_180(obj, rot_image)
            %ROTATE_IMAGE_Y_180 Rotate an image 180 degrees around the y-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 180 degrees around the y-axis
            rot_image = rot_image(end:-1:1,:,end:-1:1,:,:);
        end
        
        function [rot_image, scale] = rotate_Z_90(obj, rot_image, scale)
            %ROTATE_Z_90 Rotate everything 90 degrees around the z-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 90 degrees around the z-axis
            %   scale: the image's microns/pixels scale
            obj.rotate_neurons_Z_90(rot_image);
            [rot_image, scale] = obj.rotate_image_Z_90(rot_image, scale);
        end
        
        function [rot_image, scale] = rotate_Z_270(obj, rot_image, scale)
            %ROTATE_Z_270 Rotate everything 270 degrees around the z-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 270 degrees around the z-axis
            %   scale: the image's microns/pixels scale
            obj.rotate_neurons_Z_270(rot_image);
            [rot_image, scale] = obj.rotate_image_Z_270(rot_image, scale);
        end
        
        function rotate_neurons_Z_90(obj, rot_image)
            %ROTATE_NEURONS_Z_90 Rotate the neurons 90 degrees around the z-axis
            %   image: the image to rotate
            for i=1:length(obj.neurons)
                position =  obj.neurons(i).position;
                obj.neurons(i).position(1) = position(2);
                obj.neurons(i).position(2) = size(rot_image,1) - position(1) + 1;
            end
        end
        
        function rotate_neurons_Z_270(obj, rot_image)
            %ROTATE_NEURONS_Z_270 Rotate the neurons 270 degrees around the z-axis
            %   image: the image to rotate
            for i=1:length(obj.neurons)
                position =  obj.neurons(i).position;
                obj.neurons(i).position(1) = size(rot_image,2) - position(2) + 1;
                obj.neurons(i).position(2) = position(1);
            end
        end
        
        function [rot_image, scale] = rotate_image_Z_90(obj, rot_image, scale)
            %ROTATE_IMAGE_Z_90 Rotate an image 90 degrees around the z-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 90 degrees around the z-axis
            %   scale: the image's microns/pixels scale
            rot_image = permute(rot_image, [2,1,3,4]);
            rot_image = rot_image(:,end:-1:1,:,:,:);
            scale([1,2]) = scale([2,1]);
        end
        
        function [rot_image, scale] = rotate_image_Z_270(obj, rot_image, scale)
            %ROTATE_IMAGE_Z_270 Rotate an image 270 degrees around the z-axis
            %   image: the image to rotate
            %   rot_image: the image rotated 270 degrees around the z-axis
            %   scale: the image's microns/pixels scale
            rot_image = permute(rot_image, [2,1,3,4]);
            rot_image = rot_image(end:-1:1,:,:,:,:);
            scale([1,2]) = scale([2,1]);
        end
        
        function rot_image = rotate(obj, image, rot)
            %ROT_IMAGE Rotates the image using parameters specified in rot
            %   image: the full image that needs to be rotated
            %   rot: a 4x4 rotation matrix or a 1x3 vector consisting
            %   rotation angles. The rotation will be applied to the full
            %   image and the neurons one by one.
            %   rot_image: the rotated image
            if isvector(rot)
                rot_mat = makehgtform('xrotate',rot(1),'yrotate',rot(2),'zrotate',rot(3));
            else
                rot_mat = rot;
            end

            rot_image = [];
            sz = size(image);
            Rin = imref3d(sz(1:3));

            Rin.XWorldLimits = Rin.XWorldLimits-2*mean(Rin.XWorldLimits);
            Rin.YWorldLimits = Rin.YWorldLimits-2*mean(Rin.YWorldLimits);
            Rin.ZWorldLimits = Rin.ZWorldLimits-2*mean(Rin.ZWorldLimits);

            for c=1:size(image,4)
                rot_image(:,:,:,c) = imwarp(image(:,:,:,c,:),Rin,affine3d(rot_mat),'cubic');
            end

            newsz = size(rot_image);

            for i=1:length(obj.neurons)
                obj.neurons(i).rotate(rot_mat,sz([1,2,3]),newsz([1,2,3]))
            end
        end
        
        
        %% MIRROR THE IMAGE OR NEURONS
        
        function mirror_image = mirror_image_Z(obj, mirror_image)
            %MIRROR_IMAGE_Z Mirror an image around the z-axis
            %   image: the image to mirror
            %   rot_image: the image mirrored around the z-axis
            mirror_image = mirror_image(:,:,end:-1:1,:,:);
        end
        
        function mirror_neurons_Z(obj, mirror_image)
            %MIRROR_NEURONS_Z Mirror the neurons around the z-axis
            %   image: the image to mirror
            for i=1:length(obj.neurons)
                position =  obj.neurons(i).position;
                obj.neurons(i).position(3) = size(mirror_image,3) - position(3) + 1;
            end
        end
        
                
        %% GUI DRAWING METHODS.
        
        function colors = get_marker_colors(obj)
            %GET_MARKER_COLORS getter of neuron marker_colors.
            colors = zeros(length(obj.neurons), 3);
            for i=1:length(obj.neurons)
                colors(i,:) = obj.neurons(i).get_marker_color();
            end
        end

        function sizes = get_marker_sizes(obj)
            %GET_MARKER_SIZES getter of neuron marker_sizes.
            sizes = zeros(length(obj.neurons), 1);
            for i=1:length(obj.neurons)
                sizes(i) = obj.neurons(i).get_marker_size();
            end
        end

        function sizes = get_line_sizes(obj)
            %GET_LINE_COLORS getter of neuron line_sizes.
            sizes = zeros(length(obj.neurons), 1);
            for i=1:length(obj.neurons)
                sizes(i) = obj.neurons(i).get_line_size();
            end
        end

        function image = get_3d_shape(obj,sz,nsz)
            %GET_3D_SHAPE getter of neuron 3d reconstructions.
            %   sz: size of the full reconstructed image, which is the same
            %   size of the original image used for fitting.
            %   nsz: size of a neuron used for reconstruction.
            %   trunc: Gaussian truncation value used for reconstruction.
            %   image: full reconstruction of image using truncated
            %   Gaussian functions and stitching them together.
            image = zeros(sz);
            for i=1:length(obj.neurons)
                image = Methods.Utils.superpose(image, round(obj.neurons(i).position), obj.neurons(i).get_3d_reconstruction(nsz));
            end
        end
        
        function image = get_3d_segments(obj,sz,nsz)
            %GET_3D_SEGMENTS getter of neuron 3d segmentations.
            %   sz: size of the full reconstructed image, which is the same
            %   size of the original image used for fitting.
            %   nsz: size of a neuron used for reconstruction.
            %   trunc: Gaussian truncation value used for reconstruction.
            %   image: full reconstruction of image using truncated
            %   Gaussian functions and stitching them together.
            
            image = zeros(sz(1:3));
            for i=1:length(obj.neurons)
                recon = obj.neurons(i).get_3d_reconstruction(nsz);
                recon(recon>0) = i;
                recon = max(recon, [], 4);
                image = Utils.superpose(image, round(obj.neurons(i).position), recon);
            end
        end
        
        
        %% DEPRECATED SAVING METHOD.
        
        function sp = to_superpixel(obj)
            %TO_SUPERPIXEL coverts the neurons to a superpixel data
            %structure for data loading and storing and for interfacing
            %with different softwares and programming languages.
            % *** LEGACY FUNCTION. DEPRECATED, DON'T USE THIS!!!
            
            % Is there any data?
            sp = [];
            if isempty(obj.neurons)
                return;
            end
            
            % Marshall the data into a struct.
            % Neuron position & color.
            sp.positions = obj.get_positions();
            sp.color = obj.get_colors();
            sp.color_readout = obj.get_colors_readout();
            sp.baseline = obj.get_baselines();
            sp.covariances = obj.get_covariances();
            sp.truncation = obj.get_truncations();
            sp.aligned_xyzRGB  = obj.get_aligned_xyzRGBs();
            % Neuron user ID.
            sp.annotation = obj.get_annotations();
            sp.is_annotation_on = obj.get_is_annotations_on();
            sp.annotation_confidence = obj.get_annotation_confidences();
            % Neuron auto ID.
            sp.atlas_version = obj.atlas_version;
            sp.probabilistic_ids = obj.get_probabilistic_ids();
            sp.deterministic_id = obj.get_deterministic_ids()';
            sp.probabilistic_probs = obj.get_probabilistic_probs();
            sp.rank = obj.get_ranks();
        end
    end
end
