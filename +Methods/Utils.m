classdef Utils
    %UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        function neurons = removeNearbyNeurons(neurons, min_xy, min_z)
        % REMOVENEARBYNEURONS Remove neurons that are too near each other
        % (duplicate detections).
        % Inputs:
        %   neurons = the image with the list of neurons to check
        %   min_xy  = the minimum distance allowed between neurons in x & y
        %   min_z   = the minimum distance allowed between neurons in z
        % Note: we use the L2 norm for x & y distances, and L1 norm for z.
        % We do this because x & y often have ~3x better resolution than z.
        import Neurons.*;
        
        % Get the neuron positions and colors.
        pos = neurons.get_positions();
        colors = neurons. get_colors_readout();
        
        % Scale the neuron positions.
        pos(:,1) = pos(:,1) * neurons.scale(1);
        pos(:,2) = pos(:,2) * neurons.scale(2);
        pos(:,3) = pos(:,3) * neurons.scale(3);
        
        % Which neurons are too close?
        sqr_min_xy = min_xy^2;
        num_neurons = size(pos,1);
        is_remove = false(num_neurons,1);
        for i = 1:(num_neurons - 1)
            
            % Are any neurons too close?
            dist_xy = sum((pos(i,1:2) - pos((i+1):end,1:2)).^2, 2);
            dist_z = abs(pos(i,3) - pos((i+1):end,3));
            close_i = find(dist_xy < sqr_min_xy & dist_z < min_z);
            
            % Which neuron is brighter?
            % Note: we use the L2 norm to compare brightness.
            remove_this_i = sum(colors(i,:).^2) < sum(colors(close_i,:).^2);
            
            % If we remove this neuron, the rest stay. We do this because
            % this is the only neuron we know is near all the rest.
            if any(remove_this_i)
                is_remove(i) = true;
                
            % Remove the other nearby neurons.
            else
                is_remove(i+close_i) = true;
            end
        end
        
        % Remove duplicate neurons.
        remove_i = find(is_remove);
        for i = 1:length(remove_i)
            
            % Note: "-i - 1" adjusts the indices for deleted neurons.
            neurons.del_neuron(remove_i(i) - i + 1);
        end
        end
        
        function volume = simulate_gaussian(sz, mu, sigma, props, baseline, truncation)
        % Simulate a truncated Gaussian function for fitting procedure. This
        % function is used by matching pursuit algorithm.
        %
        % Amin Nejat
            [pos(:,1), pos(:,2), pos(:,3)] = ind2sub(sz, find(ones(sz(1:3))));

            p = mvnpdf(pos, mu, sigma);
            p(p<truncation) = 0;
            volume = reshape(p*props+baseline, [sz,length(props)]);
        end
        
        function volume = simulate_mvt(sz, mu, covariance, props, baseline, truncation)
        % Simulate a truncated Gaussian function for fitting procedure. This
        % function is used by matching pursuit algorithm.
        %
        % Amin Nejat
            [pos(:,1),pos(:,2),pos(:,3)] = ind2sub(sz, find(ones(sz(1:3))));
            p = mvtpdf(pos-mu,covariance,0.1);
            p(p<truncation) = 0;
            volume = reshape(p*props+baseline, [sz,length(props)]);
        end
        
        
        function patch = subcube(cube, loc, center)
        % Grabbing a patch of the image in a given location.
        %
        % Amin Nejat

            sz = [size(cube, 1), size(cube, 2), size(cube, 3)];

            rel = round(center);
            reu = round(center);

            rel(loc - center - 1 < 0) = loc(loc - center - 1 < 0) - 1;
            reu(loc + center - sz > 0) = sz(loc + center - sz > 0) - loc(loc + center - sz > 0);

            patch = cube(loc(1)-rel(1): loc(1)+reu(1), ...
                         loc(2)-rel(2): loc(2)+reu(2), ...
                         loc(3)-rel(3): loc(3)+reu(3), :);
            newcenter = [size(patch, 1), size(patch, 2), size(patch, 3)];

            if any(newcenter(1: 3) ~= 2*round(center)+1)
                pre = round(center) - rel;
                post = round(center) - reu;

                patch = padarray(padarray(patch, pre, 'pre'), post, 'post');
            end
        end
        
        function vol = superpose(vol, loc, F1)
            loc = round(loc);

            sz = size(vol);
            sz = sz(1:3);

            center = round([size(F1, 1), size(F1, 2), size(F1, 3)]/2);

            rel = round(center - 1);
            reu = round(center - 1);

            rel(loc - center - 1 < 0) = loc(loc - center - 1 < 0) - 1;
            reu(loc + center - sz > 0) = sz(loc + center - sz > 0) - loc(loc + center - sz > 0);

            vol(loc(1)-rel(1): loc(1)+reu(1), loc(2)-rel(2): loc(2)+reu(2), loc(3)-rel(3): loc(3)+reu(3), :) = ...
            vol(loc(1)-rel(1): loc(1)+reu(1), loc(2)-rel(2): loc(2)+reu(2), loc(3)-rel(3): loc(3)+reu(3), :) + ...
                F1(center(1)-rel(1): center(1)+reu(1), center(2)-rel(2): center(2)+reu(2), center(3)-rel(3): center(3)+reu(3), :);
        end
        
        function [video, shapes] = sp2video(sp, sz, nsz, trunc)

            shapes = cell(sz(5), size(sp(1).mean,1));
            video = zeros(sz);
            for t = 1: sz(5)
                for n=1:size(sp(t).mean,1)
                    simul = simulate_gaussian(2*nsz+1, ... % size
                            nsz+1+sp(t).mean(n,:)-round(sp(t).mean(n,:)), ... % center
                            squeeze(sp(t).cov(n,:,:)), ... % cov
                            sp(t).color(n,:), ... % colors
                            zeros(size(sp(t).color(n,:))), ... % baseline mean
                            zeros(size(sp(t).color(n,:))), ... % baseline std
                            trunc); % truncation
                    shapes{t,n} = simul;
                    video(:,:,:,:,t) = superpose(video(:,:,:,:,t), round(sp(t).mean(n,:)), simul);

                end
            end

        end
        
        function F = placement(sz, loc, F1)
        % Placing a subcube in a bigger cube (helper function).
        %
        % Amin Nejat

            loc = round(loc);

            center = round([size(F1, 1), size(F1, 2), size(F1, 3)]/2);

            rel = round(center - 1);
            reu = round(center - 1);

            rel(loc - center - 1 < 0) = loc(loc - center - 1 < 0) - 1;
            reu(loc + center - sz > 0) = sz(loc + center - sz > 0) - loc(loc + center - sz > 0);

            F = zeros([sz, size(F1, 4)]);

            F(loc(1)-rel(1): loc(1)+reu(1), loc(2)-rel(2): loc(2)+reu(2), loc(3)-rel(3): loc(3)+reu(3), :) = ...
                F1(center(1)-rel(1): center(1)+reu(1), center(2)-rel(2): center(2)+reu(2), center(3)-rel(3): center(3)+reu(3), :);
        end
        
        function unionsp = union_sp(sp1, sp2)

        % Calculating a subset of superpixels.
        %
        % Amin Nejat
            if isempty(sp1)
                unionsp = sp2;
                return;
            end

            if isempty(sp2)
                unionsp = sp1;
                return;
            end

            unionsp = sp1;

            fields = fieldnames(unionsp);

            for t = 1:length(sp1)
                for field_index = 1:numel(fields)
                    try
                        unionsp(t).(fields{field_index})(end+1:end+size(sp2(t).(fields{field_index}),1),:,:,:,:) = sp2(t).(fields{field_index})(:,:,:,:,:);
                    catch
                    end
                end
            end
        end
        
        function subsp = sub_sp(sp, subset)
        % Calculating a subset of superpixels.
        %
        % Amin Nejat

            subsp = sp;

            fields = fieldnames(subsp);

            for t = 1:length(sp)
                for field_index = 1:numel(fields)
                    try
                        subsp(t).(fields{field_index}) = sp(t).(fields{field_index})(subset,:,:,:,:);
                    catch
                    end
                end
            end

        end
        
        function save_for_parfor(fname,sp,mp_params)
            save(fname, 'sp', 'mp_params');
        end
    end
end
