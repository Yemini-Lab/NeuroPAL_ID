% This function generates the coordinates of the blocks
%%
function m_blockPoint = Locate_blk(i, j, blk_step, block_Size, width, height)

if (i-1)*blk_step + block_Size < width
    point_x = 1+(i-1)*blk_step;
else
    point_x = width - block_Size + 1;
end

if (j-1)*blk_step + block_Size < height
    point_y = 1 + (j-1)*blk_step;
else
    point_y = height - block_Size + 1;
end

m_blockPoint = [point_x, point_y];

end
