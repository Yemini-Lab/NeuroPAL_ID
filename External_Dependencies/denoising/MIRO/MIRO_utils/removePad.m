function b = removePad(a,pad)

y1 = pad(1);
y2 = y1 - 1;

if length(pad)==1
    x1 = pad(1);
else
    x1 = pad(2);
end

x2 = x1 - 1;

if length(pad) == 3
    a(:,:,1:pad(3)) = [];
    a(:,:,end-pad(3)+1:end) = [];
end

sz1 = size(a,1)-2*y1;
sz2 = size(a,2)-2*x1;
sz3 = size(a,3);
b = zeros(sz1,sz2,sz3);

for i = 1:size(a,3)
    tmp = a(:,:,i);
    tmp(1:y1,:) = [];
    tmp(:,1:x1) = [];
    tmp(end-y2:end,:) = [];
    tmp(:,end-x2:end) = [];
    
    b(:,:,i) = tmp;
end

end