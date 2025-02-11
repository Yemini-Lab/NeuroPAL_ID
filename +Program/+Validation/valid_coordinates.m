function valid_coordinates(varargin)
    app = Program.app;

    if nargin == 0
        t = round(app.tSlider.Value);
    elseif app.OverlaylastIDdframeCheckBox_2.Value
        earlier_frames = app.id_frames(app.id_frames < app.tSlider.Value);
        t = max(earlier_frames);
    end
   
    if ~exist ('z', 'var')
        z = round(app.hor_zSlider.Value);
    end
    
    if ~exist('y', 'var')
        y = round(app.xSlider.Value);
    end
    
    if ~exist ('x', 'var')
        x = round(app.video_info.ny-app.ySlider.Value);
    end
end

