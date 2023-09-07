function [shearlets, RMS, dualFrameWeights] = SLgetShearlets2D(preparedFilters,shearletIdxs)
%SLgetShearlets2D Compute 2D shearlets in the frequency domain.
%
%Usage: 
%
% [shearlets, RMS, dualFrameWeights] = SLgetShearlets2D(preparedFilters)
% [shearlets, RMS, dualFrameWeights] = SLgetShearlets2D(preparedFilters, shearletIdxs)
%
%Input:
% 
% preparedFilters: A structure containing filters that can be used to compute 2D shearlets.
%                  Such filters can be generated with SLprepareFilters2D.
%   shearletdIdxs: A Nx3 array, specifying each shearlet that is to be
%                  computed in the format [cone scale shearing] where N
%                  denotes the number of shearlets. The vertical cone in time 
%                  domain is indexed by 1 while the horizontal cone is indexed by 2.
%                  Note that the values for scale and shearing are limited by 
%                  the precomputed filters. The lowpass shearlet is indexed by 
%                  [0 0 0].If no shearlet indexes are specified, SLgetShearlets2D 
%                  returns a standard shearlet system based on the precomputed filters.
%                  Such a standard index set can also be obtained by
%                  calling SLgetShearletIdxs2D.
%
%Output:
%
%         shearlets: A XxYxN array of N 2D shearlets in the frequency domain where X and Y   
%                    denote the size of each shearlet.
%               RMS: A 1xN array containing the root mean
%                    squares (L2-norm divided by sqrt(X*Y)) of all shearlets stored in
%                    shearlets. These values can be used to normalize 
%                    shearlet coefficients to make them comparable.
%  dualFrameWeights: A XxY matrix containing the absolute and squared sum over all shearlets
%                    stored in shearlets. These weights are needed to compute the dual frame during
%                    reconstruction.
%
%Description:
%
% The wedge and bandpass filters in preparedFilters are used to compute
% shearlets on different scales and of different shearings, as specified by
% the shearletIdxs array. Shearlets are computed in the frequency domain.
% To get the i-th shearlet in the time domain, use
% fftshift(ifft2(ifftshift(shearlets(:,:,i)))).
%
% Each Shearlet is centered at floor([X Y]/2) + 1.
%
%Example 1:
% 
% %compute the lowpass shearlet
% preparedFilters = SLprepareFilters2D(512,512,4,[1 1 2 2]);
% lowpassShearlet = SLgetShearlets2D(preparedFilters,[0 0 0]);
% lowpassShearletTimeDomain = fftshift(ifft2(ifftshift(lowpassShearlet)));
%
%Example 2:
%
% %compute a standard shearlet system of four scales
% preparedFilters = SLprepareFilters2D(512,512,4);
% shearlets = SLgetShearlets2D(preparedFilters);
%
%Example 3:
%
% %compute a full shearlet system of four scales
% preparedFilters = SLprepareFilters2D(512,512,4);
% shearlets = SLgetShearlets2D(preparedFilters,SLgetShearletIdxs2D(preparedFilters.shearLevels,1));
%
%See also: SLprepareFilters2D, SLgetShearletIdxs2D, SLsheardec2D,
%          SLshearrec2D

    %% check input arguments
    if nargin < 1
        error('Too few input arguments!');
    end;
    if nargin < 2
        shearletIdxs = SLgetShearletIdxs2D(preparedFilters.shearLevels);
    end
    
    useGPU = preparedFilters.useGPU;

    rows = preparedFilters.size(1);
    cols = preparedFilters.size(2);
    nShearlets = size(shearletIdxs,1);

    %allocate shearlets
    if useGPU
        if verLessThan('distcomp','6.1')
            shearlets = parallel.gpu.GPUArray.zeros(rows, cols, nShearlets);
        else
            shearlets = gpuArray.zeros(rows, cols, nShearlets);
        end
    else
        shearlets = zeros(rows, cols, nShearlets);
    end
    %% compute shearlets
    for j = 1:nShearlets
        cone = shearletIdxs(j,1);
        scale = shearletIdxs(j,2);    
        shearing = shearletIdxs(j,3);    
        if cone == 0
            shearlets(:,:,j) = preparedFilters.cone1.lowpass;
        elseif cone == 1
            %here, the fft of the digital shearlet filters described in
            %equation (23) on page 15 of "ShearLab 3D: Faithful Digital
            %Shearlet Transforms based on Compactly Supported Shearlets" is computed.
            %for more details on the construction of the wedge and bandpass
            %filters, please refer to SLgetWedgeBandpassAndLowpassFilters2D.
            shearlets(:,:,j) = preparedFilters.cone1.wedge{preparedFilters.shearLevels(scale)+1}(:,:,-shearing+2^preparedFilters.shearLevels(scale)+1).*conj(preparedFilters.cone1.bandpass(:,:,scale));
        else
            shearlets(:,:,j) = permute(preparedFilters.cone2.wedge{preparedFilters.shearLevels(scale)+1}(:,:,shearing+2^preparedFilters.shearLevels(scale)+1).*conj(preparedFilters.cone2.bandpass(:,:,scale)),[2 1]);
        end
    end
    if nargout > 1
        RMS = squeeze(sqrt(sum(sum(abs(shearlets).^2)))/sqrt(rows*cols))';
        if nargout > 2
            dualFrameWeights = sum(abs(shearlets).^2,3);
        end
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
