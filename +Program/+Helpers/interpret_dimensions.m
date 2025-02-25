function [order, sorted_struct] = interpret_dimensions(dims, varargin)
    Program.states.now('Interpreting dimensions');
    p = inputParser();
    addRequired(p, 'dims');
    addParameter(p, 'mode', 'sizes');
    addParameter(p, 'key', '');
    parse(p, dims, varargin{:});

    if ~isempty(p.Results.key)
        key = lower(p.Results.key);
        nx = dims(strfind(key, 'x'));
        ny = dims(strfind(key, 'y'));
        nz = dims(strfind(key, 'z'));
        nc = dims(strfind(key, 'c'));
        nt = dims(strfind(key, 't'));
    else
        pck = rmfield(p.Results, 'key');
        switch pck.mode
            case 'order'
                ny = dims(1);
                nx = dims(2);
                nz = dims(3);
                nc = dims(4);
                if length(dims) <= 4
                    nt = 1;
                else
                    nt = dims(5);
                end
    
            case 'sizes'
                nx = max(dims(1:2));
                ny = min(dims(1:2));
                nc = min(dims(3:end));
            
                if length(dims) <= 4
                    nz = dims(~ismember(dims, [nx, ny, nc]));
                    nt = 1;
                else
                    nz = min(dims(~ismember(dims, [nx, ny, nc])));
                    nt = dims(~ismember(dims, [nx, ny, nc, nz]));
                end
        end
    end

    [~, order] = ismember(dims, [nx, ny, nz, nc, nt]);
    sorted_struct = struct( ...
        'x', {nx}, ...
        'y', {ny}, ...
        'z', {nz}, ...
        'c', {nc}, ...
        't', {nt});
end

