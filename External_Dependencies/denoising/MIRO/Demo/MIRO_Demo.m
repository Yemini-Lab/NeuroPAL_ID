%% MIRO Demo
% Demo file to demonstrate MIRO processing workflow. You can modify this 
% code and use with your own data.

%% Load Data

% Paths
FilePath_calibration = '.\Calibration_files\';
FilePath_data = '.\Raw_data\';
SavePath = '.\Results\';

% Load calibration data
load([FilePath_calibration, 'sCMOS_calibration.mat'],'Offset','Var','Gain');
Var = Var./(Gain^2);

% Load shearlet system
% This is not necessary but it can speed up processing if MIRO is called
% more than once. If you don't want to use it, just put shearletSystem = []
% or remove the corresponding line in the MIRO options
shearletSystem = getSLsys(Offset, 6);

% load colormap
load([FilePath_calibration, 'cmap.mat'],'glow');

% load images
D = dir([FilePath_data  '\*.mat']);

% experimental parameters
expT = [10 20 50 100];
lambda_ch1 = .461;
lambda_ch2 = .512;
lambda_ch3 = .599;

% load reference image
load('.\GT\GT');

S = zeros(length(expT),2,3);
P = zeros(length(expT),2,3);

for i = 1:length(D)

    disp(i)
    load([D(i).folder '\' D(i).name]);

    %% MIRO

    [miro1, Parameters] = MIRO(im1, ...
        'Offset',Offset,...
        'Gain',Gain,...
        'Var',Var,...
        'Lambda',lambda_ch1,...
        'DisplayImages',1, ...
        'Mode','s',...
        'h',6,...
        'Exp_time',expT(i)/1e3,...
        'shearletSystem',shearletSystem);
    colormap(glow)
    title(['Channel 1, T = ' num2str(expT(i)) ' ms'])
    pause(.01)

    miro2 = MIRO(im2,...
        'Offset',Offset,...
        'Gain',Gain,...
        'Var',Var,...
        'Lambda',lambda_ch2,...
        'DisplayImages',1,...
        'Mode','s',...
        'h',4,...
        'Exp_time',expT(i)/1e3,...
        'shearletSystem',shearletSystem);
    colormap(glow)
    title(['Channel 2, T = ' num2str(expT(i)) ' ms'])
    pause(.01)

    miro3 = MIRO(im3,...
        'Offset',Offset,...
        'Gain',Gain,...
        'Var',Var,...
        'Lambda',lambda_ch3,...
        'DisplayImages',1,...
        'Mode','s',...
        'h',4,...
        'Exp_time',expT(i)/1e3,...
        'k',0,...
        'shearletSystem',shearletSystem);
    colormap(glow)
    title(['Channel 3, T = ' num2str(expT(i)) ' ms'])
    pause(.01)

    %% Calculate SSIM & PSNR

    S_mean_ch1(1) = calculate_SSIM(gt1,im1);
    S_mean_ch1(2) = calculate_SSIM(gt1,miro1);

    S_mean_ch2(1) = calculate_SSIM(gt2,im2);
    S_mean_ch2(2) = calculate_SSIM(gt2,miro2);

    S_mean_ch3(1) = calculate_SSIM(gt3,im3);
    S_mean_ch3(2) = calculate_SSIM(gt3,miro3);


    P_mean_ch1(1) = calculate_PSNR(gt1,im1);
    P_mean_ch1(2) = calculate_PSNR(gt1,miro1);

    P_mean_ch2(1) = calculate_PSNR(gt2,im2);
    P_mean_ch2(2) = calculate_PSNR(gt2,miro2);

    P_mean_ch3(1) = calculate_PSNR(gt3,im3);
    P_mean_ch3(2) = calculate_PSNR(gt3,miro3);

    S(i,:,1) = S_mean_ch1;
    P(i,:,1) = P_mean_ch1;
    S(i,:,2) = S_mean_ch2;
    P(i,:,2) = P_mean_ch2;
    S(i,:,3) = S_mean_ch3;
    P(i,:,3) = P_mean_ch3;

    %% Save
    save(fullfile(SavePath,['MIRO_' num2str(expT(i),'%1.4u')]), 'miro1','miro2','miro3','Parameters',...
        'P_mean_ch1','P_mean_ch2','P_mean_ch3','S_mean_ch1','S_mean_ch2','S_mean_ch3');

    options.overwrite = true;
    saveastiff(uint16(miro1),fullfile(SavePath,['MIRO_' num2str(expT(i),'%1.4u') '_ch1.tif']),options);
    saveastiff(uint16(miro2),fullfile(SavePath,['MIRO_' num2str(expT(i),'%1.4u') '_ch2.tif']),options);
    saveastiff(uint16(miro3),fullfile(SavePath,['MIRO_' num2str(expT(i),'%1.4u') '_ch3.tif']),options);

end

%% Display results
f = figure('Name','Measured SSIM & PSNR','NumberTitle','off');
f.Position(3:4) = [700 420]; f.Color = [1 1 1];
tiledlayout(2,3);
for i = 1:3
nexttile
plot(expT,S(:,:,i),'o','MarkerFaceColor','auto','LineWidth',2)
title(['Channel ' num2str(i)])
ylabel SSIM
xlabel 'Exp. Time (ms)'
set(gca,'TickDir','out','FontSize',10,'Box','off')
end
for i = 1:3
nexttile
plot(expT,P(:,:,i),'o','MarkerFaceColor','auto','LineWidth',2)
ylabel PSNR
xlabel 'Exp. Time (ms)'
set(gca,'TickDir','out','FontSize',10,'Box','off')
end
