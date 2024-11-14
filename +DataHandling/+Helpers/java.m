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
            
            keys = string(table.keySet.toArray); % Get all keys from the Java hashtable as a string array.
            for k = 1:length(keys)
                target_key = DataHandling.Helpers.java.to_valid(keys{k}); % Convert key to valid format.
                if ~isempty(target_key) % Proceed only if the key is valid (not empty).
                    if ~exist('obj', 'var')
                        % Initialize the struct with the first key-value pair.
                        obj = struct(target_key, table.get(target_key));
                    else
                        % Add subsequent key-value pairs to the struct.
                        obj.(target_key) = table.get(target_key);
                    end
                end
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
            
            valid_str = strrep(raw_str, '#', 'num'); % Replace '#' with 'num' for compatibility.
            invalid_characters = DataHandling.Helpers.java.invalid_characters; % Retrieve invalid characters.
            
            for n = 1:length(invalid_characters)
                % Replace each invalid character with an underscore.
                valid_str = strrep(valid_str, invalid_characters{n}, '_');
            end
            
            % Truncate string if it exceeds the maximum allowed length.
            if length(valid_str) > DataHandling.Helpers.java.max_characters
                valid_str = valid_str(1:DataHandling.Helpers.java.max_characters - 1);
            end
            
            % If string is too short, mark it as invalid by setting it to empty.
            if length(valid_str) < 3
                valid_str = '';
            else
                % Ensure the first character is a letter; otherwise, replace with 'm'.
                if ~isstrprop(valid_str(1), 'alpha')
                    valid_str(1) = 'm';
                end
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
