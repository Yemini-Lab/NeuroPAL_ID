classdef GUI
    
    properties
    end
    
    methods (Static)
        function handle = app()
            persistent app_handle

            if any(isempty(app_handle)) || any(isa(app_handle, "handle")) && any(~isvalid(app_handle))
                window_handle = Program.GUI.window();
                app_handle = window_handle.RunningAppInstance;
            end

            handle = app_handle;
        end
        
        function handle = window()
            persistent window_handle

            if any(isempty(window_handle)) || any(~isgraphics(window_handle))
                window_handle = findall(groot, 'Name','NeuroPAL ID');
            end
            
            handle = window_handle;
        end
    end
end

