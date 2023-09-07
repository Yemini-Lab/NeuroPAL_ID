function preparedFiltersGPU = SLfiltersToGPU2D(preparedFilters)
%SLFILTERSTOGPU2D Transfer precomputed filters for the construction of 2D shearlets to the graphics card.
%
%Usage:
%
% preparedFiltersGPU = SLFILTERSTOGPU2D(preparedFilters)
%
%Input:
%
% preparedFilters: A structure containing filters that can be used to construct 2D shearlets.
%                  Such filters can be generated with SLprepareFilters2D.
%
%Output:
%
% preparedFiltersGPU: A copy of preparedFilters with all filters stored on
%                     the memory of the graphics card.
%
%Example:
%
% preparedFilters = SLprepareFilters2D(512,512,4);
% preparedFiltersGPU = SLfiltersToGPU2D(preparedFilters);
%
%See also: SLprepareFilters2D

    preparedFiltersGPU = preparedFilters;
    
    preparedFiltersGPU.cone1.bandpass = gpuArray(preparedFiltersGPU.cone1.bandpass);
    preparedFiltersGPU.cone1.lowpass = gpuArray(preparedFiltersGPU.cone1.lowpass);
    preparedFiltersGPU.cone2.bandpass = gpuArray(preparedFiltersGPU.cone2.bandpass);
    preparedFiltersGPU.cone2.lowpass = gpuArray(preparedFiltersGPU.cone2.lowpass);
    
    for i = 1:length(preparedFiltersGPU.cone1.wedge)
        preparedFiltersGPU.cone1.wedge{i} = gpuArray(preparedFiltersGPU.cone1.wedge{i});
        preparedFiltersGPU.cone2.wedge{i} = gpuArray(preparedFiltersGPU.cone2.wedge{i});
    end
    
    preparedFiltersGPU.useGPU = 1;
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

