function is_in_bounds = video_bounds(cursor)
    app = Program.app;
    is_in_x = 1 < cursor.x && cursor.x < app.video_info.nx;
    is_in_y = 1 < cursor.y && cursor.y < app.video_info.ny;
    is_in_z = 1 < cursor.z && cursor.z < app.video_info.nz;
    is_in_bounds = is_in_x && is_in_y && is_in_z;
end

