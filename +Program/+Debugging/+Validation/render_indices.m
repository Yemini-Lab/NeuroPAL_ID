function idx = render_indices(idx)
    idx = Program.Debugging.Validation.noskip_test(idx);
    idx = Program.Debugging.Validation.minimize_test(idx);
end

