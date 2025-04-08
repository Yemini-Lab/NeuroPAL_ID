function relative_values = relative_value(val_1, val_2)
    class_1 = class(val_1);
    class_2 = class(val_2);

    if ~strcmp(class_1, class_r)
        base_1 = val_1/intmax(class_1);
        base_2 = val_2/intmax(class_2);
    
        relative_values = struct( ...
            'first', base_1 * intmax(class_2), ...
            'second', base_2 * intmax(class_1));
    else
        relative_values = struct( ...
            'first', val_1, ...
            'second', val_2);
    end
end

