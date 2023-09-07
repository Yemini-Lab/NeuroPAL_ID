%% Default parameters

%% General parameters

Parameters.ResolutionCheck = 0;      % Perform Resolution Comparison
Parameters.DisplayImages = 0;        % Display Image Comparison
Parameters.DisplayAnimation = 0;     % Display Animated Image Comparison
Parameters.unsharp_masking_on = 0;   % Unsharp masking 
Parameters.Auto = 0;

% Filter used in the last step: 0 (Non-local filtering off) 
%                               1 (Unbiased Non-local Means) 
%                               2 (Multiscale Wiener filtering)
%                               3 (Video Wiener filtering)
Parameters.OptionalFilter = 0;     

%% Camera noise parameters
Parameters.Offset = 0;          %Offset (in ADU)
Parameters.Gain = 1;            %Gain (in ADU/e-)
Parameters.Var = 2.56;          %Variance of the readout noise (rms^2)
Parameters.DarkCurrent = 0.06;  %Intensity of the dark current (in e-/s)
Parameters.ExpTime = 0;         %Exposure time (in s)

%% Optical parameters
Parameters.CameraPixelSize = 6.5; %Camera pixel size (in um)
Parameters.Magnification = 100;   %optical magnification
Parameters.NA = 1.45;             %Numerical Aperture
Parameters.Lambda = 0.67;         %Wavelength (in um)
Parameters.Binning = 1;
Parameters.kmin = 0.1;            %Minimum Resolution (normalized)
Parameters.kmax = 1;              %Maximum Resolution (normalized)
Parameters.is3D = 0;              %Process data as 3D stack
Parameters.SliceInterval = 0.3;   %Axial sampling (in um)
Parameters.SR_lateral = 1;
Parameters.SR_axial = 1;
    
%% FPN parameters
% Hot-spots correction
Parameters.HS = 5;  

%% Spectral weighting parameters
% this enables the spectral filtering 
Parameters.SpectralFilterOn = 1;  
% Enables resolution estimation, when turned off it assumes that the
% effective resolution is equal to the nominal resolution
Parameters.ResolutionCheckAuto = 1;
% # of frames used for resolution estimation, if 0 all frames are used
Parameters.ResolutionCheckNFrames = 1; 
Parameters.ResolutionCheckStartingFrame = 1;
Parameters.k = 0.25;                % 0-1, for more information see eq.(40) in the Supplementary Notes

%% Shearlet soft Thresholding
Parameters.h = 1;                   % usually from 0.1 to 10, for more information see eq.(36) in the Supplementary Notes 
Parameters.Mode = 's';              % Mode for microlocal Shearlet thresholding
Parameters.SNRmin = .1;             % Minimum input SNR (normalized)
Parameters.max_scale_factor = 6;    % from 1 to Inf
Parameters.shearletSystem = [];     % shearletSystem = SLgetShearletSystem2D(0,size(im,1)+2*pad_y,size(im,2)+2*pad_x,scale); by default pad_x = pad_y = 10.
Parameters.tophat = 0;              % tophat background correction

%% NLM parameters

Parameters.LambdaNLM = 0.5;
Parameters.KernelRatio = 1;         % may be changed with sampling
Parameters.WindowRatio = 5;
Parameters.nlm_verbose = 0;
% If nlm_blocksize>0, the image is split in sub-blocks of size nlm_blocksize
% for efficient memory usage, 
Parameters.nlm_blocksize = 0; 

%% Wiener parameters
Parameters.LambdaVideo = 1;
Parameters.Quality_threshold = [.4, .5]; % [k, SNR]
Parameters.Wien = [ ...
    8,...       Block Size
    2,...       Search Step
    .5,...      Match Threshold
    8,...       Maximum Number of Patches per Group (1-14)
    19,...      Size Search Window
    6,...       Block Size for Needle Patches
    6,...       Block Step
    .1,...      Beta for Wiener weights
    1,...       Lambda Wiener
    0];...      Adaptive Lambda
    