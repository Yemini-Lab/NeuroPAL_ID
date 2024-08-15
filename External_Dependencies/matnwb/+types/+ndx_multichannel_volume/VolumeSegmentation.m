classdef VolumeSegmentation < types.core.PlaneSegmentation & types.untyped.GroupClass
% VOLUMESEGMENTATION Results from image segmentation of a specific imaging volume


% OPTIONAL PROPERTIES
properties
    color_voxel_mask; %  (VectorData) Voxel masks for each ROI including RGBW color values for each pixel
    imaging_volume; %  ImagingVolume
    labels; %  (char) Ordered list of labels for ROIs
end

methods
    function obj = VolumeSegmentation(varargin)
        % VOLUMESEGMENTATION Constructor for VolumeSegmentation
        obj = obj@types.core.PlaneSegmentation(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'color_voxel_mask',[]);
        addParameter(p, 'imaging_volume',[]);
        addParameter(p, 'labels',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.color_voxel_mask = p.Results.color_voxel_mask;
        obj.imaging_volume = p.Results.imaging_volume;
        obj.labels = p.Results.labels;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.VolumeSegmentation')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.ndx_multichannel_volume.VolumeSegmentation')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.color_voxel_mask(obj, val)
        obj.color_voxel_mask = obj.validate_color_voxel_mask(val);
    end
    function set.imaging_volume(obj, val)
        obj.imaging_volume = obj.validate_imaging_volume(val);
    end
    function set.labels(obj, val)
        obj.labels = obj.validate_labels(val);
    end
    %% VALIDATORS
    
    function val = validate_color_voxel_mask(obj, val)
        val = types.util.checkDtype('color_voxel_mask', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_imaging_volume(obj, val)
        val = types.util.checkDtype('imaging_volume', 'types.ndx_multichannel_volume.ImagingVolume', val);
    end
    function val = validate_labels(obj, val)
        val = types.util.checkDtype('labels', 'char', val);
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
        refs = export@types.core.PlaneSegmentation(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.color_voxel_mask)
            refs = obj.color_voxel_mask.export(fid, [fullpath '/color_voxel_mask'], refs);
        end
        refs = obj.imaging_volume.export(fid, [fullpath '/imaging_volume'], refs);
        if ~isempty(obj.labels)
            if startsWith(class(obj.labels), 'types.untyped.')
                refs = obj.labels.export(fid, [fullpath '/labels'], refs);
            elseif ~isempty(obj.labels)
                io.writeDataset(fid, [fullpath '/labels'], obj.labels, 'forceArray');
            end
        end
    end
end

end