classdef ImagingVolume < types.core.ImagingPlane & types.untyped.GroupClass
% IMAGINGVOLUME An Imaging Volume and its Metadata


% REQUIRED PROPERTIES
properties
    order_optical_channels; % REQUIRED (OpticalChannelReferences) Ordered list of names of the optical channels in the data
end
% OPTIONAL PROPERTIES
properties
    opticalchannelplus; %  (OpticalChannelPlus) An optical channel used to record from an imaging volume
end

methods
    function obj = ImagingVolume(varargin)
        % IMAGINGVOLUME Constructor for ImagingVolume
        obj = obj@types.core.ImagingPlane(varargin{:});
        [obj.opticalchannelplus, ivarargin] = types.util.parseConstrained(obj,'opticalchannelplus', 'types.ndx_multichannel_volume.OpticalChannelPlus', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'order_optical_channels',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.order_optical_channels = p.Results.order_optical_channels;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.ImagingVolume')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.opticalchannelplus(obj, val)
        obj.opticalchannelplus = obj.validate_opticalchannelplus(val);
    end
    function set.order_optical_channels(obj, val)
        obj.order_optical_channels = obj.validate_order_optical_channels(val);
    end
    %% VALIDATORS
    
    function val = validate_opticalchannelplus(obj, val)
        namedprops = struct();
        constrained = {'types.ndx_multichannel_volume.OpticalChannelPlus'};
        types.util.checkSet('opticalchannelplus', namedprops, constrained, val);
    end
    function val = validate_order_optical_channels(obj, val)
        val = types.util.checkDtype('order_optical_channels', 'types.ndx_multichannel_volume.OpticalChannelReferences', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        disp('types')
        disp(fullpath)
        disp(fid)
        disp(refs)
        refs = export@types.core.ImagingPlane(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.opticalchannelplus)
            refs = obj.opticalchannelplus.export(fid, fullpath, refs);
        end
        refs = obj.order_optical_channels.export(fid, [fullpath '/order_optical_channels'], refs);
    end
end

end