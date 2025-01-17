classdef security
    %SECURITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static, Access = public)
        function path = app_data_folder()
            persistent path_to_local_app_data

            if isempty(path_to_local_app_data)
                if isdeployed
                    if ispc
                        path_to_local_app_data = fullfile(getenv('USERPROFILE'), 'AppData', 'NeuroPAL_ID');

                    elseif ismac
                        path_to_local_app_data = '~/Library/Application Support/NeuroPAL_ID';

                    else
                        path_to_local_app_data = fullfile(ctfroot);

                    end

                else
                    path_to_local_app_data = fullfile(pwd);

                end
            end

            path = path_to_local_app_data;
        end

        function path = libraries(new_path)
            persistent path_to_libraries

            if nargin > 0
                if isfolder(new_path) && contains(new_path, 'lib')
                    path_to_libraries = new_path;

                else
                    error("Cannot locate NeuroPAL_ID libraries in %s.", new_path);
                    return

                end

            elseif isempty(path_to_libraries)
                Program.Routines.Debug.security.set_up();
                
            end

            path = path_to_libraries;
        end

        function set_up()
            prospective_lib = fullfile(Program.Routines.Debug.security.app_data_folder, 'lib');
            
            if isfolder(fullfile(pwd, 'lib'))
                default_lib = fullfile(pwd, 'lib');

            elseif isfolder(fullfile(ctfroot, 'lib'))
                default_lib = fullfile(ctfroot, 'lib');

            else
                error("Cannot locate NeuroPAL_ID libraries.")

            end

            if ~isfolder(prospective_lib)
                movefile(default_lib, prospective_lib);
            end

            Program.Routines.Debug.security.libraries(prospective_lib);
        end
    end
end

