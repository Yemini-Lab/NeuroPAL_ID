classdef MultiChannelVolume < types.core.NWBDataInterface & types.untyped.GroupClass
% MULTICHANNELVOLUME An extension of the base NWBData type to allow for multichannel volumetric images


% REQUIRED PROPERTIES
properties
    data; % REQUIRED (uint16) Volumetric multichannel data
    description; % REQUIRED (char) description of image
end
% OPTIONAL PROPERTIES
properties
    RGBW_channels; %  (int8) which channels in image map to RGBW
    imaging_volume; %  ImagingVolume
end

methods
    function obj = MultiChannelVolume(varargin)
        % MULTICHANNELVOLUME Constructor for MultiChannelVolume
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'RGBW_channels',[]);
        addParameter(p, 'data',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'imaging_volume',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.RGBW_channels = p.Results.RGBW_channels;
        obj.data = p.Results.data;
        obj.description = p.Results.description;
        obj.imaging_volume = p.Results.imaging_volume;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.MultiChannelVolume')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.RGBW_channels(obj, val)
        obj.RGBW_channels = obj.validate_RGBW_channels(val);
    end
    function set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.imaging_volume(obj, val)
        obj.imaging_volume = obj.validate_imaging_volume(val);
    end
    %% VALIDATORS
    
    function val = validate_RGBW_channels(obj, val)
        val = types.util.checkDtype('RGBW_channels', 'int8', val);
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
        validshapes = {[4]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'uint16', val);
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
        validshapes = {[Inf,Inf,Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
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
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_imaging_volume(obj, val)
        val = types.util.checkDtype('imaging_volume', 'types.ndx_multichannel_volume.ImagingVolume', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.RGBW_channels)
            if startsWith(class(obj.RGBW_channels), 'types.untyped.')
                refs = obj.RGBW_channels.export(fid, [fullpath '/RGBW_channels'], refs);
            elseif ~isempty(obj.RGBW_channels)
                io.writeDataset(fid, [fullpath '/RGBW_channels'], obj.RGBW_channels, 'forceArray');
            end
        end
        if startsWith(class(obj.data), 'types.untyped.')
            refs = obj.data.export(fid, [fullpath '/data'], refs);
        elseif ~isempty(obj.data)
            io.writeDataset(fid, [fullpath '/data'], obj.data, 'forceArray');
        end
        if startsWith(class(obj.description), 'types.untyped.')
            refs = obj.description.export(fid, [fullpath '/description'], refs);
        elseif ~isempty(obj.description)
            io.writeDataset(fid, [fullpath '/description'], obj.description);
        end
        refs = obj.imaging_volume.export(fid, [fullpath '/imaging_volume'], refs);
    end
end

end