function out = SLdshear(in,k,axis)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    if k == 0
        out = in;
        return;
    end
    rows = size(in,1);
    cols = size(in,2);

    out = zeros(size(in));
    if axis == 1
        for col = 1:cols
            out(:,col) = circshift(in(:,col),[k * (floor(cols/2)+1-col) 0]);
        end
    else        
        for row = 1:rows
            out(row,:) = circshift(in(row,:),[0 k * (floor(rows/2)+1-row)]);
        end
    end
end

%
%  Copyright (c) 2014. Rafael Reisenhofer
%
%  Part of ShearLab3D v1.1
%  Built Mon, 10/11/2014
%  This is Copyrighted Material
%
%  If you use or mention this code in a publication please cite the website www.shearlab.org and the following paper:
%  G. Kutyniok, W.-Q. Lim, R. Reisenhofer
%  ShearLab 3D: Faithful Digital SHearlet Transforms Based on Compactly Supported Shearlets.
%  ACM Trans. Math. Software 42 (2016), Article No.: 5.
