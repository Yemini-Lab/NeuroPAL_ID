function converted_string = short_to_long(input_string)
    short_names = Program.Handlers.channels.names{'short'};
    long_names = Program.Handlers.channels.names{'long'};

    idx = strcmp(input_string, short_names);
    converted_string = long_names(idx);
    
    if isempty(converted_string)
        converted_string = Program.Helpers.short_to_long(input_string(1));
    end
end

