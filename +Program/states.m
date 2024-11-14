classdef states < dynamicprops
    
    properties % Mutable properties
        is_video = 0;               % Whether the active file is a video.
        is_lazy = 0;                % Whether we're in lazy load mode.
        is_mip = 0;                 % Whether we're rendering a maximum intensity projection.
    end
    
    methods (Static)
        function obj = instance()
            % Persistent variable to store the single instance.
            persistent uniqueInstance
            if isempty(uniqueInstance) || ~isvalid(uniqueInstance)
                uniqueInstance = states();
            end
            obj = uniqueInstance;
        end
    end
    
    methods
        function set(obj, key, value)
            % Set the value of a given property.
            obj.(key) = value;
        end
        
        function value = get(obj, key)
            % Return the value of a given property.
            value = obj.(key);
        end

        function toggle(obj, key)
            % Change the (binary) value of a given property.
            obj.(key) = ~obj.(key);
        end
    end
end
