function frame_in_bounds(t)
    app = Program.app;
    if t > app.video_info.nt || t < 0
        uiconfirm(Program.window,'Target frame exceeds video frame count.','Error');
        return
    end
end

