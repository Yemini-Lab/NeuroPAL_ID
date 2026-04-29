function value = struct_field(s, field_name, default_value)
if nargin < 3
    default_value = [];
end

value = default_value;
if isstruct(s) && isfield(s, field_name)
    value = s.(field_name);
end
end
