function filters = MIRO_SLprepareFilters2D(rows,cols,nScales,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2)
%% Prepare wedge and bandpass filters for the computation of 2D shearlets.

%%check input arguments
if nargin < 3
    error('Too few input arguments!');
end
if nargin < 8
    if nargin < 7
        if nargin < 6
            if nargin < 5
                if nargin < 4
                    shearLevels = ceil((1:nScales)/2);
                end
                
                directionalFilter = modulate2(dfilters('dmaxflat4','d')./sqrt(2),'c');
                
            end
            scalingFilter = [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,...
        0.276348304703363,0.582566738241592,0.276348304703363,...
        -0.0517766952966369,-0.0263483047033631,0.0104933261758408];            
        end
        waveletFilter = MirrorFilt(scalingFilter);
        
    end
    scalingFilter2 = scalingFilter;
    
end
[directionalFilter,scalingFilter,waveletFilter,scalingFilter2,shearLevels] = MIRO_SLcheckFilterSizes(rows,cols,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2);
filters = struct('size',[rows cols],'shearLevels',shearLevels,'cone1',[],'cone2',[],'useGPU',0);

filters.cone1 = struct('wedge',[],'bandpass',[],'lowpass',[]);
filters.cone2 = struct('wedge',[],'bandpass',[],'lowpass',[]);

[filters.cone1.wedge, filters.cone1.bandpass, filters.cone1.lowpass] = SLgetWedgeBandpassAndLowpassFilters2D(rows,cols,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2);
if rows==cols
    filters.cone2 = filters.cone1;
else
    [filters.cone2.wedge, filters.cone2.bandpass, filters.cone2.lowpass] = SLgetWedgeBandpassAndLowpassFilters2D(cols,rows,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2);
end
end

%  Code adapted from ShearLab3D v1.1
%  Built Mon, 10/11/2014
%  Copyright (c) 2014. Rafael Reisenhofer
%
%  G. Kutyniok, W.-Q. Lim, R. Reisenhofer
%  ShearLab 3D: Faithful Digital SHearlet Transforms Based on Compactly Supported Shearlets.
%  ACM Trans. Math. Software 42 (2016), Article No.: 5.
