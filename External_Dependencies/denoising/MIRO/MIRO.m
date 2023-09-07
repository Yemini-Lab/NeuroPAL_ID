%% MIRO main MATLAB script
% MIRO   Multiscale Image Restoration by Optimally-sparse representation
%
% SYNOPSIS:
%   [miro, Parameters, intr, fpn, im] = MIRO(im,PropertyName,PropertyValue)
%
% INPUTS:
%   im
%       Noisy image: variable name or file name (only .tif files). If left
%       void, the program opens a dialog from which is possible to select
%       the input file.
%
%   Properties:
%
%       CameraPixelSize 
%           Camera pixel size (in um)
%       Magnification
%           Optical magnification
%       NA 
%           Numerical Aperture
%       Lambda
%           Wavelength (in um)
%       Gain
%           Gain map of the Camera (in ADU/e-)
%       Offset
%           Map of the Camera offset (in ADU)
%       Var
%           Variance of the readout noise (rms^2)
%       DarkCurrent
%           Intensity of the dark current (in e-/s)
%       ExpTime
%           Exposure time (in s)
%       is3D
%           Process data as 3D stack
%       SliceInterval 
%           Axial sampling (in um)
%       SR_lateral
%           Improvement in lateral resolution over the diffraction limit
%           (use with super=resolution techniques, e.g. SIM)
%       SR_axial
%           Improvement in axial resolution over the diffraction limit
%           (use with super=resolution techniques, e.g. SIM)
%       DisplayImages        
%           Display Image Comparison
%       DisplayAnimation
%           Display Animated Image Comparison 
%       h 
%           Shearlet Thresholding parameter. Usually from 0.1 to 10, 
%           for more information see eq.(36) in the Supplementary Notes 
%       Mode 
%           Mode for microlocal Shearlet thresholding
%       shearletSystem 
%           Load a pre-calculated Shearlet system
%       OptionalFilter
%           Filter used in the last step: 0 (Non-local filtering off) 
%                                         1 (Unbiased Non-local Means) 
%                                         2 (Multiscale Wiener filtering)
%                                         3 (Fast Wiener filtering)
%       LambdaNLM 
%           NLM parameter
%       LambdaVideo 
%           Parameter for Fast Wiener filter
%       ResolutionCheck 
%           Perform Resolution Comparison
%       HS
%           Hot-spots correction
%       SpectralFilterOn
%           Enables the spectral filtering 
%       ResolutionCheckAuto% 
%           Enables resolution estimation, when turned off it assumes that 
%           the effective resolution is equal to the nominal resolution
%       k                 
%           spectral filter parameter. Usually between 0-1, for more 
%           information see eq.(40) in the Supplementary Notes
%
% OUTPUTS:
%   b
%       Denoised image
%   Parameters
%       Parameters used for image restoration
%   a
%       Intermediate image after second step
%   fpn
%       Intermediate image after first step
%   im
%       Noisy image (useful when loading the image directly from a file)
%
%
% (C) Copyright 2022                Biagio Mandracchia
%     All rights reserved
%
% Biagio Mandracchia, September 2022

function [b, Parameters, a, fpn, im] = MIRO(varargin)
%% Inizialization
disp('MIRO v1.0')

[im, Parameters, Transforms] = MIRO_parse_inputs(varargin); %#ok<ASGLU>

tStart = tic;
if Parameters.UserSelectedCancel
    b = []; a = []; fpn = []; map = [];
    return
end
warning ('off','all');
n_frames = size(im,3);
Bias = zeros(n_frames,1); %#ok<*NASGU> 
Scale = zeros(n_frames,1);
fpn = zeros(size(im));
a = zeros(size(im));
b = zeros(size(im));

%% Denoising
MIRO_main;

%% Runtime

elapsedTime = toc(tStart);
disp(' ');
disp(['Total runtime: ' num2str(elapsedTime) ' seconds'])
disp(' ');

%% Resolution check
if Parameters.ResolutionCheck
    disp('Resolution check...')

    [kim, ~] = ResolutionFinder(im(:,:,end));
    [kf, ~] = ResolutionFinder(b(:,:,end));
    kim = 2./kim.*Parameters.PixelSize;
    kf = 2./kf.*Parameters.PixelSize;

    fprintf('\nEffective resolution (um): \n');
    disp(['Input image: ' num2str(kim)]);
    disp(['Final image: ' num2str(kf)]);

    fprintf('\nResolution improvement: \n');
    Display_results_percentage(kim,kf);

end

%% Display images
if Parameters.DisplayImages
    figure;
    imagesc(cat(2,nrm(im(:,:,1)),nrm(b(:,:,1)))); 
    axis image; axis off
    title 'Input image    /    Final image'
    colormap hot    
end

if Parameters.DisplayAnimation
    animation = animated_comparison(nrm(im),nrm(b),50);
    figure('units','normalized','outerposition',[0 0 1 1])
    for i = 1:size(animation,3)
        imagesc(animation(:,:,i)); axis image; axis off; colormap hot
        pause(.1)
    end
end

warning ('on','all');

end