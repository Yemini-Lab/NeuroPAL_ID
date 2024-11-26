function path = save_and_open(filename, input)

    [path, ~, ~] = fileparts(which(filename));

    if isempty(path)
        filename = fullfile(Program.GUIPreferences.instance().image_dir, filename);
        [path, ~, ~] = fileparts(filename);
    end

    if ~isfolder(path)
        mkdir(path);
    end

    if isstruct(input)
        save(filename, '-struct', 'input');
    
    else
        save(filename, 'input');

    end

    if ispc
        winopen(path);
    else
        unix(path)
    end
end

