function [img, UserSelectedCancel, filename] = ReadTiff(varargin)

UserSelectedCancel = 0;
default = cell(4,1);

for i = 1:length(varargin)
    default{i} = varargin{i};
end

filename = default{1};

if isempty(filename)

    [file,path] = uigetfile('.\*.tif*');
    filename = fullfile(path,file);
    if isequal(file,0)
        disp('User selected Cancel');
        UserSelectedCancel = 1;
        img = [];
        return
    end
end


ROIy = default{2};
ROIx = default{3};
nFrames = default{4};

info = imfinfo(filename);

if isempty(nFrames)
    nFrames = length(info);
end

if isempty(ROIy)
    ROIy = [1 info(1).Height];
end

if isempty(ROIx)
    ROIx = [1 info(1).Width];
end

img = zeros([1+diff(ROIy) 1+diff(ROIx)]);
disp(['loading ' filename '...'])
tic
disp('progress:  00')
for n = 1:nFrames
    perc = sprintf('\b\b\b\b%s%%',num2str(round(n/nFrames*100),'%02.0f')) ;
    disp(perc)
    img(:,:,n) = imread(filename,n,'PixelRegion',{[ROIy(1),ROIy(2)],[ROIx(1),ROIx(2)]});
end
T = toc;
msg = sprintf('\b\n...image loaded in %ss',num2str(T));
disp(msg) %#ok<*DSPS>

end