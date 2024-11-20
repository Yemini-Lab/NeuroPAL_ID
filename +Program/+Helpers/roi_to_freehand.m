function freehand_roi = roi_to_freehand(roi)
    if ~isa(roi, 'images.roi.Freehand')
        xmin = roi.Position(1);
        ymin = roi.Position(2);
        width = roi.Position(3);
        height = roi.Position(4);
        
        tr = [xmin + width, ymin];
        tl = [xmin, ymin];
        bl = [xmin, ymin + height];
        br = [xmin + width, ymin + height];
    
        fh_pos = [tr; tl; bl; br];
        
    else
        fh_pos = roi.Position;
    end
    
    freehand_roi = images.roi.Freehand(roi.Parent, 'Position', fh_pos, ...
        'FaceAlpha', 0.4, 'Color', [0.1 0.1 0.1], 'StripeColor', 'm', 'InteractionsAllowed', 'translate', 'Tag', 'rot_roi');
    
    delete(roi)
end

