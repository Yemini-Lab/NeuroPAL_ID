classdef OpticalChannelReferences < types.core.NWBDataInterface & types.untyped.GroupClass
% OPTICALCHANNELREFERENCES wrapper for optical channel references dataset


% REQUIRED PROPERTIES
properties
    channels; % REQUIRED (char) Ordered list of names of optical channels. Should refer to the names of the OpticalChannelPlus objects. ie. GCaMP, mNeptune, etc.
end

methods
    function obj = OpticalChannelReferences(varargin)
        % OPTICALCHANNELREFERENCES Constructor for OpticalChannelReferences
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'channels',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.channels = p.Results.channels;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.OpticalChannelReferences')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.channels(obj, val)
        obj.channels = obj.validate_channels(val);
    end
    %% VALIDATORS
    
    function val = validate_channels(obj, val)
        val = types.util.checkDtype('channels', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.channels), 'types.untyped.')
            refs = obj.channels.export(fid, [fullpath '/channels'], refs);
        elseif ~isempty(obj.channels)
            io.writeDataset(fid, [fullpath '/channels'], obj.channels, 'forceArray');
        end
    end
end

end