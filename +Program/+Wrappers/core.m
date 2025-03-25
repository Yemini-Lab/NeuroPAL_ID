classdef core
    
    properties
        future = [];
    end

    methods
        function obj = core(prl)
            persistent active_future

            if nargin ~= 0
                active_future = prl;
            end

            obj.future = active_future;
        end

        function obj = clean_up(obj)
            obj.future = [];
            delete(obj);
        end
    end
    
    methods (Static, Access = public)
        function executable = get_executable()
            if ~isdeployed
                callable = 'python ';
                sloc = fullfile(pwd, '/+Wrapper/new/');
                ext = '.py';

            else
                if ispc
                    os = 'windows';
                    ext = '.exe';
                    spath = pwd;

                elseif ismac
                    os = 'macos';
                    ext = '';
                    spath = ctfroot;
                    for i = 1:4
                        spath = fileparts(spath);
                    end
                end

                callable = '';
                sloc = fullfile(spath, 'lib', 'bin', os);
            end

            executable = sprintf('%s%s', callable, ...
                fullfile(sloc, sprintf('npal%s', ext)));
        end

        function run(operation, config)
            Program.Handlers.dialogue.step('Sharing engine...');

            if ~matlab.engine.isEngineShared
                matlab.engine.shareEngine;
            end

            stack = dbstack;
            last_func = string(stack(2).name).split('.');
            origin_wrapper = last_func(1);
            
            Program.Handlers.dialogue.step('Formulating command');
            arguments = sprintf(' --operation=%s_%s --config="%s"', ...
                origin_wrapper, operation, config);
            executable = Program.Wrappers.core.get_executable();
            cmd = [executable, arguments];

            % Ensure we have a parallel pool
            Program.Handlers.dialogue.step('Seeking parallelized instance...');
            pool = gcp('nocreate');
            if isempty(pool)
                parpool;
            end
            
            % Execute the Python script asynchronously
            % parfeval returns a "future" object which you can retrieve later
            Program.Handlers.dialogue.step('Awaiting async wrapper signal...');
            futureObj = parfeval(@system, 2, cmd); %#ok<NASGU>
            Program.Wrappers.core(futureObj);
            
            % If you want to eventually capture the output and status,
            % you can call:
            [status, output] = fetchOutputs(futureObj);
        end

        function signal(trigger)
            if exist(trigger, 'var')
                fprintf("Received data: %s", trigger)

            else
                if startsWith(trigger, "end_")
                    obj = Program.Wrappers.core;
                    [status, output] = fetchOutputs(obj);
                    obj.clean_up();

                    status
                    output

                else
                    fprintf("Received unknown signal: %s", trigger)
                end
            end
        end
    end
end

