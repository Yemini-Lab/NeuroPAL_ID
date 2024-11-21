function ss_arr = screenshot()
    window_fig = Program.GUIHandling.window_fig;

    robot = java.awt.Robot();
    pos = window_fig.Position;
    rect = java.awt.Rectangle(pos(1),pos(2),pos(3),pos(4));
    cap = robot.createScreenCapture(rect);

    rgb = typecast(cap.getRGB(0,0,cap.getWidth,cap.getHeight,[],0,cap.getWidth),'uint8');

    ss_arr = zeros(cap.getHeight,cap.getWidth,3,'uint8');
    ss_arr(:,:,1) = reshape(rgb(3:4:end),cap.getWidth,[])';
    ss_arr(:,:,2) = reshape(rgb(2:4:end),cap.getWidth,[])';
    ss_arr(:,:,3) = reshape(rgb(1:4:end),cap.getWidth,[])';
end

