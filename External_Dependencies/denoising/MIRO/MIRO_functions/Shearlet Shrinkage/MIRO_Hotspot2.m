%% Remove hot spots
function I  = MIRO_Hotspot2(I,alpha,var)

%% Median filter

pad = [1 1];
I1 = padarray(I,pad,'replicate','both');
I_med = medfilt2(I1);
I_med = removePad(I_med,pad);
I2 = I;

%% Hotspot removal

T = (alpha).*sqrt(var+I_med);
I2(abs(I-I_med)>T) = I_med(abs(I-I_med)>T);
I2(I<=0) = 1e-6;

%% Pre-denoising
I = I2;

end