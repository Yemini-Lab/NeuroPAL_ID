classdef wrapper
    
    properties
    end
    
    methods (Static, Access = public)
        function set_script_directory()
            app = Program.app;

            if ~isdeployed
                app.script_dir = fullfile(pwd, '/+Wrapper/');
                app.script_ext = '.py';

            else
                if ispc
                    app.script_dir = fullfile(pwd, '\lib\bin\windows\');
                    app.script_ext = '.exe';

                elseif ismac
                    ctfroot_path = ctfroot;
                    
                    for i = 1:4
                        ctfroot_path = fileparts(ctfroot_path);
                    end

                    app.script_dir = fullfile(ctfroot_path, 'lib/bin/macos/');
                    app.script_ext = '';

                end
            end

        end
    end
end

