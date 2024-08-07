classdef CElegansSubject < types.core.Subject & types.untyped.GroupClass
% CELEGANSSUBJECT Subject object with support for C. Elegans specific attributes


% REQUIRED PROPERTIES
properties
    growth_stage; % REQUIRED (char) Growth stage of C. elegans. One of two-fold, three-fold, L1-L4, YA, OA, duaer, post-dauer L4, post-dauer YA, post-dauer OA
end
% OPTIONAL PROPERTIES
properties
    cultivation_temp; %  (single) Worm cultivation temperature in C
    growth_stage_time; %  (char) amount of time in current growth stage in ISO 8601 duration format
end

methods
    function obj = CElegansSubject(varargin)
        % CELEGANSSUBJECT Constructor for CElegansSubject
        obj = obj@types.core.Subject(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'cultivation_temp',[]);
        addParameter(p, 'growth_stage',[]);
        addParameter(p, 'growth_stage_time',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.cultivation_temp = p.Results.cultivation_temp;
        obj.growth_stage = p.Results.growth_stage;
        obj.growth_stage_time = p.Results.growth_stage_time;
        if strcmp(class(obj), 'types.ndx_multichannel_volume.CElegansSubject')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.cultivation_temp(obj, val)
        obj.cultivation_temp = obj.validate_cultivation_temp(val);
    end
    function set.growth_stage(obj, val)
        obj.growth_stage = obj.validate_growth_stage(val);
    end
    function set.growth_stage_time(obj, val)
        obj.growth_stage_time = obj.validate_growth_stage_time(val);
    end
    %% VALIDATORS
    
    function val = validate_cultivation_temp(obj, val)
        val = types.util.checkDtype('cultivation_temp', 'single', val);
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
    function val = validate_growth_stage(obj, val)
        val = types.util.checkDtype('growth_stage', 'char', val);
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
    function val = validate_growth_stage_time(obj, val)
        val = types.util.checkDtype('growth_stage_time', 'char', val);
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
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Subject(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.cultivation_temp)
            if startsWith(class(obj.cultivation_temp), 'types.untyped.')
                refs = obj.cultivation_temp.export(fid, [fullpath '/cultivation_temp'], refs);
            elseif ~isempty(obj.cultivation_temp)
                io.writeDataset(fid, [fullpath '/cultivation_temp'], obj.cultivation_temp);
            end
        end
        if startsWith(class(obj.growth_stage), 'types.untyped.')
            refs = obj.growth_stage.export(fid, [fullpath '/growth_stage'], refs);
        elseif ~isempty(obj.growth_stage)
            io.writeDataset(fid, [fullpath '/growth_stage'], obj.growth_stage);
        end
        if ~isempty(obj.growth_stage_time)
            io.writeAttribute(fid, [fullpath '/growth_stage_time'], obj.growth_stage_time);
        end
    end
end

end