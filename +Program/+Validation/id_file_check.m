function file = id_file_check(file)
    id_file_ext = '_ID.mat';
    if endsWith(file, id_file_ext)
        file = strrep(file, id_file_ext, '.mat');
    end
end

