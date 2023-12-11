classdef AutoId < handle
    %AUTO_ID Auto.
    %
    %   An auto_id object is has a set of possible names (different if tail/head), the method used, a likelihood
    %   matrix, and a set of ids for each of observed neurons. 
    properties(Constant)
        % constants
        ncandidates         = 7;
        annotation_weight   = 1e1;
        
        iter_sinkhorn       = 500;
        iter_rwc            = 10;
        
        min_log_likelihood  = -1e9;
        max_log_likelihood  = 1e5;
        
        %parameters for automatic detection of false positives. pf=prob of
        %a detect being a false positive. max_fp is the maximum posible
        %number of false positives.
        p_fp = 1e-50; %if p = 10^(-Large number) no neuron is a false positive. 
        max_fp = 0; %chosen a larger number slows down computations cubicly.
        
        theta = 0: 0.25: 2*pi
    end
    
    properties(Access = private)
        atlas_version % the version for the atlas
        atlas % atlas data structure containing neuron names, positions, colors, and their covariances
        
        log_likelihood % likelihood matrix, of size n_mp x n_possible
        assignments % matrix of assignment for each observed neuron to canonical identity. Binary matrix of size n_mp x n_possible
        assignment_prob_ranks % n_obsx7 matrix with the 7 most likely assignment
        assignment_prob_probs % n_obsx7 matrix with the corresponding probabilities of assignment_prob_ranks
        
        pool = []; % pool for parallel processing
        pool_timeout = 1; % parallel processing timeout
    end
    
    methods(Static)
        
        function obj = instance()
             persistent instance
             if isempty(instance)
                 
                 % Create the single instantiation.
                 instance = Methods.AutoId();
                 
                 % Load the hermaphrodite neuron models.
                 model = load('atlas_xx_rgb.mat');
                 instance.atlas_version.xx = model.version;
                 instance.atlas.xx = model.atlas;
                 
                 % Load the male neuron models.
                 model = load('atlas_xo_rgb.mat');
                 instance.atlas_version.xo = model.version;
                 instance.atlas.xo = model.atlas;
             end
             obj = instance;
        end
        
        function is_ID = isBodyID(sex, body)
            %ISBODYID Can we ID this body part?
            % Input:
            %  sex   = the sex of the worm
            %  body  = the body part we want to ID
            % Output:
            %  is_ID = can we ID this body part?
            obj = Methods.AutoId.instance();
            is_ID = isfield(obj.atlas.(lower(sex)), lower(body)); 
        end
        
        function BatchId(file, worm)
            % Batch ID neurons.
            
            % Open the image file.
            try
                [~, ~, ~, ~, ~, neurons, ~, id_file] = ...
                    DataHandling.NeuroPALImage.open(file);
            catch
                % For now, don't throw exceptions from threads.
                warning('Cannot read: "%s"', file);
                return;
            end
            
            % Save the auto ID'd neurons.
            Methods.AutoId.instance().id(file, neurons, worm);
            save(id_file, 'neurons', '-append');
        end
        
        %% Utility functions.
        function rotmat = rotmat(theta)
            rotmat = [cos(theta) -sin(theta);...
                      sin(theta) cos(theta)];
        end
        
        function pos = major_axis_align(pos,sign)
            [coeff,~,~,~,~,mu] = pca(pos);
            coeff(:,1:2) = coeff(:,1:2)*sign;
            pos = (pos-mu)*coeff;
        end
      
        function D = pdist2_maha(X,Y,Sigma)
            % mahalanobis distance between a set of points and the
            % components of a GMM
            D=zeros(size(X,1),size(Y,1));
            if isempty(X)
                return;
            end
            
            for i=1:size(Y,1)
                D(:,i)=pdist2(X,Y(i,:),'mahalanobis',Sigma(:,:,i)+eye(size(Sigma,1))*1e-5).^2/2;
            end
        end
        
        function vec_x = vec(x)
            % vectorize multi-dimensional array
            vec_x = x(:);
        end
        

        %% Algorithmic functions.
        function beta = MCR_solver(Y,X,sigma,lambda)
            % MCR - Multiple covariance regression solver
            % Y - Target (n x d)
            % X - Source (n x p)
            % Sigma - covariances for each row of Y (d x d x n)
            % Solving: \sum_i \|Y_i - X_i \beta\|_{sigma_i}^2
            
            nanind = any(isnan(X),2) | any(isnan(Y),2);
            
            X = X(~nanind,:); Y = Y(~nanind,:);
            % variables
            d1 = size(Y,2); d2 = size(X,2); n = size(Y,1);
            
            % memory allocation
            A = zeros(d1*d2,d1*d2,n); B = zeros(d2,d1,n);
            
            % to learn about math look at the paper
            for i=1:size(Y,1)
                A(:,:,i) = kron(inv(sigma(:,:,i)),X(i,:)'*X(i,:));
                B(:,:,i) = X(i,:)'*Y(i,:)/sigma(:,:,i);
            end
            
            A(:,:,end+1)=lambda.*eye(size(A,1),size(A,2));
            B(:,:,end+1)=[lambda*eye(size(B,1)-1,size(B,2));zeros(1,size(B,2))];
            
            beta = reshape(nansum(A,3)\Methods.AutoId.vec(nansum(B,3)),[size(X,2),size(Y,2)]);
        end
        
        function [S,R,T]=scaled_rotation(X,Y)
            %Solves for Y = S*R*X + T
            %where S is a diagonal scaling matrix
            %R is a rotation matrix i.e. orthonormal and det(R)=1
            %T is a translation
            
            % Remove NAN rows
            idx=find(all(~isnan([X Y]),2));
            X=X(idx,:);
            Y=Y(idx,:);

            % De-mean
            Yhat=Y-mean(Y,1);
            Xhat=X-mean(X,1);

            % Scale
            sx = sqrt(sum(sum(Xhat.^2,2),1)/size(Xhat,1));
            sy = sqrt(sum(sum(Yhat.^2,2),1)/size(Yhat,1));

            Yhat=Yhat./sy;
            Xhat=Xhat./sx;

            % Solve rotation
            C = Yhat'*Xhat;
            [U,~,V]=svd(C);

            R0=V*U';
            
            % Put it all together
            S=diag(sy./sx);
            R=R0;
            T=(mean(Y,1)-mean(X,1)*R0*S);
        end
        
        function P = sinkhorn_logspace(logP,niter)
            a=nanmin(nanmin(logP(~isinf(logP))));
            logP(isinf(logP))=a-10000;
            logP(isnan(logP))=-a-10000;
            n1 = size(logP,1);
            n2 = size(logP,2);

            logP2 =-1e-100*ones(max(n1,n2), max(n1,n2));
           
            if(n1<n2)
                logP2(1:n1,:)=logP;
            elseif(n1>n2)
                logP2(:,1:n2)=logP;
            else
                logP2 = logP;
            end

            for i=1:niter
                logP2 = logP2 - repmat(Methods.logsumexp(logP2, 1), [size(logP2,1), 1]);
                logP2 = logP2 - repmat(Methods.logsumexp(logP2, 2), [1, size(logP2,2)]);
            end
            P = exp(logP2);
            P = P(1:n1,1:n2);
        end
        
        
        function P = sinkhorn_logspace_extended(logP,niter, p, n1)
            
            logP = -logP;
            n2 = size(logP,2);
            p2 = p/n1;
            p1 = (1-p)/n2;
            logP = logP - log(p1);


            logP(:,n2+1:n2+n1) = -log(p2);
            
            P = Methods.AutoId.sinkhorn_logspace(-logP, niter);
            P = P(:,1:n2);
        end
        
        
        %% Update ID functions.
        function [P,varargout] = update_permutation(colors, positions, model, known)
            import Methods.*;
            
            M = model.mu;
            X = [positions colors];
            X(any(isnan(X),2),:) = [];
            
            log_likelihoodhat=zeros(size(M,1),size(X,1));
            order = randperm(size(M,3));
            for jj=1:length(order)
                j=order(jj);
                Y=M(:,:,j);
                idx=find(~any(isnan(Y),2));
                Y(any(isnan(Y),2),:)=[];
                D = AutoId.pdist2_maha(X,Y,model.sigma);
                log_likelihoodhat(idx,:)=log_likelihoodhat(idx,:)+D';
            end
            log_likelihoodhat = log_likelihoodhat';
            if(~isempty(known))
                log_likelihoodhat(known(:,1),:) = AutoId.max_log_likelihood;
                for i=1:size(known,1)
                    log_likelihoodhat(known(i,1),known(i,2)) = AutoId.min_log_likelihood;
                end
            end
            
            if nargout > 0
                [P,cost,~] = Methods.munkres_extended(log_likelihoodhat, Methods.AutoId.p_fp, Methods.AutoId.max_fp);
                P = double(P); P(:,~any(P)) = NaN;
                varargout{1} = cost;
                
                Q = P;
                for i=1:size(known,1)
                    Q(known(i,1),known(i,2)) = NaN;
                end
                varargout{1} = nansum(Q(:).*log_likelihoodhat(:));
            else
                P = Methods.munkres_extended(log_likelihoodhat, Methods.AutoId.p_fp, Methods.AutoId.max_fp);
                P = double(P); P(:,~any(P)) = NaN;
            end
        end
        
        %% Alignment functions.
        function [col,pos,cost] = local_alignment(col,pos,model,theta,sgn,annotated)
            % local alignment between atlas and rotated points for given
            % theta
            import Methods.AutoId;
            
            POS = pos;
            
            % GMM for computing the likelihood of current local alignment
%             gm = gmdistribution(model.mu,model.sigma);
            
            % standardize positions by axis aligning it
            pos = AutoId.major_axis_align(POS,sgn);
            
            % compute the rough transformation between atlas centers and
            % its axis-aligned version 
            [coeff_mu,~,~,~,~,mu_mu] = pca(model.mu(:,[1 2 3]));
            coeff_mu = coeff_mu*det(coeff_mu);
            
            % transform rotated positions based on the atlas transformation
            % to roughly align it
            pos(:,[2 3]) = pos(:,[2 3])*AutoId.rotmat(theta);
            pos = pos*coeff_mu'+mu_mu;
            
            % standardize positions by axis aligning it
            pos = AutoId.major_axis_align(pos,1);
            
            % upweighting already annotated neurons
            weights = ones(1,size(model.mu,1));
            weights(annotated(:,2)) = 1/(size(model.mu,1)*AutoId.annotation_weight);
            
            sigma_weighted = bsxfun(@times, model.sigma, reshape(weights,1,1,size(model.mu,1)));
            
            for iteration = 1: AutoId.iter_rwc
                % sample from GMM components
%                 Z = arrayfun(@(i) mvnrnd(model.mu(i,:), model.sigma(:,:,i)), 1:size(model.mu,1), 'UniformOutput', false);
%                 Z = vertcat(Z{:});
                
                % update permutation
                P = AutoId.update_permutation(col,pos,model,annotated);
                
                % align point to sample
                beta_pos = AutoId.MCR_solver(model.mu(:,1:3), P'*[pos ones(size(pos,1),1)], sigma_weighted(1:3,1:3,:),0);
                beta_col = AutoId.MCR_solver(model.mu(:,4:end), P'*[col ones(size(col,1),1)], sigma_weighted(4:end,4:end,:),1e5);
                
                % making sure that there are no mirror flips
                det_cost = sign(det(beta_pos(1:3,1:3)));
                if det_cost < 0
                    cost = Inf;
                    return
                end
%                 beta_pos(1:3,1:3) = beta_pos(1:3,1:3)*det_cost;
                
                % update positions and colors
                pos = [pos ones(size(pos,1),1)]*beta_pos;
                col = [col ones(size(col,1),1)]*beta_col;
            end
            
%             % compute the cost based on Hungarian
            [~,cost] = AutoId.update_permutation(col,pos,model,annotated);
            
        end
        
    end
        
    
    methods
      
        %% I have no idea what these functions do, maybe we can add more
        % descriptive comments?- Ev
        function add_to_image(obj, im, worm)
            % add_to_image  function simply updates some properties of the image
            % structure that depend on auto_id
            
            neuron_names = obj.atlas.(lower(worm.sex)).(lower(worm.body)).N;
            % convert assignment (probabilistic/deterministic) to neuron
            % names
            ids = repmat({'Artifact'}, size(obj.assignments,1),1);
            ids_prob = repmat({'Artifact'}, size(obj.assignments,1),obj.ncandidates);

            [rows, cols] = find(obj.assignments);
            ids(rows) = neuron_names(cols);

            for i=1:size(obj.assignment_prob_ranks,1)
                for j=1:obj.ncandidates
                    if(obj.assignment_prob_ranks(i,j)>0)
                        ids_prob{i,j} = neuron_names{obj.assignment_prob_ranks(i,j)};
                    end
                end
            end

            ids(cellfun(@isempty, ids)) = {'Artifact'};
            ids_prob(cellfun(@isempty, ids_prob)) = {'Artifact'};
            
            
            % update image information
            im.add_deterministic_ids(ids);
            im.add_probabilistic_ids(ids_prob);
            im.add_probabilistic_probs(obj.assignment_prob_probs)

            [~,rank_uncertain] = sort(obj.assignment_prob_probs(:,1));
            rank_uncertain_inv(rank_uncertain) = 1:length(rank_uncertain);
            im.add_ranks(rank_uncertain_inv');
        end
        
       
        function compute_assignments(obj)
           % compute_assignments computes some secondary properties of auto_id object
           [obj.assignments,~,~] = Methods.munkres_extended(-obj.log_likelihood, Methods.AutoId.p_fp, Methods.AutoId.max_fp);
            
            obj.assignment_prob_ranks = [];
            obj.assignment_prob_probs = [];
            
            P =  Methods.AutoId.sinkhorn_logspace_extended(obj.log_likelihood, Methods.AutoId.iter_sinkhorn, Methods.AutoId.p_fp, Methods.AutoId.max_fp);
            
            assignment_det = zeros(1,size(P,1));
            for i=1:size(P,1)
                prow = [P(i,:) 1-nansum(P(i,:))];
                [sort_prob,ind_prob] = sort(-prow);
                ind_prob(ind_prob==length(prow))=-1;
                
                obj.assignment_prob_ranks(i,:) = ind_prob(1:obj.ncandidates);
                obj.assignment_prob_probs(i,:) = -sort_prob(1:obj.ncandidates);
                
                det = find(obj.assignments(i,:));
                
                if(isempty(det))
                    assignment_det(i)=-1;
                else
                    assignment_det(i)=det;
                end
            end
            
            for i=1:size(P,1)
                ind_det_in_probs = find(assignment_det(i)==obj.assignment_prob_ranks(i,:));
                rest_indices = setdiff(1:obj.ncandidates, ind_det_in_probs);
                rest_indices = rest_indices(1:obj.ncandidates-1);
                ranks = obj.assignment_prob_ranks(i,:);
                
                obj.assignment_prob_ranks(i, 1) = assignment_det(i);
                obj.assignment_prob_ranks(i, 2:obj.ncandidates)= ranks(rest_indices);
            end

            obj.assignments = obj.assignments;
            obj.assignment_prob_ranks = obj.assignment_prob_ranks;
            obj.assignment_prob_probs = obj.assignment_prob_probs;
            
        end
        
        function id(obj,file,im,worm)
            
            % We don't have age-specific atlases yet. For now, use the
            % hermaphrodite ID model to approximate anything younger adult.
            sex = lower(worm.sex);
            body = lower(worm.body);
            if ~contains(lower(worm.age), 'adult')
                worm.sex = 'XX';
                sex = lower(worm.sex);
            end
            
            % Set the atlas version.
            im.atlas_version = obj.atlas_version.(sex);
            
            % Get the model info.
            model = obj.atlas.(sex).(body).model;
            neurons = obj.atlas.(sex).(body).N;
            
            % neurons that are already annotated
            annotations = im.get_annotations();
            annotation_confidences = im.get_annotation_confidences();
            is_emphasized = im.get_is_emphasized();
            [annotations{annotation_confidences<=0.5 & is_emphasized}] = deal('');
            
            % find the annotated neurons
            nempty_annotations = find(cellfun(@(x) ~isempty(x), annotations));
            annotated = zeros(length(nempty_annotations), 2);
            annotated(:,1) = nempty_annotations;
            
            % find the annotated neurons in the atlas
            atlas_annotations = cellfun(@(x) ...
                find(strcmp(neurons,x)), ...
                annotations(annotated(:,1)), 'UniformOutput', false);
            
            % remove neurons that are not in the atlas
            remove_i = cellfun(@isempty, atlas_annotations);
            annotated(remove_i,:) = [];
            if ~isempty(~remove_i)
            	annotated(:,2) = [atlas_annotations{~remove_i}];
            end
            
            % read features of the current image
            colors = im.get_colors_readout();
            colors = colors(:,[1 2 3]);
            
            % Check that we have enough neurons.
            if size(colors,1) < 4
                warning('Number of neurons is not enough for AutoID, please detect at least 4 neurons.');
                return;
            end
            
            % Check if we have an atlas for this body part.
            sex_atlas = obj.atlas.(sex);
            if ~isfield(sex_atlas, body)
                error(['No atlas for "' worm.body '". Cannot ID neurons.']);
            end
            
            % align the image to statistical atlas
            aligned = obj.global_alignment(file, colors, ...
                im.get_positions().*im.scale, model, annotated);  
            for neuron=1:length(im.neurons)
                im.neurons(neuron).aligned_xyzRGB = aligned(neuron,:);
            end
            
            % update the log likelihood
            obj.update_log_likelihood(im,worm);
            
            % compute probabilistic/deterministic assignments
            obj.compute_assignments();
            
            % convert the assignments to names and update the information
            % in the image
            obj.add_to_image(im,worm);
        end
        
        function update_id(obj, im, worm)
            % update_auto_id changes the properties of auto_id given human has given 
            % the identity neuron to the neuron_i-th neuron (with the mp order).
            % it also updates the image object accordingly.
            
            % Update the log likelihood.
            obj.update_log_likelihood(im, worm);
            
            obj.compute_assignments();
            
            % convert the assignments to names and update the information
            % in the image
            obj.add_to_image(im,worm);
        end
        
        function update_confidences(obj, im, worm)
            % update_confidences updates the confidence calculations of
            % each manually annotated neuron, according to current
            % alignments
            
            model = obj.atlas.(lower(worm.sex)).(lower(worm.body)).model;
            neurons =  obj.atlas.(lower(worm.sex)).(lower(worm.body)).N;
            aligned = im.get_aligned_xyzRGBs();
            
            % Are the neurons aligned?
            if isempty(aligned)
                return;
            end
           
            for neuron=1:length(im.neurons)
                im.neurons(neuron).aligned_xyzRGB = aligned(neuron,:);
                
                if(~isempty(im.neurons(neuron).annotation))
                    neuron_index = find(strcmp(neurons, im.neurons(neuron).annotation));
                    if(~isempty(neuron_index))
                        
                        mu = model.mu(neuron_index,:);
                        sigma = squeeze(model.sigma(:,:,neuron_index));
                        im.neurons(neuron).outlier = Methods.find_outlier(aligned(neuron,:), mu, sigma);
                        
                    end
                end
            end
            
            
        end
        
        
        
        function aligned = global_alignment(obj, file, col, pos, model, annotated)
        % Global alignment based on search in the theta space
        %
        % Amin & Erdem
        
            import Methods.AutoId;
            
            % Do we have the parallelization toolbox?
            is_parallel = true;
            parallel_tb = ver('parallel');
            if isempty(parallel_tb)
                is_parallel = false;
            end
                                    
            % Setup the progress bar.
            % Note: windows wants the interpreter off from the beginning.
            wait_title = 'ID''ing Neurons';
            wb = waitbar(0, 'Initializing ...', 'Name', wait_title);
            wb.Children.Title.Interpreter = 'none';
            waitbar(0, wb, {file, 'Initializing ...'}, 'Name', wait_title);
            
            % Initialize the alignment.
            cost = nan(2*length(AutoId.theta),1);
            colors = cell(2*length(AutoId.theta),1);
            positions = cell(2*length(AutoId.theta),1);
            
            % Compute the alignment.
            num_tests = 2*length(AutoId.theta);

            for idx = 1:length(AutoId.theta)
                if is_parallel
                    
                    % Start the parallel pool.
                    if isempty(obj.pool) || ~isvalid(obj.pool) || ~obj.pool.Connected
                        obj.pool = parpool('threads');
                    end
                    
                    % Allocate memory.
                    %f = parallel.FevalFuture.empty(2*length(AutoId.theta),0);
                    
                    % Compute the alignment.
                    f(idx) = parfeval(obj.pool, @AutoId.local_alignment, ...
                        3, col, pos, model, AutoId.theta(idx), +1, annotated);
                    f(length(AutoId.theta) + idx) = ...
                        parfeval(obj.pool, @AutoId.local_alignment, ...
                        3, col, pos, model, AutoId.theta(idx), -1, annotated);
                else
                    
                    % Compute the alignment.
                    [colors{idx},positions{idx},cost(idx)] = ...
                        AutoId.local_alignment(col, pos, model, AutoId.theta(idx), +1, annotated);
                    idx_off = idx + length(AutoId.theta);
                    [colors{idx_off},positions{idx_off},cost(idx_off)] = ...
                        AutoId.local_alignment(col, pos, model, AutoId.theta(idx), -1, annotated);
                    
                    % Update the progress.
                    try
                        waitbar((2*idx)/num_tests, wb, {file, ...
                            [num2str(round((100.0*2*idx)/num_tests)),'%']}, ...
                            'Name', wait_title);
                    catch
                        break;
                    end
                end
            end
            
            % Wait for the computations to complete.
            if is_parallel
                for idx=1:2*length(AutoId.theta)
                    [job_idx,col_f,pos_f,cost_f] = fetchNext(f);
                    
                    positions{job_idx}  = pos_f;
                    colors{job_idx}     = col_f;
                    cost(job_idx)       = cost_f;
                    try
                        waitbar(idx/num_tests,wb, {file, ...
                            [num2str(round((100.0*idx/num_tests))),'%']}, ...
                            'Name', wait_title);
                    catch
                        break;
                    end
                end
            end
            
            % Terminate the existing parallel session.
            delete(gcp('nocreate'));
            
            % Done.
            try
                close(wb);
            catch
                warning('Auto ID is canceled.');
            end
            
            % Find the best alignment.
            [theta_idx] = find(cost==min(cost(:)));
            pos = positions{theta_idx};
            col = colors{theta_idx};
            
            aligned = [pos col];
        end
        
        function update_log_likelihood(obj, im, worm)
            % read the model and aligned information
            model = obj.atlas.(lower(worm.sex)).(lower(worm.body)).model;
            neurons = obj.atlas.(lower(worm.sex)).(lower(worm.body)).N;
            aligned = im.get_aligned_xyzRGBs();
            
            % the case where new neurons added without running AutoID
            if size(aligned,1) < length(im.neurons) && ~isempty(aligned)
                % read out the index of the aligned neurons
                is_aligned = arrayfun(@(x) ~isempty(x.aligned_xyzRGB), im.neurons);
                
                % read out colors and positions for all neurons
                col = im.get_colors_readout(); col = col(:,[1 2 3]);
                pos = im.get_positions().*im.scale;
                
                % get the colors and positions of aligned subset
                col_aligned = col(is_aligned,:);
                pos_aligned = pos(is_aligned,:);
                
                % compute the transformation between aligned and
                % non-aligned from aligned subset
                beta = linsolve([pos_aligned col_aligned ones(size(pos_aligned,1),1)], ...
                                [aligned ones(size(pos_aligned,1),1)]);
                            
                % transform all the points based on the recovered
                % transformation
                aligned = [pos col ones(size(pos,1),1)]*beta;
                aligned = aligned(:,1:6);
                
                % write the aligned information into neurons
                for neuron=1:length(im.neurons)
                    im.neurons(neuron).aligned_xyzRGB = aligned(neuron,:);
                end
            elseif isempty(aligned)
                col = im.get_colors_readout(); col = col(:,[1 2 3]);
                pos = im.get_positions().*im.scale;
                aligned = [pos col];
            end
            
            % find the already annotated neurons
            annotations = im.get_annotations();
            annotation_confidences = im.get_annotation_confidences();
            is_emphasized = im.get_is_emphasized();
            [annotations{annotation_confidences<=0.5 & is_emphasized}] = deal('');
            
            % find the annotated neurons
            annotated = [];
            annotated(:,1) = find(cellfun(@(x) ~isempty(x), annotations));
            
            % find the annotated neurons in the atlas
            atlas_annotations = cellfun(@(x) ...
                find(strcmp(neurons,x)), annotations(annotated(:,1)), ...
                'UniformOutput', false);
            
            % remove neurons that are not in the atlas
            remove_i = cellfun(@isempty, atlas_annotations);
            annotated(remove_i,:) = [];
            if ~isempty(~remove_i)
                annotated(:,2) =  [atlas_annotations{~remove_i}];
            end
            
            % update the log likelihood based on Mahalanobis distance
            obj.log_likelihood = -Methods.AutoId.pdist2_maha(aligned, model.mu, model.sigma);
            
            % set the likelihood of annotated neurons to MIN_LL and the nan
            % ones to MAX_LL
            obj.log_likelihood(annotated(:,1),:)= Methods.AutoId.min_log_likelihood;
            for i=1:size(annotated,1)
                obj.log_likelihood(annotated(i,1),annotated(i,2))= Methods.AutoId.max_log_likelihood;
            end
            
        end
        
        function visualize(obj,im,worm,varargin)
            if ~any(strcmp(varargin,'ax'))
                clf; hold on;
                set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);
            end
            
            % We don't have age-specific atlases yet. For now, use the
            % hermaphrodite ID model to approximate anything younger adult.
            sex = lower(worm.sex);
            body = lower(worm.body);
            if ~contains(lower(worm.age), 'adult')
                worm.sex = 'XX';
                sex = lower(worm.sex);
            end
            
            % original data
            model = obj.atlas.(sex).(body).model;
            neurons = obj.atlas.(sex).(body).N;
            col = im.get_colors_readout(); col = col(:,[1 2 3]);
            pos = im.get_positions().*im.scale;
            det_ids = im.get_deterministic_ids();
            
            % aligned data
            % CHECK ME!!! THIS ASSUMES ALL NEURONS ARE ALIGNED!!!
            aligned = im.get_aligned_xyzRGBs();
            if isempty(aligned)
                return;
            end
            
            
            % reduce rank to match aligned
            % CHECKING ALIGNED HERE, WE'RE GOOD!!!
            if size(aligned,1) < size(col,1)
                is_aligned = arrayfun(@(x) ~isempty(x.aligned_xyzRGB), im.neurons);
                col = col(is_aligned,:);
                pos = pos(is_aligned,:);
                det_ids = det_ids(is_aligned);
            end
            
            % find transformation between original and aligned data
            beta_pos = linsolve([aligned(:,1:3) ones(size(pos,1),1)],[pos ones(size(pos,1),1)]);
            beta_col = linsolve([aligned(:,4:end) ones(size(pos,1),1)],[col ones(size(pos,1),1)]);
            
            % move atlas based on the transformation
            model.mu(:,1:3) = [model.mu(:,1:3) ones(size(model.mu,1),1)]*beta_pos(:,1:3);
            model.mu(:,4:end) = [model.mu(:,4:end) ones(size(model.mu,1),1)]*beta_col(:,1:end-1);
            for i=1:size(model.sigma,3)
                model.sigma([1 2 3],[1 2 3],i) = beta_pos(1:3,1:3)'*model.sigma([1 2 3],[1 2 3],i)* beta_pos(1:3,1:3);
            end
            
                        
            % plot the result
            atlas_color = model.mu(:, [4 5 6]); atlas_color = (atlas_color)./(max(atlas_color));
            sizes = arrayfun(@(i) mean(eig(model.sigma([1,2,3],[1,2,3],i))), 1:size(model.sigma,3));
            sizes = 1000*sizes/max(sizes);
            
            if ~any(strcmp(varargin,'ax'))
                scatter3(model.mu(:,1),model.mu(:,2),model.mu(:,3), sizes, atlas_color, 'o', 'LineWidth', 3);
                text(model.mu(:,1),model.mu(:,2),model.mu(:,3), neurons, 'Color', 'r', 'fontsize', 10);
                scatter3(pos(:,1),pos(:,2),pos(:,3), 100, col./max(col), '.');
                text(pos(:,1),pos(:,2),pos(:,3), det_ids, 'Color', 'b', 'fontsize', 10);

                daspect([1,1,1]); grid on; set(gca,'color',[0.3,0.3,0.3]); view(-30,-20);
                drawnow;
            else
                ax = varargin{find(strcmp(varargin,'ax'))+1};
                z = varargin{find(strcmp(varargin,'z'))+1};
                
                mu_pixels = model.mu(:,1:3)./im.scale;
                current_z_indices = mu_pixels(:,3)>z-1.5 & mu_pixels(:,3)<z+1.5;
                scatter(ax,mu_pixels(current_z_indices,2),mu_pixels(current_z_indices,1),...
                    sizes(current_z_indices), atlas_color(current_z_indices,:), 'o', 'LineWidth', 3);
                text(ax,mu_pixels(current_z_indices,2),mu_pixels(current_z_indices,1),neurons(current_z_indices), 'Color', 'r');
                
            end
        end
    end
    
    methods(Access = private)
        
        % Hide the constructor.
        function AutoID(obj)
        end
    end
end

