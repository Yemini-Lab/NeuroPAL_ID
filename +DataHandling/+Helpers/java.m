classdef java
    % Class java - Handles conversion of Java hashtable keys and values into MATLAB structures 
    % and manages string validity based on specified character constraints.
    
    properties (Constant, Access = public)
        max_characters = 63; % Maximum number of characters allowed for valid strings.
    end
    
    methods (Static)
        function obj = parse_hashtable(table)
            % Converts a Java hashtable into a MATLAB structure with valid field names.
            % 
            % Parameters:
            %   table: A Java hashtable object containing key-value pairs.
            %
            % Returns:
            %   obj: A MATLAB struct where keys are converted to valid MATLAB field names.
            
            obj = struct();
            raw_keys = table.keySet.toArray; % Preserve original Java keys for table lookup.
            used_keys = cell(1, numel(raw_keys));
            used_count = 0;
            for k = 1:numel(raw_keys)
                raw_key = raw_keys(k);
                target_key = DataHandling.Helpers.java.to_valid(char(raw_key));
                if ~isempty(target_key)
                    target_key = matlab.lang.makeUniqueStrings(target_key, used_keys(1:used_count), ...
                        namelengthmax);
                    used_count = used_count + 1;
                    used_keys{used_count} = target_key;
                    obj.(target_key) = table.get(raw_key);
                end
            end
        end

        function [keys, values, count] = search_key(metadata, query)
            keys = cell(1, metadata.size());
            values = cell(1, metadata.size());
            count = 0;
            keySet = metadata.keySet();
            if isempty(keySet)
                warning('Global metadata has no keys.');
            else
                % Create an iterator over the keys
                keyIter = keySet.iterator();
                while keyIter.hasNext()
                    k = keyIter.next();
                    if ~isempty(k)
                        val = metadata.get(k);

                        if contains(lower(char(k)), lower(query))
                            count = count + 1;
                            keys{count} = char(k);
                            values{count} = val;
                        end
                    end
                end
            end

            keys = keys(1:count);
            values = values(1:count);
        end

        function valStr = value_to_string(val)
            % Convert a Java-based metadata value to a MATLAB string
            if isempty(val)
                valStr = '[empty]';
                return;
            end
            
            % Handle various Java/MATLAB types
            if isa(val, 'java.lang.String')
                % Convert Java string to MATLAB char array
                valStr = char(val);
            elseif isa(val, 'java.lang.Number')
                % Convert Java numeric type to MATLAB double
                valStr = num2str(double(val));
            elseif isa(val, 'java.lang.Boolean')
                % Convert Java Boolean to 'true'/'false'
                valStr = char(val.toString());
            elseif islogical(val)
                % MATLAB logical
                if val
                    valStr = 'true';
                else
                    valStr = 'false';
                end
            else
                % Other or unhandled object type, just show class name
                valStr = sprintf('[%s]', class(val));
            end
        end

        function valid_str = to_valid(raw_str)
            % Converts an input string to a valid MATLAB field name by replacing or truncating characters.
            %
            % Parameters:
            %   raw_str: Original string to be validated and formatted.
            %
            % Returns:
            %   valid_str: Modified string that meets MATLAB field name requirements.
            
            valid_str = char(string(raw_str));
            valid_str = strrep(valid_str, '#', 'num'); % Replace '#' with 'num' for compatibility.
            valid_str = matlab.lang.makeValidName(valid_str, 'ReplacementStyle', 'underscore');

            max_len = min(DataHandling.Helpers.java.max_characters, namelengthmax);
            if length(valid_str) > max_len
                valid_str = valid_str(1:max_len);
            end

            if length(valid_str) < 3
                valid_str = '';
            end
        end
    end

    methods (Static, Access = private)
        
        function obj = invalid_characters()
            % Generates a list of invalid characters for MATLAB variable names.
            %
            % Returns:
            %   obj: A cell array of strings, each representing an invalid character.
            
            persistent unchars % Use persistent variable to store results across calls.
            
            if isempty(unchars)
                chars = char(32:126); % All printable ASCII characters.
                
                % Identify valid characters (letters, digits, and underscores).
                isLetter = isstrprop(chars, 'alpha');
                isDigit = isstrprop(chars, 'digit');
                isUnderscore = chars == '_';
                exclude_idx = isLetter | isDigit | isUnderscore; % Index of valid characters.
                
                % Obtain a list of characters that are not valid in MATLAB variable names.
                special_chars = chars(~exclude_idx);
                unchars = cellstr(special_chars'); % Convert to cell array of strings.
                unchars = [unchars' {' ', '�'}]; % Include space and � as additional invalid characters.
            end
            
            obj = unchars; % Return the list of invalid characters.
        end
    end
end
