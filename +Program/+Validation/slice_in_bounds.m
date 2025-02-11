function slice_in_bounds(z)
    app = Program.app;
    if z > app.video_info.nz || z < 0
        uiconfirm(Program.window,'Target slice exceeds video slice count.','Error');
        return
    end
end

