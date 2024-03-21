function matched_data = run_histmatch(image_data, RGBW)
    data = uint32(image_data);
    
    if size(data, 4) == 3
        data_RGB = data(:,:,:,RGBW(1:3));
    
        data_RGBW = zeros(size(data,1), size(data,2), size(data,3),4);
        data_RGBW(:,:,:,1:3) = data_RGB;
    else
        data_RGBW = data(:,:,:,RGBW);
    end
    
    data_RGBW = data_RGBW(:,:,:,1:3);
    matched_data = Methods.MatchHist(data_RGBW);

    %{
    % Initialize arrays to hold color values for the first image
    redChannel1 = data(:,:,:,RGBW(1));
    greenChannel1 = data(:,:,:,RGBW(2));
    blueChannel1 = data(:,:,:,RGBW(3));
    
    % Reshape the color channels into a single vector for histogram calculation for the first image
    redVector1 = redChannel1(:);
    greenVector1 = greenChannel1(:);
    blueVector1 = blueChannel1(:);

    % Initialize arrays to hold color values for the second image
    redChannel2 = matched_data(:,:,:,RGBW(1));
    greenChannel2 = matched_data(:,:,:,RGBW(2));
    blueChannel2 = matched_data(:,:,:,RGBW(3));

    % Reshape the color channels into a single vector for histogram calculation for the second image
    redVector2 = redChannel2(:);
    greenVector2 = greenChannel2(:);
    blueVector2 = blueChannel2(:);

    % Create histograms for each color channel of both images
    figure;
    
    % Red Channel Comparison
    subplot(3,2,1);
    histogram(redVector1, 256, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    title('Red Channel (Original)');
    xlim([0, 255]);
    
    subplot(3,2,2);
    histogram(redVector2, 256, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    title('Red Channel (HistMatched)');
    xlim([0, 255]);

    % Green Channel Comparison
    subplot(3,2,3);
    histogram(greenVector1, 256, 'FaceColor', 'g', 'FaceAlpha', 0.5);
    title('Green Channel (Original)');
    xlim([0, 255]);
    
    subplot(3,2,4);
    histogram(greenVector2, 256, 'FaceColor', 'g', 'FaceAlpha', 0.5);
    title('Green Channel (HistMatched)');
    xlim([0, 255]);

    % Blue Channel Comparison
    subplot(3,2,5);
    histogram(blueVector1, 256, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    title('Blue Channel (Original)');
    xlim([0, 255]);
    
    subplot(3,2,6);
    histogram(blueVector2, 256, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    title('Blue Channel (HistMatched)');
    xlim([0, 255]);
    %}

end