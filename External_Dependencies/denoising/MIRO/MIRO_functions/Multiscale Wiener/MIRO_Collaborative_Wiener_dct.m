function [Final_img, Count] = MIRO_Collaborative_Wiener_dct(noisyImg,BasicImg,Transforms,sigma_g,parameters)%#codegen

%% initialization

width = size(noisyImg,2);
height = size(noisyImg,1);

block_Size = parameters(1);
blk_step = parameters(7);
beta = parameters(8);

lambda_W = parameters(9); % lambda Wiener
adaptive_on = parameters(10);

Width_num = round((width - block_Size)/blk_step);
Height_num = round((height - block_Size)/blk_step);
Count =zeros(Height_num + 2, Width_num + 2);

%% Tranform matrices

D = Transforms.D_2d;
DD = Transforms.DD_2d;
D_3d = Transforms.D_3d;

%% Create Gauss Pyramid

if min(size(noisyImg,1),size(noisyImg,2))>=48 % 64
    N = Pyramid(BasicImg,3);
elseif min(size(noisyImg,1),size(noisyImg,2))>32
    N = Pyramid(BasicImg,2);
    N{3} = N{2};
else
    N = Pyramid(BasicImg,1);
    N{3} = N{1};
    N{2} = N{1};
end

%% Filter

max_j = round(Height_num + 2);
max_i = round(Width_num + 2);
p = parameters(1:6);

[Final_img_0, m_Weight_0, m_Kaiser] = MIRO_Collaborative_Wiener_Initialization(noisyImg, block_Size,max_i);

parfor ii = 1:max_i
    for jj = 1:max_j
        
        [Final_img_tmp, m_Weight_tmp, Count(ii,jj)] = MIRO_patch_matching_and_processing(Final_img_0(:,:,ii), m_Weight_0(:,:,ii),ii,jj,blk_step,...
            block_Size, width, height, noisyImg,BasicImg, N, D, DD, D_3d, p, sigma_g, m_Kaiser, beta, lambda_W, adaptive_on);
        
        Final_img_0(:,:,ii) = Final_img_tmp;
        m_Weight_0(:,:,ii) = m_Weight_tmp;
        
    end
end

Final_img = sum(Final_img_0,3)./sum(m_Weight_0,3);


end