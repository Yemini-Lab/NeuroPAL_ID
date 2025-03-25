function maximum_array = get_max_array_size()
    % Returns maximum memory to use for a single chunk.

    if ispc
        maximum_array = memory().MaxPossibleArrayBytes * 0.90;
    else
        [~, maximum_array] = system('sysctl hw.memsize | awk ''{print $2}''');
        maximum_array = str2double(maximum_array) * 0.90;
    end
end

