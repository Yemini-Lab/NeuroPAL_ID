function stimuli = readStimFile(path)
    [~, ~, fmt] = fileparts(path);

    switch fmt
        case 'txt'
            stimuli = readtable(path, 'Delimiter', ',', 'Format', '%d%s');
        case 'nwb'
            % TBD (See visualize_light.)
    end
end