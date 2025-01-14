classdef active_volume
    %ACTIVE_VOLUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = get(query)
            if nargin < 1
                obj = struct( ...
                    'array', {}, ...
                    'dims', {}, ...
                    'state', {});

            else
                switch query
                    case 'array'
                    case 'dims'
                    case 'state'
                end

            end
        end
        
        function outputArg = get_array()
        end
    end
end

