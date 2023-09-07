function [wedge, bandpass, lowpass] = SLgetWedgeBandpassAndLowpassFilters2D(rows,cols,shearLevels,directionalFilter,scalingFilter,waveletFilter,scalingFilter2)
%SLgetWedgeBandpassAndLowpassFilters2D

%% check number of input parameters and assign default values
if nargin < 3
    error('Not enough input parameters!');
end
if nargin < 7
    if nargin < 6
        if nargin < 5
            if nargin < 4
                directionalFilter = modulate2(dfilters('dmaxflat4','d')./sqrt(2),'c');                
            end
            scalingFilter = [0.0104933261758410,-0.0263483047033631,-0.0517766952966370,...
                             0.276348304703363,0.582566738241592,0.276348304703363,...
                            -0.0517766952966369,-0.0263483047033631,0.0104933261758408];            
        end
        waveletFilter = MirrorFilt(scalingFilter);        
    end
    scalingFilter2 = scalingFilter;    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   all page and equation numbers refer to "ShearLab 3D: Faithful Digital %
%   Shearlet Transforms based on Compactly Supported Shearlets"           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize variables

%get number of scales
NScales = length(shearLevels);

%allocate bandpass and wedge filters
bandpass = zeros(rows,cols,NScales); %these filters partition the frequency plane into different scales
wedge = cell(1,max(shearLevels)+1); %these filters partition the frequency plane into different directions

%normalize filters
directionalFilter = directionalFilter/sum(abs(directionalFilter(:))); %this filter corresponds to the time domain representation of the trigonometric polynomial P (see equation (13) on page 12)

%% compute 1D high and lowpass filters at different scales

filterHigh = cell(1,NScales); %filterHigh{NScales} = g_1 and filterHigh{1} = g_J (compare page 11) 
filterLow = cell(1,NScales); %we have filterLow{NScales} = h_1 and filterLow{1} = h_J (compare page 11)
filterLow2 = cell(1,max(shearLevels)+1); %typically, we have filterLow2{max(shearLevels)+1} = filterLow{NScales}, i.e. filterLow2{NScales} = h_1 (compare page 11)

%initialize wavelet highpass and lowpass filters
filterHigh{size(filterHigh,2)} = waveletFilter; %this filter is typically chosen to form a quadrature mirror filter pair with scalingFilter and corresponds to g_1 on page 11
filterLow{size(filterLow,2)} = scalingFilter;  %this filter corresponds to h_1 on page 11
filterLow2{size(filterLow2,2)} = scalingFilter2; %this filter is typically chosen to be equal to scalingFilter and provides the y-direction for the tensor product constructing the 2D wavelet filter w_j on page 14


%compute wavelet high- and lowpass filters associated with a 1D digital
%wavelet transform on NScales scales, e.g., we compute h_1 to h_J and g_1
%to g_J (compare page 11) with J = NScales.
for j = size(filterHigh,2)-1:-1:1
    filterLow{j} = conv(filterLow{size(filterLow,2)},SLupsample(filterLow{j+1},2,1));
    filterHigh{j} = conv(filterLow{size(filterLow,2)},SLupsample(filterHigh{j+1},2,1));
end
for j = size(filterLow2,2)-1:-1:1
    filterLow2{j} = conv(filterLow2{size(filterLow2,2)},SLupsample(filterLow2{j+1},2,1));
end
%% construct bandpass filters for scales 1 to NScales
for j = 1:size(filterHigh,2)
    bandpass(:,:,j) = fftshift(fft2(ifftshift(SLpadArray(filterHigh{j},[rows,cols]))));
end


%% construct wedge filters for achieving directional selectivity.
% as the entries in the shearLevels array describe the number of differently 
% sheared atoms on a certain scale, a different set of wedge 
% filters has to be constructed for each value in shearLevels.

for shearLevel = unique(shearLevels)
    
    %preallocate a total of floor(2^(shearLevel+1)+1) wedge filters, where
    %floor(2^(shearLevel+1)+1) is the number of different directions of
    %shearlet atoms associated with the horizontal (resp. vertical)
    %frequency cones.    
    wedge{shearLevel+1} = zeros(rows,cols,floor(2^(shearLevel+1)+1)); %plus one for one unsheared shearlet
    
    %upsample directional filter in y-direction. by upsampling the directional
    %filter in the time domain, we construct repeating wedges in the
    %frequency domain ( compare abs(fftshift(fft2(ifftshift(directionalFilterUpsampled)))) and 
    %abs(fftshift(fft2(ifftshift(directionalFilter)))) ). 
    directionalFilterUpsampled = SLupsample(directionalFilter,1,2^(shearLevel+1)-1);
    
    %remove high frequencies along the y-direction in the frequency domain.
    %by convolving the upsampled directional filter with a lowpass filter in y-direction, we remove all
    %but the central wedge in the frequency domain. 
    wedgeHelp = conv2(directionalFilterUpsampled,filterLow2{size(filterLow2,2)-shearLevel}');
    wedgeHelp = SLpadArray(wedgeHelp,[rows,cols]);
    %please note that wedgeHelp now corresponds to
    %conv(p_j,h_(J-j*alpha_j/2)') in the language of the paper. to see
    %this, consider the definition of p_j on page 14, the definition of w_j
    %on the same page an the definition of the digital sheralet filter on
    %page 15. furthermore, the g_j part of the 2D wavelet filter w_j is
    %invariant to shearings, hence it suffices to apply the digital shear
    %operator to wedgeHelp.
    
    %% application of the digital shear operator (compare equation (22))
    
    %upsample wedge filter in x-direction. this operation corresponds to
    %the upsampling in equation (21) on page 15.
    wedgeUpsampled = SLupsample(wedgeHelp,2,2^shearLevel-1);
    
    %convolve wedge filter with lowpass filter, again following equation
    %(21) on page 14.
    lowpassHelp = SLpadArray(filterLow2{size(filterLow2,2)-max(shearLevel-1,0)},size(wedgeUpsampled));
    if shearLevel >= 1
        wedgeUpsampled = fftshift(ifft2(ifftshift(fftshift(fft2(ifftshift(lowpassHelp))).*fftshift(fft2(ifftshift(wedgeUpsampled))))));
    end
    lowpassHelpFlip = fliplr(lowpassHelp);
    
    %traverse all directions of the upper part of the left horizontal
    %frequency cone
    for k = -2^shearLevel:2^shearLevel
        %resample wedgeUpsampled as given in equation (22) on page 15.
        wedgeUpsampledSheared = SLdshear(wedgeUpsampled,k,2);
        %convolve again with flipped lowpass filter, as required by equation (22) on
        %page 15.
        if shearLevel >= 1
            wedgeUpsampledSheared = fftshift(ifft2(ifftshift(fftshift(fft2(ifftshift(lowpassHelpFlip))).*fftshift(fft2(ifftshift(wedgeUpsampledSheared))))));
        end
        %obtain downsampled and renormalized and sheared wedge filter in the
        %frequency domain, according to equation (22) on page 15
        wedge{shearLevel+1}(:,:,fix(2^shearLevel)+1-k) = fftshift(fft2(ifftshift(2^shearLevel*wedgeUpsampledSheared(:,1:2^shearLevel:2^shearLevel*cols))));
    end
end

%% compute low pass filter of shearlet system
lowpass = fftshift(fft2(ifftshift(SLpadArray(filterLow{1}'*filterLow{1},[rows,cols]))));

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
