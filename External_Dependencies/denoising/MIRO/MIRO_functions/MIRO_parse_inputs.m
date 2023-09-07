% MIRO inizialization file

function [im, Parameters, Transforms] = MIRO_parse_inputs(varargin)

inputcellarray = varargin{1};
if ~isempty(inputcellarray), im = inputcellarray{1};
else, im = []; end

%% Read File
Parameters.UserSelectedCancel = 0;
if ischar(im), [im, Parameters.UserSelectedCancel] = ReadTiff(im); end
if ~isfloat(im), im = double(im); end

%% Load default parameters

MIRO_Default_Parameters;

%% Parameters assignment
for idx = 2:2:length(inputcellarray)

    if strcmp(inputcellarray{idx},'Parameters')
        %         Parameters = inputcellarray{idx+1};
        fldnames = fieldnames(inputcellarray{idx+1});
        for i = 1:length(fldnames)
            Parameters.(fldnames{i}) = inputcellarray{idx+1}.(fldnames{i});
        end
    else
        Parameters.(matlab.lang.makeValidName(inputcellarray{idx})) = inputcellarray{idx+1};
    end

end

%% Offset, Var & Gain check

Parameters.Gain(Parameters.Gain<1) = 1; % the pixel values of the selected gain map should be greater than 1.

Parameters.PixelSize = Parameters.CameraPixelSize/Parameters.Magnification*Parameters.Binning;  %Pixel Size in the image plane (in um)
Parameters.Sampling = .61*Parameters.Lambda/Parameters.NA/Parameters.PixelSize/Parameters.SR_lateral;

if Parameters.DarkCurrent ~= 0 || Parameters.Exp_time ~= 0
    I_dark = Parameters.DarkCurrent.*Parameters.ExpTime;
    Parameters.Var = Parameters.Var + I_dark;
    Parameters.Offset = Parameters.Offset + I_dark.*Parameters.Gain;
end

if size(Parameters.Var,1) == 1
    Parameters.Var = Parameters.Var*ones(size(im(:,:,1)));
end

Parameters.max_est_method = 0;
%% Matrices for dct transform
if Parameters.OptionalFilter == 2
    Transforms.D_2d = dctmtx(Parameters.Wien(1));
    % matrix for 3rd dim transform
    Transforms.D_3d = dctmtx(Parameters.Wien(4));
    % matrix for needle patches
    Transforms.DD_2d = dctmtx(Parameters.Wien(6));
else
    Transforms = [];
end
%%
clear textprogressbar

end