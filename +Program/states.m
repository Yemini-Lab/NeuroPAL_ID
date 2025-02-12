classdef states < dynamicprops
    
    properties
    end
    
    methods (Access = public)        
        function set(keyword, value)
            states = Program.states;
            states.(keyword) = value;
            Program.states(states);
        end

        function clear(keyword)
            states = Program.states;
            states = rmfield(states, keyword);
            Program.states(states);
        end
    end

    methods (Static, Access = public)
        function bool = debug()
            states = Program.states;
            bool = isfield(states, 'debug_mode');
        end
    end

    methods (Access = private)
        function obj = states(new_states)
            persistent state_obj

            if nargin > 0
                state_obj = new_states;
            elseif isempty(state_obj)
                state_obj = struct('is_initialized', {0});
            end

            obj = state_obj;
        end
    end
end

