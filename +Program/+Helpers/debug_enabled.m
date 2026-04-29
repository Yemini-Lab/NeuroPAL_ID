function tf = debug_enabled()
value = lower(strtrim(getenv('NPAL_DEBUG')));
tf = any(strcmp(value, {'1', 'true', 'yes', 'on'}));
end
