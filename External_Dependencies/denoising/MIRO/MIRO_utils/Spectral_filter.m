function a = Spectral_filter(a,r1,r2,kmin,T,s,sampling,pad,is3D,sigma_z)

if is3D == 0
    
    if kmin < T
        
        a = padarray(a,pad,'replicate','both');
        
        [X, Y] = meshgrid(1:size(a,2),1:size(a,1));
        Xc = ceil(size(a,2)/2);
        Yc = ceil(size(a,1)/2);
        
        r = sqrt((X-Xc).^2 + (Y-Yc).^2);
        filter = 1./(1+exp(6.*(r-r1)./(r2-r1)-6));
        filter = ifftshift(filter);
        
        amount = .1/s;
        amount = min(10/sampling,amount);
        
        for i = 1:size(a,3)
            
            a(:,:,i) = abs(ifft2(fft2(a(:,:,i)).*filter));
            
            b = (1+amount).*a(:,:,i) - amount.*imgaussfilt(a(:,:,i),kmin);
            a(:,:,i) = max(a(:,:,i),b);
            
        end
        
        a = removePad(a,pad);
        
    else
        sigma_xy = sampling/4.71;
        for i = 1:size(a,3)
            a(:,:,i) = imgaussfilt(a(:,:,i),sigma_xy);
            amount = .1/s;
            amount = min(10/sampling,amount);
            a(:,:,i) = max(a(:,:,i),imsharpen(a(:,:,i),'Radius',1,'Amount',amount,'Threshold',0));
        end
    end
    
else % 3D
    
    if kmin < T
        
        a = padarray(a,pad,'replicate','both');
        
        [X, Y, ~] = meshgrid(1:size(a,2),1:size(a,1),1:size(a,3));
        Xc = ceil(size(a,2)/2);
        Yc = ceil(size(a,1)/2);
        
        r = sqrt((X-Xc).^2 + (Y-Yc).^2);
        filter = 1./(1+exp(6.*(r-r1)./(r2-r1)-6));
        filter = ifftshift(filter);
        a = abs(ifftn(fftn(a).*filter));
        
        %         amount = .1/s;
        %         amount = min(10/sampling,amount);
        %         b = (1+amount).*a - amount.*imgaussfilt3(a,[kmin kmin sigma_z*T/kmin]);
        %         a = max(a,b);
        
        a = removePad(a,pad);
        
    end
    
    sigma_xy = sampling/4.71; % filtering in xy is already performed in lines 45-54, so here we use a smaller sigma_xy (4.71 = 2.355*2)
    sigma_z = sigma_z/2.355;
    a = imgaussfilt3(a,[sigma_xy, sigma_xy, sigma_z]);
    for i = 1:size(a,3)
        amount = .1/s;
        amount = min(10/sampling,amount);
        a(:,:,i) = max(a(:,:,i),imsharpen(a(:,:,i),'Radius',1,'Amount',amount,'Threshold',0));
    end
    
end

end