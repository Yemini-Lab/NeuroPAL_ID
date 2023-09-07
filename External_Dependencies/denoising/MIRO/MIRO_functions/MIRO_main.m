%% First Step: FPN correction
disp('FPN correction...');
tic;
for i = 1:n_frames
    [fpn(:,:,i),Bias(i),Scale(i)] = MIRO_FPN_correction(im(:,:,i),Parameters);
end
toc;

%% Second Step: microlocal image processing

% Frequency Re-Weighting & Shearlet Thresholding
tic;
[a, fpn, ka, SNRa, Parameters] = MIRO_Spectral_weighting(fpn,Parameters);

if Parameters.Auto
    disp('\t resolution estimation...')
    f = Parameters.ResolutionCheckNFrames;
    if f > 0
        [res_b, SNRb] = ResolutionFinder(a(:,:,1:f));
    else
        [res_b, SNRb] = ResolutionFinder(a);
    end

    res_b = max(ka,res_b);
    SNRb = max(SNRa,SNRb);
    disp(['k: ' num2str(res_b)]);
    disp(['SNR : ' num2str(SNRb)]);

    QT = Parameters.Quality_threshold;
    Q = res_b >= QT(1) && SNRb >= QT(2);
    if Parameters.Auto && Q
        Parameters.OptionalFilter = 0;
    end
end

toc;
%% Third Step: non-local image processing (optional)
switch Parameters.OptionalFilter

    case 0
        b = a;
        map = [];

    case 1  % Non Local Means
        disp('Non-local image processing...')
        fprintf('\t Unbiased NLM filter\n');
        T = tic;

        Options_nlm.kernelratio = Parameters.KernelRatio;
        Options_nlm.windowratio = Parameters.WindowRatio;
        sigma_nlm = Parameters.LambdaNLM*sqrt(mean2(Parameters.Var));
        if Parameters.nlm_blocksize == 0
            Parameters.nlm_blocksize = max(size(a(:,:,1))) + ...
                2*Options_nlm.windowratio + 2*Options_nlm.kernelratio;
        end
        Options_nlm.blocksize = Parameters.nlm_blocksize;
        Options_nlm.verbose = Parameters.nlm_verbose;

        for i = 1:n_frames
            Options_nlm.filterstrength = sigma_nlm./Scale(i)*floor(max(a(:,:,i),[],'all'));
            b(:,:,i) = MIRO_nlm(a(:,:,i),Options_nlm);
        end
        toc(T);

    case 2  % Multiscale Wiener filter
        disp('Non-local image processing...')
        fprintf('\t Multiscale Wiener filter\n');
        tic;

        % Adjust Wiener parameters according to image SNR
        parameters_wien = Parameters.Wien;
        parameters_wien(3) = parameters_wien(3)*mean2(fpn)/SNRa;
        parameters_wien(9) = parameters_wien(9)*(1-SNRa^2)/SNRa^2;
        if ka < Parameters.kmin || ka > Parameters.kmax
            parameters_wien(9) = parameters_wien(9)/SNRa;
            parameters_wien(10) = 1;
        end

        Scale_a = ones(n_frames,1);
        for i = 1:n_frames

            Scale_a(i) = max(a(:,:,i),[],'all') - min(a(:,:,i),[],'all');
            parameters_wien(9) = parameters_wien(9)./Scale_a(i);
            [b(:,:,i), map(:,:,i)] = MIRO_Collaborative_Wiener_dct((fpn(:,:,i)),nrm(real(a(:,:,i).^.5)),...
                Transforms,Parameters.Var./Scale_a(i),parameters_wien); %#ok<*SAGROW>

            if Parameters.max_est_method == 0
                b(:,:,i) = imresize(map(:,:,i),size(b(:,:,i))).*b(:,:,i);
            else
                b(:,:,i) = Scale(i).*nrm(b(:,:,i)) + Bias(i);
            end

            b(:,:,i) = real(sqrt(b(:,:,i).*a(:,:,i))); % Geometric mean

        end

        toc;

    case 3  % Fast Wiener filter for Video data
        disp('Non-local image processing...')
        fprintf('\t Fast Wiener filter\n');
        T = tic;

        % Video processing
        Scale_a = max(a,[],'all') - min(a,[],'all');
        smp =  max(4,ceil(Parameters.Sampling));
        sgma = Parameters.LambdaVideo*mean2(a)./Scale_a;
        if n_frames<2
            b = MIRO_Fast_Wiener(nrm(fpn),nrm(a), 0.25*sgma, smp);
        else
            b = MIRO_Fast_Wiener_Video(nrm(fpn),nrm(a), sgma, smp); %#ok<*SAGROW>
        end
        sorted_values =sort(fpn(:),'descend');
        nValues = 10;
        Imax = mean(sorted_values(1:nValues));
        Imin = mean(sorted_values((end-nValues+1):end));
        Scale = Imax - Imin;
        Bias = Imin;
        b = Scale.*b + Bias;
        toc(T);

end

%% Unsharp masking (optional)

if Parameters.unsharp_masking_on
    disp('Unsharp masking')
    for i = 1:n_frames
        amount = .1/max(Parameters.smoothness,.1);
        amount = min(10/Parameters.Sampling,amount);
        b(:,:,i) = max(b(:,:,i),imsharpen(b(:,:,i),'Radius',1/ka,'Amount',amount,'Threshold',0));
    end
end

b(isnan(b)) = min(b,[],'all');
