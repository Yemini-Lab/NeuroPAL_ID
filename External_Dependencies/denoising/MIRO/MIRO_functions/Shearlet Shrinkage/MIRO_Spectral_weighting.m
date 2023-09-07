% Frequency re-weighting

function [b, a, ka, SNRa, Parameters] = MIRO_Spectral_weighting(a,Parameters)%#codegen

kmin = Parameters.kmin;
Mode = Parameters.Mode;
h = Parameters.h;
spectral_filter_on = Parameters.SpectralFilterOn;
max_thr = max(round(Parameters.Sampling),1);
s = Parameters.k; % here we call this parameter s to avoid confusion with ka
max_scale  = Parameters.max_scale_factor;
sampling = Parameters.Sampling;
tophat = Parameters.tophat;
is3D = Parameters.is3D;
sigma_z = 2*Parameters.Lambda/(Parameters.NA^2)/Parameters.SliceInterval/Parameters.SR_axial;
var_shear = Parameters.Var;
n_frames = size(a,3);
pad = [10,10];


%% Resolution & SNR

R = min(1/sampling,.5);
T = min(2*R,.95);
disp('Global image processing...')
if Parameters.ResolutionCheckAuto
    ka = 0; niter=0; maxiter = 3;
    while ka <= kmin && niter <= maxiter
        fprintf('\t Resolution estimation...\n')
        f0 = Parameters.ResolutionCheckStartingFrame;
        f = Parameters.ResolutionCheckNFrames;
        if f > 0
            f0 = min(f0, n_frames);
            f1 = min(f0 + f, n_frames);
            [ka, SNRa] = ResolutionFinder(a(:,:,f0:f1));
        else
            [ka, SNRa] = ResolutionFinder(a);
        end
        fprintf(['\t Estimated k: ' num2str(ka) '\n'])
        fprintf(['\t Estimated SNR: ' num2str(SNRa) '\n'])
        
        if ka <= kmin
            %% Pre-processing
            fprintf('\t Too Low, pre-processing... \n')
            for i = 1:n_frames
                a(:,:,i) = MIRO_Hotspot2(a(:,:,i),SNRa,Parameters.Var);
            end
        end
        niter = niter+1;
    end
    
else
    ka = T;
    SNRa = 1;
    fprintf(['\t Estimated k: ' num2str(ka) '\n'])
    fprintf(['\t Estimated SNR: ' num2str(SNRa) '\n'])
end


r1 = ka/2*min(size(a(:,:,1))); % radius in Fourier space (effective resolution)
r2 = R*min(size(a(:,:,1))); % radius in Fourier space (maximum resolution)

%% Evaluation basic estimate
if spectral_filter_on
    fprintf('\t Spectral filtering \n')
    a = Spectral_filter(a,r1,r2,ka,T,s,Parameters.Sampling,pad,is3D,sigma_z);
end

b = a;

%% microlocal shearlet thresholding
disp('Microlocal image processing...')

b = padarray(b,pad,'replicate','both');
if size(var_shear,1) > 1
    var_shear = padarray(var_shear,pad,'replicate','both');
end

fprintf('\t Generating shearlet system...');
th = min(exp(1/SNRa),max_thr)*h;

if isempty(Parameters.shearletSystem) || ~isequal(Parameters.shearletSystem.size,size(b,[1 2]))
    
    scale_factor = min(floor(log2(min(size(b(:,:,1)))))-2,max_scale);
    scale_factor = max(scale_factor,1);
    
    Parameters.shearletSystem = MIRO_SLgetShearletSystem2D(0,size(b,1),size(b,2),scale_factor);
end
disp(['scale factor: ' num2str(length(Parameters.shearletSystem.shearLevels))])
fprintf('\t ')
switch Mode
    case 's'
        textprogressbar('Microlocal shearlet soft thresholding...');
    case 'h'
        textprogressbar('Microlocal shearlet hard thresholding...');
    otherwise
        Mode = 's';
        textprogressbar('Microlocal shearlet soft thresholding...');
end

for i = 1:n_frames
    
    textprogressbar((i-1)/n_frames*100);
    b(:,:,i) = MIRO_Shearlet_thresholding(b(:,:,i),var_shear,Parameters.shearletSystem,th,Mode,sampling,tophat);
    
end
textprogressbar(100);
textprogressbar(' ');
%%
b = removePad(b,pad);

end