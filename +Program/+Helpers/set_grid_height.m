function set_grid_height(grid, idx, val)
    temporary_height = grid.RowHeight;
    temporary_height(idx) = {val};
    grid.RowHeight = temporary_height;
end

