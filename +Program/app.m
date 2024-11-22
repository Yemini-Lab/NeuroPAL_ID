function handle = app()
    persistent app_handle

    if any(isempty(app_handle)) || any(isa(app_handle, "handle")) && any(~isvalid(app_handle))
        window_handle = Program.window();
        app_handle = window_handle.RunningAppInstance;
    end

    handle = app_handle;
end

