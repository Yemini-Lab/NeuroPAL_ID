classdef information
    
    % Program constants.
    properties (Constant, Access = public)
        name = 'NeuroPAL Auto ID'; % program name
        version = 2; % software version
        version_URL = 'https://raw.githubusercontent.com/amin-nejat/CELL_ID/master/version.info';
        %website_URL = 'http://hobertlab.org/neuropal/';
        website_URL = 'http://yeminilab.com/neuropal/';
        bug_URL = 'https://github.com/amin-nejat/CELL_ID/issues';
    end
    
   % Public methods.
    methods (Static)
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
