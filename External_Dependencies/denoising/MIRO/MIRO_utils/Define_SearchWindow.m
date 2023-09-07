% This function defines the position of the search window

function Window_location = Define_SearchWindow(noisyImg, BlockPoint, WindowSize, Blk_Size)

point_x = BlockPoint(1);
point_y = BlockPoint(2);

LX = point_x + Blk_Size/2 - WindowSize/2; 
LY = point_y + Blk_Size/2 - WindowSize/2;
RX = LX + WindowSize;
RY = LY + WindowSize;

if LX < 1
    LX = 1;
elseif RX > size(noisyImg,2)
    LX = size(noisyImg,2) - WindowSize;
end

if LY < 1
    LY = 1;
elseif RY > size(noisyImg,1)
    LY = size(noisyImg,1) - WindowSize;
end

Window_location = round([LX, LY]);

end