function newim = MatchHist(A)
    clear avg_hist;
    
    avg_hist = load('avg_hist.mat', 'avg_hist');
    avg_hist = avg_hist.avg_hist;
    
    im_flat = reshape(A, [], size(A,4));
    newim = zeros(size(A), 'uint64');
    Amax = max(A(:));
    M = zeros(3, Amax, 'uint64');
    
    for l = 1:3
    
        % Iterate over each channel in image array.
        chan_flat = im_flat(:,l);
    
        % Load target histogram for current channel.
        chan_hist = avg_hist(:,l);
    
        % Calculate maximum pixel intensity in current channel.
        usemax = double(max(chan_flat(:)));
    
        % Create bin edges for histogram of current color channel.
        useedges = linspace(0, usemax+1, usemax+2);
    
        % Calculate histogram of the current color channel.
        [hist, edges] = histcounts(chan_flat, useedges);
        %disp(['Histogram: ', num2str(hist)]);
        %disp(['Edges: ', num2str(edges)]);
    
        % Computes cumulative distribution function of current histogram.
        cdf = cumsum(hist) / numel(chan_flat);
        %disp(['CDF: ', num2str(cdf)]);
    
        % Computes cumulative sum of the target histogram.
        sumref = cumsum(double(transpose(chan_hist)));
    
        % Normalizes cumulatize sum of the target histogram to form its CDF.
        cdf_ref = sumref / max(sumref);
    
        % Iterate over each possible pixel intensity value to map each to
        % its target pixel intensity value.
        for idx = 1:usemax+1
            % Find intensity value in target histogram that has a CDF value
            % closest to current intensity value's CDF.
            [~, ind] = min(abs(cdf(idx)- cdf_ref));
    
            % Store intensity mapping.
            M(l, idx) = ind;
            %plot(M(l, :))
            %disp(['M(', num2str(l), ',', num2str(idx), ') = ', num2str(ind)]);
        end
    
        for i = 1:size(A,1) % Iterate over each pixel along first dim...
            for j = 1:size(A,2) % ...and second dim...
                for k=1:size(A,3) % ...and third dim...
                    % ...To repopulate the image with mapped intensity values.
                    newim(i,j,k,l) = M(l,A(i,j,k,l)+1)-1;
                end
            end
        end
    end
end