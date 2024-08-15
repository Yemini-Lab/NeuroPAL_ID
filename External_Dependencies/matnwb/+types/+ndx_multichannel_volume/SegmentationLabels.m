classdef SegmentationLabels < types.core.NWBDataInterface & types.untyped.GroupClass
% SEGMENTATIONLABELS Segmentation labels


% REQUIRED PROPERTIES
properties
    description; % REQUIRED (char) description of what ROIs represent
    labels; % REQUIRED (char) ROI labels. Should be the same length as the number of ROIs
end
% OPTIONAL PROPERTIES
properties
    ImageSegmentation; %  ImageSegmentation
    MCVSegmentation; %  MultiChannelVolume
    MCVSeriesSegmentation; %  MultiChannelVolumeSeries
end

methods
    function obj = SegmentationLabels(varargin)
        % SEGMENTATIONLABELS Constructor for SegmentationLabels
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'ImageSegmentation',[]);
        addParameter(p, 'MCVSegmentation',[]);
        addParameter(p, 'MCVSeriesSegmentation',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'labels',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.ImageSegmentation = p.Results.ImageSegmentation;
        obj.MCVSegmentation = p.Results.MCVSegmentation;
        obj.MCVSeriesSegmentation = p.Results.MCVSeriesSegmentation;
        obj.description = p.Results.description;
        obj.labels = p.Results.labels;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.SegmentationLabels')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.ImageSegmentation(obj, val)
        obj.ImageSegmentation = obj.validate_ImageSegmentation(val);
    end
    function set.MCVSegmentation(obj, val)
        obj.MCVSegmentation = obj.validate_MCVSegmentation(val);
    end
    function set.MCVSeriesSegmentation(obj, val)
        obj.MCVSeriesSegmentation = obj.validate_MCVSeriesSegmentation(val);
    end
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.labels(obj, val)
        obj.labels = obj.validate_labels(val);
    end
    %% VALIDATORS
    
    function val = validate_ImageSegmentation(obj, val)
        val = types.util.checkDtype('ImageSegmentation', 'types.core.ImageSegmentation', val);
    end
    function val = validate_MCVSegmentation(obj, val)
        val = types.util.checkDtype('MCVSegmentation', 'types.ndx_multichannel_volume.MultiChannelVolume', val);
    end
    function val = validate_MCVSeriesSegmentation(obj, val)
        val = types.util.checkDtype('MCVSeriesSegmentation', 'types.ndx_multichannel_volume.MultiChannelVolumeSeries', val);
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
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.ImageSegmentation)
            refs = obj.ImageSegmentation.export(fid, [fullpath '/ImageSegmentation'], refs);
        end
        if ~isempty(obj.MCVSegmentation)
            refs = obj.MCVSegmentation.export(fid, [fullpath '/MCVSegmentation'], refs);
        end
        if ~isempty(obj.MCVSeriesSegmentation)
            refs = obj.MCVSeriesSegmentation.export(fid, [fullpath '/MCVSeriesSegmentation'], refs);
        end
        if startsWith(class(obj.description), 'types.untyped.')
            refs = obj.description.export(fid, [fullpath '/description'], refs);
        elseif ~isempty(obj.description)
            io.writeDataset(fid, [fullpath '/description'], obj.description);
        end
        if startsWith(class(obj.labels), 'types.untyped.')
            refs = obj.labels.export(fid, [fullpath '/labels'], refs);
        elseif ~isempty(obj.labels)
            io.writeDataset(fid, [fullpath '/labels'], obj.labels, 'forceArray');
        end
    end
end

end