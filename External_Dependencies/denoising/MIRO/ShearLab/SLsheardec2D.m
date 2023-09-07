function coeffs = SLsheardec2D(X,shearletSystem)
%SLsheardec2D Shearlet decomposition of 2D data.
%
%Usage:
%
% coeffs = SLsheardec2D(X,shearletSystem);
%
%Input:
%
%              X: 2D data in time domain.
% shearletSystem: Structure containg a shearlet system. Such a system can
%                 be computed with SLgetShearletSystem2D or
%                 SLgetSubsystem2D.
%Output:
%
% coeffs: XxYxN array of the same size as the shearletSystem.shearlets array. coeffs contains all
%         shearlet coefficients, that is all inner products with the given data,
%         of all translates of the shearlets in the specified system. When constructing
%         shearlets with SLgetShearletSystem2D, each shearlet is centered in the 
%         time domain at floor(size(X)/2) + 1. Hence, the inner
%         product of X and the i-th shearlet in the time domain can be found at
%         coeffs(floor(size(X,1)/2) + 1,floor(size(X,2)/2) + 1,i). 
%
%Example:
%
% X = double(imread('barbara.jpg'));
% useGPU = 0;
% shearletSystem = SLgetShearletSystem2D(useGPU,size(X,1),size(X,2),4);
% coeffs = SLsheardec2D(X,shearletSystem);
%
%See also: SLgetShearletSystem2D, SLgetSubsystem2D, SLshearrec2D

    %% check input arguments
    if nargin < 2
        error('Not enough input parameters!');
    end
    
    if shearletSystem.useGPU
        if verLessThan('distcomp','6.1')
            coeffs = parallel.gpu.GPUArray.zeros(size(shearletSystem.shearlets));
        else
            coeffs = gpuArray.zeros(size(shearletSystem.shearlets));
        end            
    else
        coeffs = zeros(size(shearletSystem.shearlets));
    end
 
    %get data in frequency domain
    Xfreq = fftshift(fft2(ifftshift(X)));

    %compute shearlet coefficients at each scale
    %not that pointwise multiplication in the fourier domain equals convolution
    %in the time-domain
    for j = 1:shearletSystem.nShearlets
        coeffs(:,:,j) = fftshift(ifft2(ifftshift(Xfreq.*conj(shearletSystem.shearlets(:,:,j)))));        
    end
    
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
