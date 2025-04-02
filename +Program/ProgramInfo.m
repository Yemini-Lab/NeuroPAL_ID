classdef ProgramInfo
    %PROGRAMINFO Program information.
    
    % Program constants.
    properties (Constant, Access = public)
        name = 'NeuroPAL Auto ID'; % program name
        version = 1.8; % software version
        version_URL = 'https://raw.githubusercontent.com/amin-nejat/CELL_ID/master/version.info';
        %website_URL = 'http://hobertlab.org/neuropal/';
        website_URL = 'http://yeminilab.com/neuropal/';
        bug_URL = 'https://github.com/amin-nejat/CELL_ID/issues';
    end
    
   % Public methods.
    methods (Static)
        function handle = window()
            %WINDOW Retrieve a persistent handle to the active window.
            %
            %   Output:
            %   - handle: The figure handle with the specified name, or
            %       empty if none is found.
        
            % Define a persistent variable that caches the figure handle across calls
            persistent window_handle


            % Check whether the persistent variable is uninitialized.
            is_uninitialized = isempty(window_handle);

            % Check whether the persistent variable references a delete
            % or otherwise invalid graphics object.
            is_invalid = any(~isgraphics(window_handle));
        
            % Check whether the persistent variable references a delete
            % or otherwise invalid graphics object.
            if is_uninitialized || is_invalid
                % If so, find the active window.
                window_handle = findall(groot, 'Name', 'NeuroPAL ID');
            end
            
            % Return the handle to the caller
            handle = window_handle;
        end

        function handle = app()
            %APP Retrieve a persistent handle to the running app instance.
            %
            %   Output:
            %   - handle: The handle to the running application instance
            %       (if it exists), or an empty value otherwise.
        
            % Initiate a persistent reference.
            persistent app_handle

            % Check whether the persistent variable is uninitialized.
            is_uninitialized = any(isempty(app_handle));

            % Check whether the persistent variable references a delete
            % or otherwise invalid graphics object.
            is_invalid = any(isa(app_handle, "handle")) ...
                && any(~isvalid(app_handle));
        
            % If the reference is empty or invalid, try to find it.
            if  is_uninitialized || is_invalid               
                window_handle = Program.ProgramInfo.window();
                app_handle = window_handle.RunningAppInstance;
            end
        
            % Return the persistent variable.
            handle = app_handle;
        end

        function msg = getAboutMsg()
            %GETABOUTMSG Get the about message for display.
            msg = [];
        end
        
        function msg = getKeyboardShortcutsMsg()
            %GETKEYBOARDSHORTCUTSMSG Get the keyboard shortcuts message for
            %  display.
            msg = [];
        end
        
        function latest_version = checkUpdates()
            %CHECKUPDATES Check the software for updates.
            
            % Initialize the version.
            import Program.*;
            
            % Get the latest version info.
            url = ProgramInfo.version_URL;
            str = urlread(url); % webread has a bug!
            
            % Can we connect?
            url_ver = splitlines(str);
            
            % Find the latest software version.
            ver_i = find(contains(url_ver, 'software'), 1);
            ver_str = url_ver{ver_i};
            equal_i = find(ver_str == '=', 1);
            latest_version = str2double(ver_str((equal_i+1):end));
        end
    end
end
