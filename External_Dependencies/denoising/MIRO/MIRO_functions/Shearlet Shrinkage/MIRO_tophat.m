function f = MIRO_tophat(f,smp,alpha)

sz = round(alpha*8*smp);
se = strel('disk',sz);
f = imtophat(f,se);

end