function [Final_img_tmp, m_Weight_tmp,Count] = MIRO_patch_matching_and_processing(Final_img_0, m_Weight_0,ii,jj,blk_step,...
    block_Size, width, height, noisyImg,BasicImg, N, D, DD, D_3d, p, sigma_g, m_Kaiser, beta, lambda_W, adaptive_on)

m_blockPoint = Locate_blk(ii, jj, blk_step, block_Size, width, height);

[Similar_noisy, Similar_Basic, Positions, Count,sigma] = MIRO_Needle_match(noisyImg,...
    BasicImg, m_blockPoint, N, sigma_g, lambda_W, D, DD, p, adaptive_on);

[Similar_Wiener, Wiener_weights] = MIRO_patch_3DFiltering(Similar_Basic,...
    Similar_noisy, D_3d, sigma);

[Final_img_tmp, m_Weight_tmp] = MIRO_Aggregation(Similar_Wiener, Wiener_weights,...
    Positions, Final_img_0, m_Weight_0, Count, m_Kaiser, D, beta);

end