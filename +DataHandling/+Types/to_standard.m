function standard_arr = to_standard(arr)
    standard_arr = cast(arr, Program.config.defaults{'class'});
    
    %current_class = class(arr);
    %standard_class = Program.GUIHandling.standard_class;
    %bare_arr = arr/intmax(current_class);
    %standard_arr = bare_arr*intmax(standard_class);
end

