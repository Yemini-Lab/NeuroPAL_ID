function double_arr = to_double(arr)
    current_class = class(arr);
    bare_arr = arr/intmax(current_class);
    double_arr = bare_arr*intmax('double');
end

