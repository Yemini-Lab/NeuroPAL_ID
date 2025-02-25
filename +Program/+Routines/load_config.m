function load_config()
    app = Program.app;
    
    config = Program.config;
    subject_validation_map = config.default.fields.gui_subject;
    subject_properties = fieldnames(subject_validation_map);
    for p=1:length(subject_properties)
        subject_property = subject_properties{p};
        handle = sprintf('%sDropDown', subject_property);
        app.(handle).Items = subject_validation_map.(subject_property);
    end
end

