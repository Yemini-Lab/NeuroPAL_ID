function shearletSystem = MIRO_SLgetShearletSystem2D(useGPU, rows, cols, nScales, shearLevels, full, directionalFilter, quadratureMirrorFilter)
%% Compute the shearlet system

%%check input arguments
if nargin < 4
    error('Too few input arguments!');
end

if nargin < 8
    quadratureMirrorFilter = [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,...
        0.276348304703363,0.582566738241592,0.276348304703363,...
        -0.0517766952966369,-0.0263483047033631,0.0104933261758408];
    if nargin < 7
        directionalFilter = modulate2(dfilters('dmaxflat4','d')./sqrt(2),'c');
        if nargin < 6
            full = 0;
            if nargin < 5
                shearLevels = ceil((1:nScales)/2);
            end
        end
    end
end

if useGPU
    preparedFilters = SLfiltersToGPU2D(MIRO_SLprepareFilters2D(rows,cols,nScales,shearLevels,directionalFilter,quadratureMirrorFilter));
else
    preparedFilters = MIRO_SLprepareFilters2D(rows,cols,nScales,shearLevels,directionalFilter,quadratureMirrorFilter);
end
shearletIdxs = SLgetShearletIdxs2D(preparedFilters.shearLevels,full);
[shearlets, RMS, dualFrameWeights] = SLgetShearlets2D(preparedFilters,shearletIdxs);

%% create description
shearletSystem = struct('shearlets',shearlets,'size',preparedFilters.size,'shearLevels',preparedFilters.shearLevels,'full',full,'nShearlets',size(shearletIdxs,1),'shearletIdxs',shearletIdxs,'dualFrameWeights',dualFrameWeights,'RMS',RMS,'useGPU',useGPU,'isComplex',0);

end

%  Code adapted from ShearLab3D v1.1
%  Built Mon, 10/11/2014
%  Copyright (c) 2014. Rafael Reisenhofer
%
%  G. Kutyniok, W.-Q. Lim, R. Reisenhofer
%  ShearLab 3D: Faithful Digital SHearlet Transforms Based on Compactly Supported Shearlets.
%  ACM Trans. Math. Software 42 (2016), Article No.: 5.
