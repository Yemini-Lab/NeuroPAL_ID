%% Remove Hot Spots
function [I, Imax, Imin]  = MIRO_Hotspot(I,alpha,var,method)

%% Median filter
pad = [2, 2];
I1 = padarray(I,pad,'replicate','both');
I_med = medfilt2(I1);
I_med = removePad(I_med,pad);
I2 = I;

%% Hotspot removal
T = alpha.*sqrt(medfilt2(var)+I_med);
I2(abs(I-I_med)>T) = I_med(abs(I-I_med)>T);
I2(I<=0) = 1e-6;

%% Max estimation (outlier-robust)
switch method
    case 0
        Imax = max(I(:));
        Imin = min(I(:));
        
    case 1
        % method 1
        sorted_values =sort(I_med(:),'descend');
        nValues = min(length(I(:)),max(100,ceil(mean2(var)/std2(I_med)*1e1)));
        Imax = mean(sorted_values(1:nValues));
        
        % min_values =sort(I_med(:),'ascend');
        Imin = mean(sorted_values((end-nValues+1):end));
        
    case 2
        % method 2
        sorted_values =sort(I2(:),'descend');
        nValues = min(length(I2(:)),max(10,ceil(mean2(var)/std2(I_med)*1e1)));
        Imax = mean(sorted_values(1:nValues));
        
        T = mean2(I_med)+ min(mean2(var),mean2(std2(I_med)));
        Imin = floor(mean(I_med(I_med<T),'all'));
        
    case 3
        % method 3
        a = prctile(I,98,'all');
        Imax = mean(I(I>=a));
        
        a = prctile(I,2,'all');
        Imin = mean(I(I<=a));
        
    case 4
        % method 4
        a = prctile(I,99,'all');
        Imax = a;
        
        a = prctile(I,1,'all');
        Imin = a;
        
    case 5
        % method 5
        sorted_values =sort(I2(:),'descend');
        nValues = min(length(I2(:)),max(10,ceil(mean2(var)/std2(I_med)*1e1)));
        Imax = mean(sorted_values(1:nValues));
        
        Imin = min(I_med,[],'all');
        
    case 6
        %method 6
        [N,ed] = histcounts(I);
        Imax = ed(end-1);
        
        [~, idx_max] = max(N);
        Imin = ed(idx_max);
        
    case 7
        % method 7
        sorted_values =sort(I2(:),'descend');
        nValues = min(length(I2(:)),max(10,ceil(mean2(var)/std2(I_med)*1e1)));
        Imax = mean(sorted_values(1:nValues));
        
        T = mean2(I_med)+ min(mean2(var),mean2(std2(I_med)));
        Imin = (mean(I_med(I_med<T),'all'));
        
end

%%
I = I2;
Imax = Imax - Imin;

end