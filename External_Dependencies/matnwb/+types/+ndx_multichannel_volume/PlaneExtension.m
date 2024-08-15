classdef PlaneExtension < types.core.PlaneSegmentation & types.untyped.GroupClass
% PLANEEXTENSION Results from image segmentation of a specific imaging volume



methods
    function obj = PlaneExtension(varargin)
        % PLANEEXTENSION Constructor for PlaneExtension
        obj = obj@types.core.PlaneSegmentation(varargin{:});
        if strcmp(class(obj), 'types.ndx_multichannel_volume.PlaneExtension')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.ndx_multichannel_volume.PlaneExtension')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.PlaneSegmentation(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end