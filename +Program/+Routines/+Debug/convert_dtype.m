function convert_dtype()
    state = Program.state();
    volume = state.active_volume;
    volume.convert('uint8');
end

