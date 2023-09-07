function X = SLshearrec2D(coeffs, shearletSystem)
%SLshearrec2D 2D reconstruction of shearlet coefficients.
%
%Usage:
%
% X = SLshearrec2D(coeffs, shearletSystem);
%
%Input:
%               coeffs: XxYxN array of shearlet coefficients.
%       shearletSystem: Structure containing a shearlet system. This should be
%                       the same system as the one previously used for decomposition.
%
%Output:
%
% X: Reconstructed 2D data.
%
%Example:
%
% X = double(imread('barbara.jpg'));
% useGPU = 0;
% shearletSystem = SLgetShearletSystem2D(useGPU,size(X,1),size(X,2),4);
% coeffs = SLsheardec2D(X,shearletSystem);
% Xrec = SLshearrec2D(coeffs,shearletSystem);
%
%See also: SLgetShearlets2D,SLsheardec2D

    %% check input arguments
    if nargin < 2
        error('Not enough input parameters!');
    end
    
   
    %initialise reconstructed data
    if shearletSystem.useGPU
        if verLessThan('distcomp','6.1')
            X = parallel.gpu.GPUArray.zeros(size(coeffs,1),size(coeffs,2));
        else
            X = gpuArray.zeros(size(coeffs,1),size(coeffs,2));
        end
    else
        X = zeros(size(coeffs,1),size(coeffs,2));
    end

    for j = 1:shearletSystem.nShearlets
        X = X+fftshift(fft2(ifftshift(coeffs(:,:,j)))).*shearletSystem.shearlets(:,:,j);
    end
    X = fftshift(ifft2(ifftshift((1./shearletSystem.dualFrameWeights).*X)));
    
end

%
%  Copyright (c) 2014. Rafael Reisenhofer
%
%  Part of ShearLab3D v1.1
%  Built Mon, 10/11/2014
%  This is Copyrighted Material
%
%  If you use or mention this code in a publication please cite the website www.shearlab.org and the following paper:
%  G. Kutyniok, W.-Q. Lim, R. Reisenhofer
%  ShearLab 3D: Faithful Digital SHearlet Transforms Based on Compactly Supported Shearlets.
%  ACM Trans. Math. Software 42 (2016), Article No.: 5.
