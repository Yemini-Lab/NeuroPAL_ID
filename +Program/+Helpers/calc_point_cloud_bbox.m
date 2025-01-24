function pc_struct = calc_point_cloud_bbox(xy_arr)
        pos = struct('xy', {xy_arr});
        x = xy_arr(:, 1);
        y = xy_arr(:, 2);

        pos.left = min(x);
        pos.right = max(x);
        pos.bottom = max(y);
        pos.top = min(y);

        pos.height = pos.top - pos.bottom;
        pos.width = pos.right - pos.left;
        pos.horizontal_center = pos.left + pos.width/2;
        pos.vertical_center = pos.bottom + pos.height/2;

        pos.corners = struct( ...
            'tl', {[pos.left, pos.top]}, ...
            'tr', {[pos.right, pos.top]}, ...
            'bl', {[pos.left, pos.bottom]}, ...
            'br', {[pos.right, pos.bottom]});

        pc_struct = pos;
end

