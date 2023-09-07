function [ directionalFilter,scalingFilter,waveletFilter,scalingFilter2 ] = SLcheckFilterSizes(rows,cols,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2)
%SLcheckFilterSizes

%% configuration 1
filterSetup{1}.directionalFilter = directionalFilter;
filterSetup{1}.scalingFilter = scalingFilter;
filterSetup{1}.waveletFilter = waveletFilter;
filterSetup{1}.scalingFilter2 = scalingFilter2;


%% configuration 2
filterSetup{2}.directionalFilter = modulate2(dfilters('dmaxflat4','d')./sqrt(2),'c');
filterSetup{2}.scalingFilter = [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,...
                             0.276348304703363,0.582566738241592,0.276348304703363,...
                            -0.0517766952966369,-0.0263483047033631,0.0104933261758408];
filterSetup{2}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{2}.scalingFilter2 = scalingFilter;


%% configuration 3
filterSetup{3}.directionalFilter = modulate2(dfilters('cd','d')./sqrt(2),'c');
filterSetup{3}.scalingFilter = [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,...
                             0.276348304703363,0.582566738241592,0.276348304703363,...
                            -0.0517766952966369,-0.0263483047033631,0.0104933261758408];
filterSetup{3}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{3}.scalingFilter2 = scalingFilter;


%% configuration 4
filterSetup{4}.directionalFilter = modulate2(dfilters('cd','d')./sqrt(2),'c');
filterSetup{4}.scalingFilter = [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,...
                             0.276348304703363,0.582566738241592,0.276348304703363,...
                            -0.0517766952966369,-0.0263483047033631,0.0104933261758408];
filterSetup{4}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{4}.scalingFilter2 = scalingFilter;

%% configuration 5
filterSetup{5}.directionalFilter = modulate2(dfilters('cd','d')./sqrt(2),'c');
filterSetup{5}.scalingFilter = MakeONFilter('Coiflet',1);
filterSetup{5}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{5}.scalingFilter2 = scalingFilter;


%% configuration 6
filterSetup{6}.directionalFilter = modulate2(dfilters('cd','d')./sqrt(2),'c');
filterSetup{6}.scalingFilter = MakeONFilter('Daubechies',4);
filterSetup{6}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{6}.scalingFilter2 = scalingFilter;


%% configuration 7
filterSetup{7}.directionalFilter = modulate2(dfilters('oqf_362','d')./sqrt(2),'c');
filterSetup{7}.scalingFilter = MakeONFilter('Daubechies',4);
filterSetup{7}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{7}.scalingFilter2 = scalingFilter;



%% configuration 8
filterSetup{8}.directionalFilter = modulate2(dfilters('oqf_362','d')./sqrt(2),'c');
filterSetup{8}.scalingFilter = MakeONFilter('Haar');
filterSetup{8}.waveletFilter = MirrorFilt(scalingFilter);
filterSetup{8}.scalingFilter2 = scalingFilter;

success = 0;

for k = 1:8
    %% check 1
    lwfilter = length(filterSetup{k}.waveletFilter);
    lsfilter = length(filterSetup{k}.scalingFilter);
    lcheck1 = lwfilter;
    for j = 1:(length(shearLevels)-1)
        lcheck1 = lsfilter + 2*lcheck1 - 2;
    end
    if lcheck1 > cols || lcheck1 > rows
        continue;
    end
    
    %% check  2
    rowsdirfilter = size(filterSetup{k}.directionalFilter,1);
    colsdirfilter = size(filterSetup{k}.directionalFilter,2);
    lcheck2 = (rowsdirfilter-1)*2^(max(shearLevels)+1) + 1;
    
    lsfilter2 = length(filterSetup{k}.scalingFilter2);
    lcheck2help = lsfilter2;
    for j = 1:max(shearLevels)
        lcheck2help = lsfilter2 + 2*lcheck2help - 2;
    end
    lcheck2 = lcheck2help + lcheck2 - 1;
    if lcheck2 > cols || lcheck2 > rows || colsdirfilter > cols || colsdirfilter > rows
        continue;
    end
    success = 1;
    break;
end
directionalFilter = filterSetup{k}.directionalFilter;
scalingFilter = filterSetup{k}.scalingFilter;
waveletFilter = filterSetup{k}.waveletFilter;
scalingFilter2 = filterSetup{k}.scalingFilter2;
if success == 0
    error(['The specified Shearlet system is not available for data of size ', num2str(rows) ,'x',num2str(cols), '. Try decreasing the number of scales and shearings.']);
end
if success == 1 && k > 1
    warning(['The specified Shearlet system was not available for data of size ', num2str(rows) ,'x',num2str(cols), '. Filters were automatically set to configuration ',num2str(k),' (see SLcheckFilterSizes.m).']);
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
