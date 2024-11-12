function render_idx = indices_to_render(idx_arr)
    unique_vals = unique(idx_arr);
    mapped_vals = unique_vals(1):unique_vals(1)+length(unique_vals)-1;
    [~, idx] = ismember(idx_arr, unique_vals);
    noskip_arr = mapped_vals(idx);
    delta = 1-min(noskip_arr);
    render_idx = noskip_arr + delta;
end

