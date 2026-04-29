function synced = sync_main_from_processing(app)
if nargin < 1 || isempty(app)
    app = Program.app;
end

synced = Program.Helpers.sync_main_display_from_processing(app, true);
end
