function filters = SLprepareFilters2D(rows,cols,nScales,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2)
%SLprepareFilters2D Prepare wedge and bandpass filters for the computation of 2D shearlets.
%
%Usage: 
%
% filters = SLprepareFilters2D(rows, cols, nScales)
% filters = SLprepareFilters2D(rows, cols, nScales, shearLevels)
% filters = SLprepareFilters2D(rows, cols, nScales, shearLevels, directionalFilter)
% filters = SLprepareFilters2D(rows, cols, nScales, shearLevels, directionalFilter, quadratureMirrorFilter)
%
%Input:
%
%                   rows: Number of rows.
%                   cols: Number of columns.
%                nScales: Number of scales of the desired shearlet system.
%                         Has to be >= 1.
%            shearLevels: A 1xnScales sized array, specifying the level of
%                         shearing occuring on each scale. Each entry of
%                         shearLevels has to be >= 0. A shear level of K
%                         means that the generating shearlet is sheared 2^K
%                         times in each direction for each cone. For
%                         example: If nScales = 3 and shearLevels = [1 1
%                         2], the precomputed filters correspond to a
%                         shearlet system with a maximum number of (2*(2*2^1
%                         + 1)) + (2*(2*2^1 + 1)) + (2*(2*2^2 + 1)) = 38
%                         shearlets (omitting the lowpass shearlet and translation). Note
%                         that it is recommended not to use the full
%                         shearlet system but to omit shearlets lying on
%                         the border of the second cone as they are only
%                         slightly different from those on the border of
%                         the first cone.
%      directionalFilter: A 2D directional filter that serves as the basis
%                         of the directional 'component' of the shearlets.
%                         The default choice is modulate2(dfilters('dmaxflat4','d'),'c').
%                         For small sized inputs, or very large systems the
%                         default directional filter might be too large. In
%                         this case, it is recommended to use
%                         modulate2(dfilters('cd','d'),'c').
% quadratureMirrorFilter: A 1D quadrature mirror filter defining the
%                         wavelet 'component' of the shearlets. The default
%                         choice is [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,
%                         0.276348304703363,0.582566738241592,0.276348304703363,
%                         -0.0517766952966369,-0.0263483047033631,0.0104933261758408].
%                         Other QMF filters can be genereted with MakeONFilter.
%
%Output:
%   
% filters: A structure containing wedge and bandpass filters that can be used to 
%          compute 2D shearlets.
%                  
%Description:
%
% Based on the specified directional filter and quadrature mirror filter,
% 2D wedge and bandpass filters are computed that can be used to compute arbitrary 2D
% shearlets for data of size [rows cols] on nScales scales with as many
% shearings as specified by the shearLevels array.
%
%Example 1:
%
% %Prepare filters for a input of size 512x512 and a 4-scale shearlet system
% preparedFilters = SLprepareFilters2D(512,512,4);
% shearlets = SLgetShearlets2D(preparedFilters);
%
%Example 2:
%
% %Prepare filters for a input of size 512x512 and a 3-scale shearlet system
% %with 2^3 = 8 shearings in each direction for each cone on all 3 scales.
% preparedFilters = SLprepareFilters2D(512,512,3,[3 3 3]);
% shearlets = SLgetShearlets2D(preparedFilters);
%
%See also: SLgetShearletIdxs2D,SLgetShearlets2D,dfilters,MakeONFilter

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
[directionalFilter,scalingFilter,waveletFilter,scalingFilter2] = SLcheckFilterSizes(rows,cols,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2);
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
