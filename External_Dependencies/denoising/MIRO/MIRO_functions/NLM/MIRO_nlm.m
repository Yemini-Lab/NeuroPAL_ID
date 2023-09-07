function J = MIRO_nlm(I,Options)
% This function NLMF performs Non-Local Means noise filtering of
% 2D grey/color or 3D image data. The function is partly c-coded for
% cpu efficient filtering.
%
% Function:
%
%   J = NLMF( I, Options);
%
% inputs,
%   I : 2D grey/color or 3D image data, of type Double
%           in range [0..1]
%   Options : Struct with options
%
% outputs,
%   J : The NL-means filtered image or image volume
%
% options,
%   Options.kernelratio : Radius of local Patch (default 3)
%   Options.windowratio : Radius of neighbourhood search window (default 3)
%   Options.filterstrength : Strength of the NLMF filtering (default 0.05)
%   Options.blocksize : The image is split in sub-blocks for efficienter
%                      memory usage,  (default 2D: 150, default 3D: 32);
%   Options.nThreads : Number of CPU Threads used default (2);
%   Options.verbose : When set to true display information (default false)
%
%
% Literature:
% - Non local filter proposed for A. Buades, B. Coll  and J.M. Morel
%   "A non-local algorithm for image denoising"
% - Dirk-Jan Kroon (2021). Fast Non-Local Means 1D, 2D Color and 3D, 
%   MATLAB Central File Exchange.
% - I. Frosio, J. Kautz, Statistical Nearest Neighbors for Image Denoising,
%   IEEE Trans. Image Processing, 2018.
%
%
% First Compile c-code!!!!, with :
%   mex -v -compatibleArrayDims vectors_nlmeans_double.c
%   mex -v -compatibleArrayDims image2vectors_double.c
%
%

if((min(I(:))<0)||(max(I(:))>1)), warning('NLMF:inputs','Preferable data range [0..1]'); end
if(~isa(I,'double')), error('NLMF:inputs','Input data must be double');end

is2D=size(I,3)<4;

% Process inputs
defaultoptions=struct('kernelratio',1,'windowratio',5,'filterstrength',0.05,'blocksize',150,'nThreads',2,'verbose',false);
if(is2D), defaultoptions.blocksize=150; else, defaultoptions.blocksize=32; end
if(~exist('Options','var')), Options=defaultoptions;
else
    tags = fieldnames(defaultoptions);
    for i=1:length(tags), if(~isfield(Options,tags{i})), Options.(tags{i})=defaultoptions.(tags{i}); end, end
    if(length(tags)~=length(fieldnames(Options))), warning('NLMF:unknownoption','unknown options found'); end
end

kernelratio=round(Options.kernelratio);
windowratio=round(Options.windowratio);
filterstrength=Options.filterstrength;
blocksize=round(Options.blocksize);
nThreads=round(Options.nThreads);
verbose=Options.verbose;

if(is2D)
    Ipad = padarray(I,[kernelratio+windowratio kernelratio+windowratio],'symmetric'); %,
else
    Ipad = padarray(I,[kernelratio+windowratio kernelratio+windowratio kernelratio+windowratio],'symmetric'); %,
end

% Separate the image into smaller blocks, for less memory usage
% and efficient cpu-cache usage.
block=makeBlocks(kernelratio,windowratio, blocksize, I, Ipad, is2D);

if(verbose), tic; end
erms='***';
J=zeros(size(I),class(Ipad));
for i=1:length(block)
    if(verbose)
        disp(['Processing Block ' num2str(i) ' of ' num2str(length(block)) ' estimated time remaining ' erms]);
    end
    if(is2D)
        Iblock=Ipad(block(i).x1:block(i).x2,block(i).y1:block(i).y2,:);
    else
        Iblock=Ipad(block(i).x1:block(i).x2,block(i).y1:block(i).y2,block(i).z1:block(i).z2);
    end


    % Get the local patches of every pixel-coordinate in the block
    V=MIRO_image2vectors_double(double(Iblock),double(kernelratio),double(nThreads));

    %     blockfilterstrength = filterstrength*floor(median(Iblock,'all'));
    % Do NL-means on the vectors in the block
    Iblock_filtered=MIRO_vectors_nlmeans_double(double(Iblock),double(V),double(kernelratio),double(windowratio),double(filterstrength),double(nThreads));

    if(is2D)
        J(block(i).x3:block(i).x4,block(i).y3:block(i).y4,:)=Iblock_filtered;
    else
        J(block(i).x3:block(i).x4,block(i).y3:block(i).y4,block(i).z3:block(i).z4)=Iblock_filtered;
    end

    if(verbose)
        t=toc; erm=(t/i)*(length(block)-i); erms=num2str(erm);
    end
end
% toc;


function block=makeBlocks(kernelratio,windowratio,blocksize, I,Ipad, is2D)
block=struct;
i=0;
blocksize_real=blocksize-(kernelratio+windowratio)*2;
if(is2D)
    for y1=1:blocksize_real:size(Ipad,2)
        for x1=1:blocksize_real:size(Ipad,1)
            x2=x1+blocksize-1; y2=y1+blocksize-1;
            x2=max(min(x2,size(Ipad,1)),1);
            y2=max(min(y2,size(Ipad,2)),1);
            x3=x1; y3=y1;
            x4=min(x1+blocksize_real-1,size(I,1));
            y4=min(y1+blocksize_real-1,size(I,2));
            if((x4>=x3)&&(y4>=y3))
                i=i+1;
                block(i).x1=x1; block(i).y1=y1; block(i).x2=x2; block(i).y2=y2;
                block(i).x3=x3; block(i).y3=y3; block(i).x4=x4; block(i).y4=y4;
            end
        end
    end
else
    for z1=1:blocksize_real:size(Ipad,3)
        for y1=1:blocksize_real:size(Ipad,2)
            for x1=1:blocksize_real:size(Ipad,1)
                x2=x1+blocksize-1; y2=y1+blocksize-1;  z2=z1+blocksize-1;
                x2=max(min(x2,size(Ipad,1)),1);
                y2=max(min(y2,size(Ipad,2)),1);
                z2=max(min(z2,size(Ipad,3)),1);
                x3=x1; y3=y1; z3=z1;
                x4=min(x1+blocksize_real-1,size(I,1));
                y4=min(y1+blocksize_real-1,size(I,2));
                z4=min(z1+blocksize_real-1,size(I,3));
                if((x4>=x3)&&(y4>=y3)&&(z4>=z3))
                    i=i+1;
                    block(i).x1=x1; block(i).y1=y1;  block(i).z1=z1;
                    block(i).x2=x2; block(i).y2=y2;  block(i).z2=z2;
                    block(i).x3=x3; block(i).y3=y3;  block(i).z3=z3;
                    block(i).x4=x4; block(i).y4=y4;  block(i).z4=z4;
                end
            end
        end
    end
end