classdef AutoDetect < handle
   
   properties % Public Access
        options = []
        supervoxels = []
        use_fmincon = true
        
        fsize
        szext
        
        scale
   end
   
   methods(Access=private)
      function obj = AutoDetect()
        has_fmincon = exist('fmincon', 'file') == 2;
        has_optimopts = exist('optimoptions', 'file') == 2;
        has_license = true;
        try
            has_license = license('test','Optimization_Toolbox');
        catch
            has_license = false;
        end

        obj.use_fmincon = has_fmincon && has_optimopts && has_license;
        if obj.use_fmincon
            obj.options = optimoptions('fmincon', 'Display', 'off');
            obj.options.MaxFunEvals = 5000;
            obj.options.MaxIter = 5000;
            obj.options.StepTolerance = 1e-10;
        else
            % Fall back to fminsearch with penalties if Optimization Toolbox is missing.
            obj.options = optimset('Display', 'off', 'MaxFunEvals', 5000, 'MaxIter', 5000);
        end
      end
   end
   
   methods(Static)
       function obj = instance()
           persistent instance
           if isempty(instance)
               obj = Methods.AutoDetect();
               instance = obj;
           else
               obj = instance;
           end
       end
       
       function BatchDetect(file, worm, num_neurons)
           %BATCHDETECT Batch detect neurons.
           
           % Setup the conversion progress bar.
           % Note: windows wants the interpreter off from the beginning.
           wait_title = 'Converting Image';
           wb = waitbar(0, 'Converting ...', 'Name', wait_title);
           wb.Children.Title.Interpreter = 'none';
           waitbar(0, wb, {file, 'Converting ...'}, 'Name', wait_title);
            
           % Open the image file.
           try
               [data, info, prefs, ~, mp, ~, np_file, id_file] = ...
                   DataHandling.NeuroPALImage.open(file);
           catch
               % For now, don't throw exceptions from threads.
               warning('Cannot read: "%s"', file);
               return;
           end
           
           % Done converting.
           try
               close(wb);
           catch
               warning('Image conversion was canceled.');
           end
           
           % Save the worm info.
           save(np_file, 'worm', '-append');
           
           % Setup the preprocessing progress bar.
           % Note: windows wants the interpreter off from the beginning.
           wait_title = 'Preprocessing Image';
           wb = waitbar(0, 'Preprocessing ...', 'Name', wait_title);
           wb.Children.Title.Interpreter = 'none';
           waitbar(0, wb, {file, 'Preprocessing ...'}, 'Name', wait_title);
           
           % Preprocess the colors.
           data_RGBW = double(data(:,:,:,prefs.RGBW(~isnan(prefs.RGBW))));
           data_zscored_raw = Methods.Preprocess.zscore_frame(double(data_RGBW));
           
           % Remove artifacts.
           [~, mask] = Methods.Preprocess.filter_gut_lysosomes(data_zscored_raw);
           mask = repmat(mask,1,1,1,length(prefs.RGBW(~isnan(prefs.RGBW))));
           data_zscored = data_zscored_raw;
           data_zscored(mask) = 0;
           
           % Done preprocessing.
           try
               close(wb);
           catch
               warning('Image preprocessing was canceled.');
           end
                      
           % Detect the neurons.
           mp.k = num_neurons;
           [sp, mp] = Methods.AutoDetect.instance().detect(file, data_zscored, ...
                mp.k, mp.min_eig_thresh, info.scale', worm, mp.exclusion_radius);
           
           % Save the neurons.
           version = Program.ProgramInfo.version;
           mp_params = mp;
           neurons = Neurons.Image(sp, worm.body, 'scale', info.scale');
           Methods.Utils.removeNearbyNeurons(neurons, 2, 2);
           save(id_file, 'version', 'neurons', 'mp_params');
       end
       
        function [c, ceq] = constrain_eigenvalues(x, lb, ub)
            % Nonlinear inequality constraints (eigenvalues) for fmincon.
            % Amin Nejat
           
           L = zeros(3, 3);
           L([1,2,3,5,6,9]) = x(4:9);
           variances = L*L';
           
           v = sort(eig(variances));
           c = -[v'-lb, ub-v'];
           
            ceq = [];
        end

        function val = penalized_cost(x, f, A_eq, b_eq, lb, ub, nonlcon, penalty_w)
            % Penalized objective for fminsearch fallback when fmincon is unavailable.
            val = f(x);

            if ~isempty(lb) && ~isempty(ub)
                low = lb - x;
                high = x - ub;
                if any(low > 0)
                    val = val + penalty_w * sum(low(low > 0).^2);
                end
                if any(high > 0)
                    val = val + penalty_w * sum(high(high > 0).^2);
                end
            end

            if ~isempty(A_eq)
                eq = A_eq * x' - b_eq;
                val = val + penalty_w * sum(eq(:).^2);
            end

            if ~isempty(nonlcon)
                try
                    [c, ceq] = nonlcon(x);
                catch
                    c = [];
                    ceq = [];
                end
                if ~isempty(c)
                    c_violation = c(c > 0);
                    if ~isempty(c_violation)
                        val = val + penalty_w * sum(c_violation.^2);
                    end
                end
                if ~isempty(ceq)
                    val = val + penalty_w * sum(ceq(:).^2);
                end
            end
        end
        
        function resid = gaussian_cost(x, vol, norm_factor)
        % Calculating residual between a multi-color Gaussian function and the
        % original image.
        %
        % Amin Nejat

            x = x./norm_factor';
            
            mu = x(1:3);
            L = zeros(3, 3); L([1,2,3,5,6,9]) = x(4:9); cov = L*L';

            props = x(12:size(vol,4) + 11)*exp(x(10));
            baseline = x(size(vol,4) + 12:end-1)*x(11);
            sz = size(vol);
            recon = Methods.Utils.simulate_gaussian(sz(1:3), mu', cov, props', baseline', x(end));
            
            resid = sqrt(sum((vol(:) - recon(:)).^2));
        end
        
        function [shape, recon, mu, cov, colors] = get_gaussian(x, sz, norm)
        % Creating Gaussian function for a given set of parameters, used for
        % visualization.
        %
        % Amin Nejat

            x = x./norm;

            mu = x(1:3);
            L = zeros(3, 3); L([1,2,3,5,6,9]) = x(4:9); cov = L*L';

            colors = x(12:sz(4)+11)*exp(x(10));
            recon = Methods.Utils.simulate_gaussian(sz(1:3), mu, cov, colors, zeros(1,sz(4)), x(end));
            shape = recon(:,:,:,1)/colors(1);
        end
        
        
        function filter = get_filter(sz, sigma_factor, trunc)
        % Creating a Gaussian filter 2D, 3D, or 4D for smoothing an image.
        %
        % Amin Nejat

            fmu = (sz+1)/2;
            fsigma = diag(sz)./sigma_factor;
            pos = [];
            [pos(:, 1), pos(:, 2), pos(:, 3)] = ind2sub(sz, find(ones(sz(1:3))));
            filt = reshape(mvnpdf(pos, fmu, fsigma), sz);
            filt(filt < prctile(filt(:), trunc)) = 0;

            filter = filt/sum(sqrt(filt(:).*filt(:)));
        end
        
        function eval = evaluation(image, volume, mp_params, centers, scale, precision)
        % Evaluation of the segmentation method, the output contains shape
        % based evaluation (correlation and MSE) in the reconstruction
        % field and location based evaluation (TP, FP, TN, FN, Accuracy,
        % Precision, Recall, F1) in the centeres field.
        % Amin Nejat
            
            eval = [];
            eval.params.mp_params = mp_params;
            eval.params.precision = precision;
            
            sz = size(volume);
            reconstruction = image.get_3d_shape(sz,mp_params.hnsz);

            vec = @(x) x(:);


            % reconstruction based            
            eval.recon.mse = nanmean(vec((reconstruction - volume).^2));
            correlation = corrcoef(vec(reconstruction), vec(volume));
            eval.recon.cor = correlation(1,2);

            % shape based
%             segmentation = image.get_3d_segments(sz,mp_params.hnsz);

            % location based

            eval.centers.tp = [];
            eval.centers.fp = [];
            eval.centers.tn = [];
            eval.centers.fn = [];

            eval.centers.accuracy = [];
            eval.centers.f1 = [];
            eval.centers.precision = [];
            eval.centers.recall = [];
            eval.centers.mean_closest_distance = [];
            eval.centers.assign = {};
            
            for i=1:size(image.get_positions(),1)
                positions = image.get_positions();
                positions = positions(1:i,:);

                distances = pdist2(positions.*scale(:)', centers.*scale(:)');
                distances(distances > precision) = Inf;

                if i == 1
                    tp = any(~isinf(distances));
                    assign = [];
                else
                    if all(isinf(distances(:)))
                        tp = 0;
                        assign = [];
                    else
                        [~,~,assign] = Methods.munkres(distances);
                        [~,cols] = find(assign);
                        tp = length(cols);
                    end
                end

                fn = size(centers,1)-tp;
                fp = size(positions,1)-tp;
                tn = 0;

                eval.centers.tp(end+1) = tp;
                eval.centers.fp(end+1) = fp;
                eval.centers.tn(end+1) = tn;
                eval.centers.fn(end+1) = fn;
                eval.centers.assign{end+1} = assign;

                eval.centers.accuracy(end+1) = (tp+tn)/(tp+fp+tn+fn);
                eval.centers.f1(end+1) = 2*tp/(2*tp+fp+fn);
                eval.centers.precision(end+1) = tp/(tp+fp);
                eval.centers.recall(end+1) = tp/(tp+fn);
                eval.centers.mean_closest_distance(end+1) = mean(min(pdist2(positions.*scale(:)', centers.*scale(:)')));
            end
        end
        
   end
   
   methods % Public Access
       
        function [supervoxels, params] = detect(obj, titlestr, volume, ...
                k, min_eig_thresh, scale, worm, exclusion_radius)
        % Matching pursuit algorithm for finding the best mixture of Gaussians that
        % fits to input dataset. The algorithm runs greedy by subtracting off the
        % brightest Gaussian at each iteration.
        %
        % INPUTS
        % ======
        % titlestr: a string that is shown in the progress bar
        % volume: 4D image array (x,y,z,c), doesn't need to be z-scored
        % k: number of objects that the algorithm finds
        % min_eig_thresh (in microns): if the minimum eigenvalue of the
        %   covariance of an object is less than this the object will be
        %   removed in the procedure but is not accepted as a neuron
        % scale (micron per pixel): scaling between image and micron spaces
        % exclusion_radius (in microns): no pair of objects can have distances
        %   less that the exclusion
        %
        % OUTPUTS
        % =======
        % supervoxels: struct containing the locations (positions), shape
        %   parameters (covariances), colors (colors), basline color
        %   (baseline), truncation values (trunc), and readout color from
        %   the image (color_readout)
        % params: struct contining the parameters chosen for running the
        %   algorithm; parameters are half size of a neuron in microns
        %   (hnsz), number of objects (k), threshold for minimum eigenvalue
        %   (min_eig_thresh), exclusion radius (exclusion_radius)
        %
        % Amin Nejat
        
        % Setup the progress bar.
        wait_title = 'Detecting Neurons';
        wb = waitbar(0, {titlestr, 'Initializing ...'}, 'Name', wait_title);
        wb.Children.Title.Interpreter = 'none';
        
        % Determine the neuron detection scale.
        detect_scale = 0.4;
        switch lower(worm.age)
            case {'3-fold', 'l1'}
                detect_scale = 0.2;
            case 'l2'
                detect_scale = 0.25;
            case 'l3'
                detect_scale = 0.3;
            case 'l4'
                detect_scale = 0.35;
            case 'adult'
                detect_scale = 0.4;
        end
        
        % Do NOT upsample images.
        detect_scale = max(detect_scale, min(scale));
        
        % Initialize the image size info.
        obj.supervoxels = [];
        sz = [size(volume), 1];
        spatial_factor = min(scale)/detect_scale;
        obj.scale = scale(:)'/spatial_factor;
        
        % Z-score & rescale the image.
        volume = Methods.Preprocess.zscore_frame(...
            Methods.Preprocess.decimate_frame(double(volume), ...
            round(sz(1:3)*spatial_factor), 'linear'));
        obj.szext = [size(volume), 1];
        
        % Determine the matching pursuit parameters.
        params                  = [];
        params.k                = k;
        params.detect_scale     = detect_scale;
        params.hnsz             = round(round(3./obj.scale(:)')/2)*2+1;
        params.min_eig_thresh   = min_eig_thresh; % microns
        params.exclusion_radius = exclusion_radius; % microns
                
        
        % Smooth the image using a Gaussian.
        filter = Methods.AutoDetect.get_filter(params.hnsz, params.hnsz, 0);
        obj.fsize = size(filter)-1;
        rho = Methods.Preprocess.filter_frame(volume, filter);
        % Detect the neurons.
        % Amin, we could use some comments here to explain what's happening.
        N = 0;
        while N < k
            try
                waitbar((N+1)/k,wb,...
                    {titlestr, ...
                    sprintf('%d%% completed ...', int16(100*(N+1)/k))}, ...
                    'Name', wait_title);
            catch
                break;
            end
            
            rho_mag = max(rho, [], 4);
            [~, lmidx] = max(rho_mag(:));
            [x,y,z] = ind2sub(size(rho_mag), lmidx);
            loc = [x,y,z];

            bpatch = Methods.Utils.subcube(volume, loc, obj.fsize);
            
            [shape, sp] = obj.fit_gaussian(bpatch, squeeze(rho(loc(1),loc(2),loc(3),:))', loc);
            
            fshape = imfilter(shape, filter, 'full');
            fresidual = Methods.Utils.placement(obj.szext(1:3), loc, fshape);
            
            for ch = 1: size(rho, 4)
                rho(:,:,:,ch) = rho(:,:,:,ch)-fresidual*sp.color(ch);
            end
            
            exclusion_condition = isempty(obj.supervoxels) || ...
                min(pdist2(obj.supervoxels.positions.*obj.scale, loc.*obj.scale)) > exclusion_radius;
            
            if min(eig(squeeze(sp.covariances).*obj.scale)) > min_eig_thresh && exclusion_condition
                cpatch = Methods.Utils.subcube(volume, round(sp.positions), [1,1,0]);
                sp.color_readout = median(reshape(cpatch, [numel(cpatch)/size(cpatch, 4), size(cpatch, 4)]));
                obj.supervoxels = Methods.Utils.union_sp(obj.supervoxels, sp);
            end
            if ~isempty(obj.supervoxels)
                N = size(obj.supervoxels.positions, 1);
            end
        end
        
        % Done.
        try
            close(wb);
        catch
            warning('The detection was canceled.');
        end
        
        % Store the detection results.
        obj.supervoxels.positions = obj.supervoxels.positions/spatial_factor;
        obj.supervoxels.covariances = obj.supervoxels.covariances/spatial_factor;
        supervoxels = obj.supervoxels;
        params.k = size(sp.color,1);
        end
        
        
        function [shape, sp] = fit_gaussian(obj, bpatch, colorvec, absolute_position)
            % Amin, desperately need comments to explain this method.
            
            norm = [obj.scale, ... % loc
                sqrt([obj.scale(1),1,1,obj.scale(2),1,obj.scale(3)]), ... % covariance parameters
                1, ... % color scale
                1, ... % noise scale
                ones(1, obj.szext(4)), ... % color
                ones(1, obj.szext(4)), ... % noise
                10000];
            
            eig_lb = [0.01,0.01,0.01];
            eig_ub = [5,5,5];
            
            
            nonlcon = @(x) Methods.AutoDetect.constrain_eigenvalues(x, eig_lb, eig_ub);
            
            colors = reshape(bpatch, [numel(bpatch)/size(bpatch, 4), size(bpatch, 4)]);
            colors(colors == 0) = eps;
            noisevec = prctile(colors, 10);
            
            colorvec(colorvec < 0) = eps;
            
            color_level = sum(colorvec(:));
            noise_level = abs(sum(noisevec(:)));
            
            colorvec = colorvec/color_level;
            noisevec = noisevec/noise_level;
            
            
            x0 =   double([(obj.fsize+1).*obj.scale, ... % loc
                sqrt([3,0,0,3,0,3]), ... % covariance parameters
                1.5*log(color_level), ... % color scale
                noise_level, ... % noise scale
                colorvec, ... % color
                noisevec, ... % noise
                0]);
            
            lb = [x0(1:3)-0.3*ones(1,3), zeros(1,6), 0, 0, zeros(1,obj.szext(4)), -ones(1,obj.szext(4)), 0];
            ub = [x0(1:3)+0.3*ones(1,3), 100*ones(1,6), 20, 0.1, ones(1,2*obj.szext(4)), 1000];
            
            
            A_eq = [zeros(1, 11), ones(1, obj.szext(4)), zeros(1, obj.szext(4)), 0; ...
                [zeros(1, 11), zeros(1, obj.szext(4)), ones(1, obj.szext(4)), 1]];
            b_eq = [1; 1];
            
            
            f = @(x) Methods.AutoDetect.gaussian_cost(x', bpatch, norm);
            if obj.use_fmincon
                x_hat = fmincon(f, x0, [], [], A_eq, b_eq, lb, ub, nonlcon, obj.options);
            else
                penalty_w = 1e6;
                penalized = @(x) Methods.AutoDetect.penalized_cost(x, f, A_eq, b_eq, lb, ub, nonlcon, penalty_w);
                x_hat = fminsearch(penalized, x0, obj.options);
            end
            
            [shape, ~, ~, cov, col] = Methods.AutoDetect.get_gaussian(x_hat, [2*obj.fsize+1, obj.szext(4)], norm);
            bas = x_hat(12+obj.szext(4):11+2*obj.szext(4))*x_hat(11);
            
            relative_position = (x_hat(1:3)-x0(1:3))./norm(1:3);
            
            sp.positions = relative_position+absolute_position;
            sp.covariances(1,:,:) = cov;
            sp.color = col;
            sp.baseline = bas;
            sp.truncation = x_hat(end)/norm(end);
        end
   end
end
