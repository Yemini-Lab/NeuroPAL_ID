function out = cache(varargin)
    persistent current_cache

    if nargin ~= 0 
        if isequal(varargin{1}, 'clear')
            current_cache = [];
        else
            current_cache = varargin{:};
        end
    end

    out = current_cache;
end

