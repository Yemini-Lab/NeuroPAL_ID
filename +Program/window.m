function handle = window()
    persistent window_handle

    if any(isempty(window_handle)) || any(~isgraphics(window_handle))
        window_handle = findall(groot, 'Name','NeuroPAL ID');
    end
    
    handle = window_handle;
end

