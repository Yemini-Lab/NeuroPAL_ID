function [fpn,bias,scale] = MIRO_FPN_correction(im,Parameters)

offset = Parameters.Offset;
gain = Parameters.Gain;
var = Parameters.Var;
HS = Parameters.HS;
method = Parameters.max_est_method;

%%
fpn = (max(0,im-offset))./gain;

if HS > 0
    
    [fpn, scale,bias]= MIRO_Hotspot(fpn,HS,var,method);
    
else

    [~, scale, bias]= MIRO_Hotspot(fpn,HS,var,method);
    
end


end