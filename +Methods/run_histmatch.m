function matched_data = run_histmatch(image_data, RGBW)
    data = uint64(Methods.Preprocess.zscore_frame(image_data));
    
    if size(data, 4) == 3
        data_RGB = data(:,:,:,RGBW(1:3));
    
        data_RGBW = zeros(size(data,1), size(data,2), size(data,3),4);
        data_RGBW(:,:,:,1:3) = data_RGB;
    else
        data_RGBW = data(:,:,:,RGBW);
    end
    
    data_RGBW = data_RGBW(:,:,:,1:3);
    matched_data = Methods.MatchHist(data_RGBW);
    matched_data = Methods.Preprocess.zscore_frame(uint16(matched_data));
end