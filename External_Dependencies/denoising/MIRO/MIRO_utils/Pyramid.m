% This function generates a cell array containing n copies of the input image
% scaled by a certain factor one from the other.
function P = Pyramid(img,n)

P = cell(n,1);

P{1} = impyramid(img,'reduce');
for i = 2:n
    P{i} = impyramid(P{i-1},'reduce');
end

end