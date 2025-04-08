function handle = app()
    %APP Retrieve a persistent handle to the running application instance.
    %
    %   handle = app() checks if the persistent variable app_handle is empty
    %   or invalid, and if so, obtains the current running application instance
    %   from Program.window(). This ensures that only one reference to the
    %   application is kept and reused throughout the program.
    %
    %   OUTPUT:
    %       handle - The handle to the running application instance (if it
    %                exists), or an empty value otherwise.
    %
    %   See also: Program.window

    % Define a persistent variable that retains its value between function calls
    persistent app_handle

    % If the handle is empty or invalid, refresh it from the Program.window
    if any(isempty(app_handle)) || ...
       (any(isa(app_handle, "handle")) && any(~isvalid(app_handle)))
        window_handle = Program.window();
        app_handle = window_handle.RunningAppInstance;
    end

    % Return the persistent handle
    handle = app_handle;
end
