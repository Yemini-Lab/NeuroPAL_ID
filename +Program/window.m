function handle = window()
    %WINDOW Retrieve a persistent handle to the figure named 'NeuroPAL ID'.
    %
    %   handle = window() attempts to locate any figure with the 'Name'
    %   property set to 'NeuroPAL ID'. If the function's persistent 
    %   variable 'window_handle' is empty or invalid, it calls FINDALL 
    %   to refresh this handle. Subsequent calls reuse the cached handle.
    %
    %   OUTPUT:
    %       handle - The figure handle with the specified name, or empty
    %                if none is found.
    %
    %   See also: findall, groot

    % Define a persistent variable that caches the figure handle across calls
    persistent window_handle

    % If the cached handle is empty or no longer a valid graphics object,
    % attempt to locate the figure named 'NeuroPAL ID'
    if any(isempty(window_handle)) || any(~isgraphics(window_handle))
        window_handle = findall(groot, 'Name', 'NeuroPAL ID');
    end
    
    % Return the handle to the caller
    handle = window_handle;
end
