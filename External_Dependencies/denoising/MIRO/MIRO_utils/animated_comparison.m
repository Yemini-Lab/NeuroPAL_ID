function out = animated_comparison(im1,im2,nframes)

im1 = im1(:,:,1);
im2 = im2(:,:,1);

sz = size(im1,2);
out = repmat(im1,1,1,nframes);
step = round(sz/nframes);
out(:,:,end) = im2;

for i = 2:nframes-1
    idx = min(sz,i*step);
    out(:,1:idx,i) = im2(:,1:idx);
end


end