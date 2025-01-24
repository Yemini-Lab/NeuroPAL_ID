function xy_arr = rotate_xy_arr(xy_arr, theta)
    R = [cosd(theta), -sind(theta); sind(theta), cosd(theta)];

    roi_center = mean(xy_arr);
    xy_arr = ((xy_arr - roi_center) * R') + roi_center;
end

