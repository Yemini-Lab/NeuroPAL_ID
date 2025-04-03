classdef system
    %SYSTEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static, Access = public)
        function maximum_array_size = get_maximum_array_size()
            % If there is an active progress dialogue, prompt it to
            % indicate that we are now performing a memory analysis.
            Program.GUI.dialogues.step('Performing memory analysis...');

            if ispc
                % If system is running Windows, use Matlab's memory()
                % function.
                maximum_array_size = memory().MaxPossibleArrayBytes;
            else
                % If system is running MacOS/Unix, use system call and
                % parse output.
                [~, maximum_array_size] = system( ...
                    'sysctl hw.memsize | awk ''{print $2}''');
                maximum_array_size = str2double(maximum_array_size);
            end

            % Adjust the maximum array size to leave a 10% memory
            % computational buffer.
            maximum_array_size = maximum_array_size * 0.90;
        end
    end
end

