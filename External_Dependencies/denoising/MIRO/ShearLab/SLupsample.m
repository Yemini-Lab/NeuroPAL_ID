function arrayUpsampled = SLupsample(array, dims, nZeros)
%SLUPSAMPLE Summary of this function goes here
%   Detailed explanation goes here
    sz = size(array);
    szUpsampled = sz;
    szUpsampled(dims) = (szUpsampled(dims)-1).*(nZeros+1) + 1;
    if isa(array,'gpuArray')
        if verLessThan('distcomp','6.1')
            arrayUpsampled = parallel.gpu.GPUArray.zeros(szUpsampled);
        else
           arrayUpsampled = gpuArray.zeros(szUpsampled);
        end
    else
        arrayUpsampled = zeros(szUpsampled);
    end
    S.type = '()';
    S.subs = cell(1,length(szUpsampled));
    
    for k = 1:length(sz) 
        S.subs{k} = ':';        
    end
    for k = 1:length(dims)     
        S.subs{dims(k)} = 1:(nZeros(k)+1):szUpsampled(dims(k));    
    end
    arrayUpsampled = subsasgn(arrayUpsampled,S,array);
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
