function preprocess(varargin)
    p = inputParser();
    addParameter(p, 'array', []);
    addParameter(p, 'volume', []);
    addParameter(p, 'actions', []);
    parse(p, obj, varargin{:});

    

end

