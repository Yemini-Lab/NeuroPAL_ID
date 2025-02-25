function processing_tab()
    app = Program.app;
    switch Program.states.volume_type
        case 'stack'
            path = app.image_file;
        case 'video'
            path = app.video_info.file;
        otherwise
            GUI_prefs = Program.GUIPreferences.instance();
            last_path = GUI_prefs.image_dir;
            file_info = [last_path Program.config.valid_fmts];
            [name, path, ~] = uigetfile(file_info, 'Select volume.');
            path = fullfile(path, name);
    end

    Program.Routines.load_volume(path)
end

