%% STD estimation using weighted non-local means (Kullback–Leibler divergence)

function [sigma] = Sigma_estimation(im1)

w = zeros(size(im1,1));
s = zeros(size(im1,1));
for count1 = 1:size(im1,1)
    for count2 = 1:size(im1,1)
        w(count1,count2) = mean2(abs(im1(count1,:,:) - im1(count2,:,:))...
            .*abs(log1p(complex(im1(count1,:,:))) - log1p(complex(im1(count2,:,:)))));
        w(count1,count2) = exp(-w(count1,count2));
    end
end
%         W = sum(w,2);
for z = 1:size(im1,1)
    for z2 = 1:size(im1,1)
        
        s(z,z2) = mean2(w(z,z2).*im1.^2);
        
    end
end

S = sqrt(mean(s,2));
sigma = repmat(S,1,size(im1,2),size(im1,3));

end