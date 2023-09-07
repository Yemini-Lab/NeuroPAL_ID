function [Xrec, shearletSystem] = MIRO_Shearlet_thresholding(X,Var,shearletSystem,thresholdingFactor,mode,smp,tophat)
% Shearlet decomposition, microlocal thresholding and reconstruction

%% Shearlet decomposition
coeffs = SLsheardec2D(X,shearletSystem);

%% Shearlet shrinkage
switch mode
        
    case 's'
        Y = medfilt2(X,[3 3]);
        rms = shearletSystem.RMS;
        for i = 1:size(coeffs,3)
            T = (rms(i).*thresholdingFactor*.1).*abs(sqrt(Var + Y));
            coeffs(:,:,i) = (max(0,coeffs(:,:,i)-T) - max(0,-coeffs(:,:,i)-T));
        end

    case 'h'
        Y = medfilt2(X,[3 3]);
        rms = shearletSystem.RMS;
        for i = 1:size(coeffs,3)
            T = (rms(i).*thresholdingFactor).*abs(sqrt(Var + Y));
            coeffs(:,:,i) = coeffs(:,:,i).*(abs(coeffs(:,:,i)) > T);
        end
        
end

%% Reconstruction
Xrec = SLshearrec2D(coeffs,shearletSystem);
Xrec = max(Xrec,0);

if tophat ~= 0
    Xrec = MIRO_tophat(Xrec,smp,tophat);
end

end