function event_struct = event_to_struct(varargin)
    fields = properties(varargin{:});
    
    for i = 1:length(fields)
        fieldName = fields{i};
        event_struct.(fieldName) = varargin{:}.(fieldName);
    end
end