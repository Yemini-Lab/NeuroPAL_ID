function sex_code = parse_sex(sex_string)
    switch lower(sex_string)
        case {'o', 'herm', 'hermaphrodite', 'xx', 'x'}
            sex_code = 'XX';
        case {'m', 'male', 'xo'}
            sex_code = 'XO';
        otherwise
            sex_code = 'XX';
    end
end

