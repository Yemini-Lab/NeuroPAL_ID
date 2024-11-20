function set_grid_width(grid, idx, val)
    temp_width = grid.ColumnWidth;
    temp_width(idx) = {val};
    grid.ColumnWidth = temp_width;
end

