function SLsys = getSLsys(img, scale, imagepad)

if ~exist('imagepad','var')
    imagepad = 20;
end

SLsys = SLgetShearletSystem2D(0,size(img,1)+imagepad,size(img,2)+imagepad,scale);

end