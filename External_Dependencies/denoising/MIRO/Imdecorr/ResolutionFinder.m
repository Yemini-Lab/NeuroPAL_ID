function [kcMax, SNR] = ResolutionFinder(image)

%% set path and load some data
% addpath('funcs')
% image = img0;%double(loadData('test_image.tif'));

if mod(size(image,1),2) == 1
    image(end,:) = [];
end

if mod(size(image,2),2) == 1
    image(:,end) = [];
end


tile_size = 64;
if size(image,3) == 1 && size(image,1) >= 2*tile_size && size(image,1) >= 2*tile_size
    w = floor(size(image,2)/tile_size);
    h = floor(size(image,1)/tile_size);
    image(h*tile_size+1:end,:) = [];
    image(:,w*tile_size+1:end) = [];
    reshape(image,[tile_size,tile_size,h*w]);
end

% pps = 15; % projected pixel size of 15nm
% typical parameters for resolution estimate
Nr = 25; % 50
Ng = 10; % 100
r = linspace(0,1,Nr);
% GPU = 0;

%% apodize image edges with a cosine function over 20 pixels
image = apodImRect(image,40);

%% compute resolution

% figID = 100;
% if GPU 
%     [kcMax,SNR] = getDcorr(gpuArray(image),r,Ng); gpuDevice(1);
% else
    [kcMax,SNR] = getDcorr(image,r,Ng);
% end

% disp(['kcMax : ',num2str(kcMax,3),', A0 : ',num2str(SNR,3)])
%% sectorial resolution
% 
% Na = 8; % number of sectors
% figID = 101;
% if GPU
%     [kcMax,A0] = getDcorrSect(gpuArray(image),r,Ng,Na,figID); gpuDevice(1);
% else
%     [kcMax,A0] = getDcorrSect(image,r,Ng,Na,figID);
% end

%% Local resolution map
% 
% tileSize = 200; % in pixels
% tileOverlap = 0; % in pixels
% figId = 103;
% 
% if GPU 
%     [kcMap,A0Map] = getLocalDcorr(gpuArray(image),tileSize,tileOverlap,r,Ng,figID);gpuDevice(1);
% else
%     [kcMap,A0Map] = getLocalDcorr(image,tileSize,tileOverlap,r,Ng,figID);
% end

end