classdef MultiChannelVolumeSeries < types.core.TimeSeries & types.untyped.GroupClass
% MULTICHANNELVOLUMESERIES Image series of volumetric data with multiple channels


% REQUIRED PROPERTIES
properties
    dimension; % REQUIRED (int32) Number of pixels on x, y, and z axes
end
% OPTIONAL PROPERTIES
properties
    binning; %  (uint8) Amount of pixels combined into bins; could be 1, 2, 4, 8, etc.
    device; %  Device
    exposure_time; %  (single) Exposure time of the sample, in seconds; often the inverse of the frequency.
    external_file; %  (char) Paths to one or more external file(s). Field is only present if format ='external'. This is only relevant if the image series is stored in the file system as one or more image file(s). This field should NOT be used if the image is stored in another NWB file and that file is linked to this file
    format; %  (char) Format of image. If this is 'external', then the attribute 'external_file' contains the path information to the image files. If this is 'raw', then the raw (single-channel) binary data is stored in the 'data' dataset. If this attribute is not present, then the default format='raw' case is assumed.
    imaging_volume; %  ImagingVolume
    intensity; %  (single) Intensity of the excitation in mW/mm^2, if known.
    pmt_gain; %  (single) Photomultiplier gain for each channel
    power; %  (single) Power of the excitation in mW, if known.
    scan_line_rate; %  (single) Lines imaged per second.
    starting_frame; %  (int32) Each external image may contain one or more consecutive frames of the full ImageSeries. This attribute serves as an index to indicate which frames each file contains, to faciliate random access. The 'starting_frame' attribute, hence, contains a list of frame numbers within the full ImageSeries of the first frame of each file listed in the parent 'external_file' dataset. Zero-based indexing is used (hence, the first element will always be zero). For example, if the 'external_file' dataset has three paths to files and the first file has 5 frames, the second file has 10 frames, and the third file has 20 frames, then this attribute will have values [0, 5, 15]. If there is a single external file that holds all of the frames of the ImageSeries (and so there is a single element in the 'external_file' dataset), then this attribute should have value [0].
end

methods
    function obj = MultiChannelVolumeSeries(varargin)
        % MULTICHANNELVOLUMESERIES Constructor for MultiChannelVolumeSeries
        varargin = [{'format' 'raw'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'binning',[]);
        addParameter(p, 'data',[]);
        addParameter(p, 'device',[]);
        addParameter(p, 'dimension',[]);
        addParameter(p, 'exposure_time',[]);
        addParameter(p, 'external_file',[]);
        addParameter(p, 'format',[]);
        addParameter(p, 'imaging_volume',[]);
        addParameter(p, 'intensity',[]);
        addParameter(p, 'pmt_gain',[]);
        addParameter(p, 'power',[]);
        addParameter(p, 'scan_line_rate',[]);
        addParameter(p, 'starting_frame',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.binning = p.Results.binning;
        obj.data = p.Results.data;
        obj.device = p.Results.device;
        obj.dimension = p.Results.dimension;
        obj.exposure_time = p.Results.exposure_time;
        obj.external_file = p.Results.external_file;
        obj.format = p.Results.format;
        obj.imaging_volume = p.Results.imaging_volume;
        obj.intensity = p.Results.intensity;
        obj.pmt_gain = p.Results.pmt_gain;
        obj.power = p.Results.power;
        obj.scan_line_rate = p.Results.scan_line_rate;
        obj.starting_frame = p.Results.starting_frame;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.MultiChannelVolumeSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.binning(obj, val)
        obj.binning = obj.validate_binning(val);
    end
    function set.device(obj, val)
        obj.device = obj.validate_device(val);
    end
    function set.dimension(obj, val)
        obj.dimension = obj.validate_dimension(val);
    end
    function set.exposure_time(obj, val)
        obj.exposure_time = obj.validate_exposure_time(val);
    end
    function set.external_file(obj, val)
        obj.external_file = obj.validate_external_file(val);
    end
    function set.format(obj, val)
        obj.format = obj.validate_format(val);
    end
    function set.imaging_volume(obj, val)
        obj.imaging_volume = obj.validate_imaging_volume(val);
    end
    function set.intensity(obj, val)
        obj.intensity = obj.validate_intensity(val);
    end
    function set.pmt_gain(obj, val)
        obj.pmt_gain = obj.validate_pmt_gain(val);
    end
    function set.power(obj, val)
        obj.power = obj.validate_power(val);
    end
    function set.scan_line_rate(obj, val)
        obj.scan_line_rate = obj.validate_scan_line_rate(val);
    end
    function set.starting_frame(obj, val)
        obj.starting_frame = obj.validate_starting_frame(val);
    end
    %% VALIDATORS
    
    function val = validate_binning(obj, val)
        val = types.util.checkDtype('binning', 'uint8', val);
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
        validshapes = {[Inf,Inf,Inf,Inf,Inf], [Inf,Inf,Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_device(obj, val)
        val = types.util.checkDtype('device', 'types.core.Device', val);
    end
    function val = validate_dimension(obj, val)
        val = types.util.checkDtype('dimension', 'int32', val);
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
    function val = validate_exposure_time(obj, val)
        val = types.util.checkDtype('exposure_time', 'single', val);
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
    function val = validate_external_file(obj, val)
        val = types.util.checkDtype('external_file', 'char', val);
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
    function val = validate_format(obj, val)
        val = types.util.checkDtype('format', 'char', val);
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
    function val = validate_intensity(obj, val)
        val = types.util.checkDtype('intensity', 'single', val);
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
    function val = validate_pmt_gain(obj, val)
        val = types.util.checkDtype('pmt_gain', 'single', val);
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
    function val = validate_power(obj, val)
        val = types.util.checkDtype('power', 'single', val);
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
    function val = validate_scan_line_rate(obj, val)
        val = types.util.checkDtype('scan_line_rate', 'single', val);
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
    function val = validate_starting_frame(obj, val)
        val = types.util.checkDtype('starting_frame', 'int32', val);
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
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.binning)
            io.writeAttribute(fid, [fullpath '/binning'], obj.binning);
        end
        refs = obj.device.export(fid, [fullpath '/device'], refs);
        if startsWith(class(obj.dimension), 'types.untyped.')
            refs = obj.dimension.export(fid, [fullpath '/dimension'], refs);
        elseif ~isempty(obj.dimension)
            io.writeDataset(fid, [fullpath '/dimension'], obj.dimension, 'forceArray');
        end
        if ~isempty(obj.exposure_time)
            if startsWith(class(obj.exposure_time), 'types.untyped.')
                refs = obj.exposure_time.export(fid, [fullpath '/exposure_time'], refs);
            elseif ~isempty(obj.exposure_time)
                io.writeDataset(fid, [fullpath '/exposure_time'], obj.exposure_time, 'forceArray');
            end
        end
        if ~isempty(obj.external_file)
            if startsWith(class(obj.external_file), 'types.untyped.')
                refs = obj.external_file.export(fid, [fullpath '/external_file'], refs);
            elseif ~isempty(obj.external_file)
                io.writeDataset(fid, [fullpath '/external_file'], obj.external_file, 'forceArray');
            end
        end
        if ~isempty(obj.format)
            io.writeAttribute(fid, [fullpath '/format'], obj.format);
        end
        refs = obj.imaging_volume.export(fid, [fullpath '/imaging_volume'], refs);
        if ~isempty(obj.intensity)
            if startsWith(class(obj.intensity), 'types.untyped.')
                refs = obj.intensity.export(fid, [fullpath '/intensity'], refs);
            elseif ~isempty(obj.intensity)
                io.writeDataset(fid, [fullpath '/intensity'], obj.intensity);
            end
        end
        if ~isempty(obj.pmt_gain)
            if startsWith(class(obj.pmt_gain), 'types.untyped.')
                refs = obj.pmt_gain.export(fid, [fullpath '/pmt_gain'], refs);
            elseif ~isempty(obj.pmt_gain)
                io.writeDataset(fid, [fullpath '/pmt_gain'], obj.pmt_gain, 'forceArray');
            end
        end
        if ~isempty(obj.power)
            if startsWith(class(obj.power), 'types.untyped.')
                refs = obj.power.export(fid, [fullpath '/power'], refs);
            elseif ~isempty(obj.power)
                io.writeDataset(fid, [fullpath '/power'], obj.power, 'forceArray');
            end
        end
        if ~isempty(obj.scan_line_rate)
            io.writeAttribute(fid, [fullpath '/scan_line_rate'], obj.scan_line_rate);
        end
        if ~isempty(obj.starting_frame)
            io.writeAttribute(fid, [fullpath '/starting_frame'], obj.starting_frame, 'forceArray');
        end
    end
end

end