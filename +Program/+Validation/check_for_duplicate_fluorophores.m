function [new_indices, has_duplicate, duplicate_indices] = check_for_duplicate_fluorophores(indices)
    indices = cell2mat(indices);
    has_duplicate = numel(indices) == numel(unique(indices));
    duplicate_indices = [];
    if has_duplicate
        duplicate_indices = [];
        uniqueVals = unique(indices);
        
        for val = uniqueVals(:)'
            matches = find(indices == val);
            if numel(matches) > 1
                duplicate_indices(end+1) = matches(2);
            end
        end
    end

    new_indices = indices;
    for d=1:length(duplicate_indices)
        idx = duplicate_indices(d);
        new_indices(idx) = [];
        new_indices = [new_indices indices(idx)];        
        Program.Handlers.channels.add_channel();
    end
end

