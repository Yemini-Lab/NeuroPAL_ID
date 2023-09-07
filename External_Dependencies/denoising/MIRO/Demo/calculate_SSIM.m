function [S_mean, S_std, S] = calculate_SSIM(ref,im)


ref = nrm(ref);
im = nrm(im);


for idx = 1:size(im,3)
    S(idx) = ssim(ref,im(:,:,idx));
end

S_mean = mean(S);
S_std = std(S);


end