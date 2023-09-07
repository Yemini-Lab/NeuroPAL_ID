function shearletIdxs = SLgetShearletIdxs2D(shearLevels,full,varargin)
%SLgetShearletIdxs2D Compute a index set describing a 2D shearlet system.
%
% Usage:    
%  
%   shearletIdxs = SLgetShearletIdxs2D(shearLevels)
%   shearletIdxs = SLgetShearletIdxs2D(shearLevels, full)
%   shearletIdxs = SLgetShearletIdxs2D(shearLevels, full, 'NameRestriction1', ValueRestriction1,...)
%
%Input:
%   
%        shearLevels: A 1D array, specifying the level of shearing on each scale. 
%                     Each entry of shearLevels has to be >= 0. A shear level of K
%                     means that the generating shearlet is sheared 2^K
%                     times in each direction for each cone. For
%                     example: If shearLevels = [1 1 2], the corresponding 
%                     shearlet system has a maximum redundancy of (2*(2*2^1
%                     + 1)) + (2*(2*2^1 + 1)) + (2*(2*2^2 + 1)) = 38
%                     (omitting the lowpass shearlet). Note
%                     that it is recommended not to use the full
%                     shearlet system but to omit shearlets lying on
%                     the border of the second cone as they are only
%                     slightly different from those on the border of
%                     the first cone.
%               full: Logical value that determines whether the indexes are computed
%                     for a full shearlet system or if shearlets lying on the border of
%                     the second cone are omitted. The default and recommended
%                     value is 0.
% 'TypeRestriction1': Possible restrictions: 'cones', 'scales',
%                     'shearings'.
%  ValueRestriction1: Numerical value or Array specifying a
%                     restriction. If the type of the restriction is
%                     'scales' the value 1:2 ensures that only indexes
%                     corresponding the shearlets on the first two
%                     scales are computed.
%
%Output:
%
% shearletIdxs: Nx3 matrix, where each row describes one shearlet in the
%               format [cone scale shearing].
%
%Example 1:
%
% %Compute the indexes, describing a 2D shearlet system with 3 scales
% shearletIdxs = SLgetShearletIdxs2D([1 1 2]);
% 
%Example 2:
%
% %Compute the subset of a shearlet system, containing only shearlets on
% %the first scale. 
% shearletSystem = SLgetShearletSystem2D(0,512,512,4);
% subsetIdxs = SLgetShearletIdxs2D(shearletSystem.shearLevels,shearletSystem.full,'scales',1);
% subsystem = SLgetSubsystem2D(shearletSystem,subsetIdxs);
%
%
%See also: SLgetShearletSystem2D, SLgetSubsystem2D

    if nargin < 1
        error('Not enough input parameters!');
    end
    if nargin < 2
        full = 0;
    end
    
    shearletIdxs = [];
    includeLowpass = 1;

    scales = 1:length(shearLevels);
    shearings = -2^(max(shearLevels)):2^(max(shearLevels));
    cones = 1:2;

    for i = 1:2:length(varargin)
        includeLowpass = 0;
        if strcmp(varargin{i},'scales')
            scales = varargin{i+1};
        elseif strcmp(varargin{i},'shearings')
            shearings = varargin{i+1}; 
        elseif strcmp(varargin{i},'cones')
            cones = varargin{i+1}; 
        end
    end

    for cone = intersect(1:2,cones)
        for scale = intersect(1:length(shearLevels),scales)
            for shearing = intersect(-2^shearLevels(scale):2^shearLevels(scale),shearings)
                if full || cone == 1 || abs(shearing) < 2^shearLevels(scale)
                    shearletIdxs = [shearletIdxs; [cone scale shearing]];
                end                        
            end
        end
    end
    if includeLowpass || ismember(0,scales) || ismember(0,cones)
        shearletIdxs = [shearletIdxs; [0 0 0]];
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
