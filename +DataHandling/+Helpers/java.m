classdef java
    
    properties (Constant, Access = public)
        max_characters = 63;
    end
    
    methods (Static)
        function obj = parse_hashtable(table)
            keys = string(table.keySet.toArray);
            for k=1:length(keys)
                target_key = DataHandling.Helpers.java.to_valid(keys{k});
                if ~isempty(target_key)
                    if ~exist('obj', 'var')
                        obj = struct(target_key, table.get(target_key));
                    else
                        obj.(target_key) = table.get(target_key);
                    end
                end
            end
        end

        function valid_str = to_valid(raw_str)
            valid_str = strrep(raw_str, '#', 'num');
            invalid_characters = DataHandling.Helpers.java.invalid_characters;

            for n=1:length(invalid_characters)
                valid_str = strrep(valid_str, invalid_characters{n}, '_');
            end

            if length(valid_str) > DataHandling.Helpers.java.max_characters
                valid_str = valid_str(1:DataHandling.Helpers.java.max_characters-1);
            end

            if length(valid_str) < 3
                valid_str = '';
            else
                if ~isstrprop(valid_str(1), 'alpha')
                    valid_str(1) = 'm';
                end
            end
        end
    end

    methods (Static, Access = private)
        
        function obj = invalid_characters()
            persistent unchars

            if isempty(unchars)
                chars = char(32:126);
    
                isLetter = isstrprop(chars, 'alpha');
                isDigit = isstrprop(chars, 'digit');
                isUnderscore = chars == '_';
                exclude_idx = isLetter | isDigit | isUnderscore;
                
                special_chars = chars(~exclude_idx);
                unchars = cellstr(special_chars');
                unchars = [unchars' {' ', '�'}];
            end

            obj = unchars;
        end
    end
end

