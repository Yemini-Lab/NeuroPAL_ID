% This function compares patches' similarity and groups them accordingly

function [Final_noisy_blocks, Final_similar_blocks, blk_positions, Count, sigma] = MIRO_Needle_match(NoisyImg, BasicImg, BlockPoint, N, sigma_g, lambda_W, D, DD, parameters, adaptive_on)%#codegen

%% Load parameters

Blk_Size = parameters(1);          % Step #1 block size
Search_Step = parameters(2);       % Step #1 search step
Threshold = parameters(3);         % Step #1 match threshold
max_matched = parameters(4);       % Step #1 max patches per group
Window_size = parameters(5);       % Step #1 search window
Blk_Size_needle = parameters(6);   % Step #1 block size for the needle patches

present_x = BlockPoint(1);
present_y = BlockPoint(2);

n_needle = length(N);
m_Distance = zeros(n_needle+1,1);

%% Reference patch

% inizialization
blk_positions = repmat([BlockPoint(2), BlockPoint(1)],max_matched,1);

% dct transform of the reference patch
img = BasicImg(present_y: present_y+Blk_Size-1, present_x: present_x+Blk_Size-1);
dct_img = D*img*D';
Final_similar_blocks = shiftdim(repmat(dct_img,1,1,max_matched),2);

% reference noisy patch
noisy_img = NoisyImg(present_y: present_y+Blk_Size-1, present_x: present_x+Blk_Size-1);
dct_noisy_img = D*(noisy_img)*D';
Final_noisy_blocks = shiftdim(repmat(dct_noisy_img,1,1,max_matched),2);

% dct transform of the reference "needle". This is evaluated only for the
% basic image, which is the only one used for the similarity estimation
dct_N = cell(n_needle);
for  k = 1:n_needle % % parfor  k = 1:n_needle
    % scale coordinates
    present_x_needle = round(present_x*.5^k);
    present_y_needle = round(present_y*.5^k);
    % check scaled coordinates
    if present_x_needle == 0
        present_x_needle = 1;
    elseif present_x_needle > size(N{k},2)-Blk_Size_needle+1
        present_x_needle = size(N{k},2)-Blk_Size_needle+1;
    end
    if present_y_needle == 0
        present_y_needle = 1;
    elseif present_y_needle > size(N{k},1)-Blk_Size_needle+1
        present_y_needle = size(N{k},1)-Blk_Size_needle+1;
    end
    
    temp_N = N{k}(present_y_needle: present_y_needle+Blk_Size_needle-1, present_x_needle: present_x_needle+Blk_Size_needle-1);
    dct_N{k} = DD*(temp_N)*DD';
    
end

Window_location = Define_SearchWindow(BasicImg, BlockPoint, Window_size, Blk_Size);
blk_num = (Window_size - Blk_Size)/Search_Step;
blk_num = round(blk_num);
present_x = Window_location(1);
present_y = Window_location(2);

m_Blkpositions = zeros(blk_num.^2, 2);
Distances = zeros(blk_num.^2,1);

%% Comparison
matched_cnt = 1;
for i = 1:blk_num
    for j = 1:blk_num
        
        for k = 1:n_needle
            % scale coordinates
            present_x_needle = round(present_x*.5^k);
            present_y_needle = round(present_y*.5^k);
            % check scaled coordinates
            if present_x_needle == 0
                present_x_needle = 1;
            end
            if present_x_needle > size(N{k},2)-Blk_Size_needle+1
                present_x_needle = size(N{k},2)-Blk_Size_needle+1;
            end
            if present_y_needle == 0
                present_y_needle = 1;
            end
            if present_y_needle > size(N{k},1)-Blk_Size_needle+1
                present_y_needle = size(N{k},1)-Blk_Size_needle+1;
            end
            
            % measure distances for the k-th element of the needle
            tem_N = N{k}(present_y_needle:present_y_needle+Blk_Size_needle-1, present_x_needle:present_x_needle+Blk_Size_needle-1);
            dct_Tem_N = DD*(tem_N)*DD';
            
            m_Distance(k) = Block_distance(dct_N{k},dct_Tem_N);
            
        end
        
        
        mean_Distance = mean(nonzeros(m_Distance)); 
        % "pessimistic estimation" that does not count the zero distances
        
        if mean_Distance < Threshold && mean_Distance > 0
            
            m_Blkpositions(matched_cnt, :) = [present_y, present_x];
            Distances(matched_cnt) = mean_Distance;
            matched_cnt = matched_cnt + 1;
        end
        
        present_y = present_y + Search_Step;
    end
    present_x = present_x + Search_Step;
    present_y = Window_location(2);
    
end

Distances = Distances(1:matched_cnt-1); 
[~, sort_idx] = sort(Distances);

%% Grouping

Count = min(matched_cnt,max_matched);
Count = max(Count - mod(Count,2),1);

for i = 1:Count-1
    
    blk_positions(i+1, :) = m_Blkpositions(sort_idx(i), :);
    tem_img = BasicImg(blk_positions(i+1,1):blk_positions(i+1,1)+Blk_Size-1,...
        blk_positions(i+1,2):blk_positions(i+1,2)+Blk_Size-1);
    Final_similar_blocks(i+1, :, :) = D*(tem_img)*D';
    
    present_x = m_Blkpositions(sort_idx(i), 2);
    present_y = m_Blkpositions(sort_idx(i), 1);
    noisy_img = NoisyImg(present_y: present_y+Blk_Size-1,present_x: present_x+Blk_Size-1);
    Final_noisy_blocks(i+1, :, :) = D*(noisy_img)*D';

end

%% Sigma estimation

sigma_p = Sigma_estimation(Final_similar_blocks);
sigma = zeros(size(sigma_p));

if adaptive_on
    for i = 1:Count
        sigma_g_patch = sigma_g(blk_positions(i,1):blk_positions(i,1)+Blk_Size-1,...
            blk_positions(i,2):blk_positions(i,2)+Blk_Size-1);
        T = max(1,min(1e5,10.*mean2(sigma_g_patch)./mean2(squeeze(sigma_p(i,:,:))))).^2;

        sigma(i,:,:) = sqrt(lambda_W.*T.*squeeze(sigma_p(i,:,:)).^2 + sigma_g_patch.^2);
        
    end
else
    for i = 1:Count
        sigma_g_patch = sigma_g(blk_positions(i,1):blk_positions(i,1)+Blk_Size-1,...
            blk_positions(i,2):blk_positions(i,2)+Blk_Size-1);
        sigma(i,:,:) = sqrt(lambda_W.*squeeze(sigma_p(i,:,:)).^2 + sigma_g_patch.^2);
        
    end
end

end