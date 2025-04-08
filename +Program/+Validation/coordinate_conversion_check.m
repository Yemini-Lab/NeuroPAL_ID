function pos_arr = coordinate_conversion_check(pos_arr)

    if max(pos_arr(:, 2)) <= app.video_info.nx/10
        %pos_arr(:, 2) = max(floor(pos_arr(:, 2)*app.video_info.nx- 1e-6), 0);
        pos_arr(:, 2) = (pos_arr(:, 2) * app.video_info.nx);
    end

    if max(pos_arr(:, 3)) <= app.video_info.ny/10
        %pos_arr(:, 3) = max(floor(pos_arr(:, 3)*app.video_info.ny- 1e-6), 0);
        pos_arr(:, 3) = (pos_arr(:, 3) * app.video_info.ny);
    end
    
    if mean(pos_arr(:, 4)) <= app.video_info.nz/5
        %pos_arr(:, 4) = max(floor(pos_arr(:, 4)*app.video_info.nz- 1e-6), 0);
        pos_arr(:, 4) = (pos_arr(:, 4) * app.video_info.nz);
    end
end

