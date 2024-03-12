function newim = MatchHist(A)
    clear avg_hist;

    avg_hist = load('avg_hist.mat', 'avg_hist');
    avg_hist = avg_hist.avg_hist;
    
    im_flat = reshape(A, [], size(A,4));
    
    newim = zeros(size(A), 'uint32');

    Amax = max(A(:));

    M = zeros(3, Amax, 'uint32');
    
    for l = 1:size(A,4)
        chan_flat = im_flat(:,l);
        %chan_ref_flat = ref_flat(:,l);
        chan_hist = avg_hist(:,l);
    
        usemax = double(max(chan_flat(:)));
        %refmax = max(chan_ref_flat(:));
    
        useedges = linspace(0, usemax+1, usemax+2);

        [hist, edges] = histcounts(chan_flat, useedges);
        %refhist = histcounts(chan_ref_flat, refmax);
    
        cdf = cumsum(hist) / numel(chan_flat);
        %cdf_ref = cumsum(refhist) / numel(chan_ref_flat);
    
        sumref = cumsum(double(transpose(chan_hist)));
    
        cdf_ref = sumref / max(sumref);
   
        for idx = 1:usemax+1
            [~, ind] = min(abs(cdf(idx)- cdf_ref));
            M(l, idx) = ind;
    
        end
    
        for i = 1:size(A,1)
            for j = 1:size(A,2)
                for k=1:size(A,3)
                    newim(i,j,k,l) = M(l,A(i,j,k,l)+1)-1;
                end
            end
        end
    end
end