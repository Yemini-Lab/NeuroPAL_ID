function output = noskip_test(input_array)
    unique_vals = unique(input_array);
    mapped_vals = unique_vals(1):unique_vals(1)+length(unique_vals)-1;
    [~, idx] = ismember(input_array, unique_vals);
    output = mapped_vals(idx);
end