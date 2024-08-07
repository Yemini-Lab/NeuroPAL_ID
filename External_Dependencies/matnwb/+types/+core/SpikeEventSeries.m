classdef SpikeEventSeries < types.core.ElectricalSeries & types.untyped.GroupClass
% SPIKEEVENTSERIES Stores snapshots/snippets of recorded spike events (i.e., threshold crossings). This may also be raw data, as reported by ephys hardware. If so, the TimeSeries::description field should describe how events were detected. All SpikeEventSeries should reside in a module (under EventWaveform interface) even if the spikes were reported and stored by hardware. All events span the same recording channels and store snapshots of equal duration. TimeSeries::data array structure: [num events] [num channels] [num samples] (or [num events] [num samples] for single electrode).



methods
    function obj = SpikeEventSeries(varargin)
        % SPIKEEVENTSERIES Constructor for SpikeEventSeries
        varargin = [{'data_conversion' types.util.correctType(1, 'single') 'data_offset' types.util.correctType(0, 'single') 'data_resolution' types.util.correctType(-1, 'single') 'data_unit' 'volts' 'timestamps_interval' types.util.correctType(1, 'int32') 'timestamps_unit' 'seconds'} varargin];
        obj = obj@types.core.ElectricalSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'data_continuity',[]);
        addParameter(p, 'data_conversion',[]);
        addParameter(p, 'data_offset',[]);
        addParameter(p, 'data_resolution',[]);
        addParameter(p, 'data_unit',[]);
        addParameter(p, 'timestamps',[]);
        addParameter(p, 'timestamps_interval',[]);
        addParameter(p, 'timestamps_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.data_continuity = p.Results.data_continuity;
        obj.data_conversion = p.Results.data_conversion;
        obj.data_offset = p.Results.data_offset;
        obj.data_resolution = p.Results.data_resolution;
        obj.data_unit = p.Results.data_unit;
        obj.timestamps = p.Results.timestamps;
        obj.timestamps_interval = p.Results.timestamps_interval;
        obj.timestamps_unit = p.Results.timestamps_unit;
        if strcmp(class(obj), 'types.core.SpikeEventSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
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
        validshapes = {[Inf,Inf,Inf], [Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data_continuity(obj, val)
        val = types.util.checkDtype('data_continuity', 'char', val);
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
    function val = validate_data_conversion(obj, val)
        val = types.util.checkDtype('data_conversion', 'single', val);
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
    function val = validate_data_offset(obj, val)
        val = types.util.checkDtype('data_offset', 'single', val);
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
    function val = validate_data_resolution(obj, val)
        val = types.util.checkDtype('data_resolution', 'single', val);
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
    function val = validate_data_unit(obj, val)
        if isequal(val, 'volts')
            val = 'volts';
        else
            error('Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.SpikeEventSeries">SpikeEventSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_timestamps(obj, val)
        val = types.util.checkDtype('timestamps', 'double', val);
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
    function val = validate_timestamps_interval(obj, val)
        if isequal(val, 1)
            val = 1;
        else
            error('Unable to set the ''timestamps_interval'' property of class ''<a href="matlab:doc types.core.SpikeEventSeries">SpikeEventSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_timestamps_unit(obj, val)
        if isequal(val, 'seconds')
            val = 'seconds';
        else
            error('Unable to set the ''timestamps_unit'' property of class ''<a href="matlab:doc types.core.SpikeEventSeries">SpikeEventSeries</a>'' because it is read-only.')
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ElectricalSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end