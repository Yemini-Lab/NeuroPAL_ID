classdef OpticalChannelPlus < types.core.OpticalChannel & types.untyped.GroupClass
% OPTICALCHANNELPLUS An optical channel used to record from an imaging volume. Contains both emission and excitation bands.


% REQUIRED PROPERTIES
properties
    emission_range; % REQUIRED (single) boundaries of emission wavelength for channel, in nm
    excitation_lambda; % REQUIRED (single) Excitation wavelength for channle, in nm.
    excitation_range; % REQUIRED (single) boundaries of excitation wavelength for channel, in nm
end

methods
    function obj = OpticalChannelPlus(varargin)
        % OPTICALCHANNELPLUS Constructor for OpticalChannelPlus
        obj = obj@types.core.OpticalChannel(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'emission_range',[]);
        addParameter(p, 'excitation_lambda',[]);
        addParameter(p, 'excitation_range',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.emission_range = p.Results.emission_range;
        obj.excitation_lambda = p.Results.excitation_lambda;
        obj.excitation_range = p.Results.excitation_range;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.OpticalChannelPlus')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.emission_range(obj, val)
        obj.emission_range = obj.validate_emission_range(val);
    end
    function set.excitation_lambda(obj, val)
        obj.excitation_lambda = obj.validate_excitation_lambda(val);
    end
    function set.excitation_range(obj, val)
        obj.excitation_range = obj.validate_excitation_range(val);
    end
    %% VALIDATORS
    
    function val = validate_emission_range(obj, val)
        val = types.util.checkDtype('emission_range', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_excitation_lambda(obj, val)
        val = types.util.checkDtype('excitation_lambda', 'single', val);
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
    function val = validate_excitation_range(obj, val)
        val = types.util.checkDtype('excitation_range', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.OpticalChannel(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.emission_range), 'types.untyped.')
            refs = obj.emission_range.export(fid, [fullpath '/emission_range'], refs);
        elseif ~isempty(obj.emission_range)
            io.writeDataset(fid, [fullpath '/emission_range'], obj.emission_range, 'forceArray');
        end
        if startsWith(class(obj.excitation_lambda), 'types.untyped.')
            refs = obj.excitation_lambda.export(fid, [fullpath '/excitation_lambda'], refs);
        elseif ~isempty(obj.excitation_lambda)
            io.writeDataset(fid, [fullpath '/excitation_lambda'], obj.excitation_lambda);
        end
        if startsWith(class(obj.excitation_range), 'types.untyped.')
            refs = obj.excitation_range.export(fid, [fullpath '/excitation_range'], refs);
        elseif ~isempty(obj.excitation_range)
            io.writeDataset(fid, [fullpath '/excitation_range'], obj.excitation_range, 'forceArray');
        end
    end
end

end