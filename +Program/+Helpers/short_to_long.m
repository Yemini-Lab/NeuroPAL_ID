function converted_string = short_to_long(input_string)
    short_names = Program.Handlers.channels.names('short');
    long_names = Program.Handlers.channels.names('long');

    idx = strcmp(input_string, short_names);
    converted_string = long_names(idx);
end

