function debug_event(source, message, varargin)
if ~Program.Helpers.debug_enabled()
    return
end

if nargin > 2
    message = sprintf(message, varargin{:});
end

Program.Helpers.debug_log('[NPAL DEBUG][%s] %s\n', source, message);

try
    app = Program.app;
    if ~isempty(app) && isvalid(app)
        app.logEvent(source, message, 0);
    end
catch
end
end
