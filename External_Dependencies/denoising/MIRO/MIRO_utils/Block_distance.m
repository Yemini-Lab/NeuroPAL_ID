function [Distance] = Block_distance(im1, im2)

% Distance calculated using the Frobenius Norm
blk_size = size(im1,1);
Distance = (norm(im1-im2,'fro').^2)/(blk_size.^2);

% 'L'
%         Distance = im1.*log(im1) + im2.*log(im2) - (im1 + im2).*log((im1 + im2)./2);
%         Distance = mean2(abs(Distance));
% % 'KL'  % Kullback–Leibler divergence
%         Distance = (im1 - im2).*log(im1./im2)./2;
%         Distance = mean2(abs(Distance));

end