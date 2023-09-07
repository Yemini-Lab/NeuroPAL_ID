function [Final_img, m_Weight] = MIRO_Aggregation(similar_blocks, Wiener_weights, blk_positions, m_final_img, m_weight_img, Count, Kaiser, D, beta)%#codegen

shape = size(similar_blocks)-1;

Wiener_weights = (Wiener_weights).^(beta);
block_weight = Wiener_weights.*Kaiser;

pad = [8,8];
blocks = zeros(shape(2)+2*pad(1)+1,shape(3)+2*pad(2)+1,shape(1)+1);

for i = 1:Count
    %     tmp_blocks = idct2(squeeze(similar_blocks(i, :, :)));
    tmp_blocks = D'*(squeeze(similar_blocks(i, :, :)))*D;    
    blocks(:,:,i) = padarray(tmp_blocks,pad,'replicate','both');
    
end

st = pad(1) + 1;
en = st + shape(2);

for i = 1:Count

    point = blk_positions(i, :);
    tem_img = Wiener_weights .* blocks(st:en,st:en,i) .* Kaiser;
    
    m_final_img(point(1):point(1) + shape(2), point(2):point(2) + shape(3)) = ...
        m_final_img(point(1):point(1) + shape(2), point(2):point(2) + shape(3)) + tem_img;
    m_weight_img(point(1):point(1) + shape(2), point(2):point(2) + shape(3)) = ...
        m_weight_img(point(1):point(1) + shape(2), point(2):point(2) + shape(3)) + block_weight;
end

Final_img = m_final_img;
m_Weight = m_weight_img;

end