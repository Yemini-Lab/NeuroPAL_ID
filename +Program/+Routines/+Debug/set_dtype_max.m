function set_dtype_max()
    state = Program.state();
    volume = state.active_volume;
    volume.dtype_max = 255;
    Program.GUI.histogram_editor.update(volume);
end

