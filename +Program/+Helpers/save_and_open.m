function path = save_and_open(filename, input)

    if isstruct(input)
        save(filename, '-struct', 'input');
    
    else
        save(filename, 'input');

    end

    [path, ~, ~] = fileparts(which(filename));

    if ispc
        winopen(path);
    else
        unix(path)
    end
end

