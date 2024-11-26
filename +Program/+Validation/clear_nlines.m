function cleared_string = clear_nlines(input)
    cleared_string = splitlines(input);
    cleared_string = cleared_string(~cellfun('isempty', cleared_string));
    cleared_string = join(cleared_string, '\n');
    cleared_string = sprintf(cleared_string{1});
end

