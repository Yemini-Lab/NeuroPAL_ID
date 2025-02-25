function toggle_mip()
    states = Program.states;
    if isfield(states, 'mip')
        Program.states.set('mip', ~states.mip);
    else
        Program.states.set('mip', 1);
    end
end

