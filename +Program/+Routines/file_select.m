function loaded_successfully = file_select(mode)
    loaded_successfully = 0;
    
    if Program.states.is_loading_file
        return
    else
        Program.states.set('is_loading_file', 1);
    end
    
    Program.Routines.close();
    
    window = Program.window;
    GUI_prefs = Program.GUIPreferences.instance();
    
    window.Visible = 'off';
    explorer_preset = [GUI_prefs.image_dir, Program.config.fmts{mode}];
    [name, path, ~] = uigetfile(explorer_preset, 'Select Volume');
    fpath = fullfile(path, name);
    window.Visible = 'on';
    
    if name == 0
        Program.states.set('is_loading_file', 0);
        return; % user cancelled
    end
    
    GUI_prefs.image_dir = path;
    GUI_prefs.save();
    
    if Program.Validation.check_volume_size(fpath)
        Program.Routines.Processing.load(mode, fpath);
        return; % passed file to preprocessing
    end
    
    volume = Program.Routines.load_volume(fpath);
    Program.states.set('volume', volume);
    Program.states.set('is_loading_file', 1);
    loaded_successfully = 1;
end

