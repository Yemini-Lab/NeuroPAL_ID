function draw_frames(app, frames)
if nargin < 1 || isempty(app)
    app = Program.app;
end

Program.Routines.Processing.local_draw_frame(app, app.proc_xyAxes, frames.xy);

if app.ProcPreviewZslowCheckBox.Value
    Program.Routines.Processing.local_draw_frame(app, app.proc_xzAxes, frames.xz);
    Program.Routines.Processing.local_draw_frame(app, app.proc_yzAxes, frames.yz);
else
    Program.Routines.Processing.local_draw_frame(app, app.proc_xzAxes, []);
    Program.Routines.Processing.local_draw_frame(app, app.proc_yzAxes, []);
end
end
