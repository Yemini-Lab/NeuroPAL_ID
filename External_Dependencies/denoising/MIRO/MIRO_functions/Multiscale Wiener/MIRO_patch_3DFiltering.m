function [similar_blocks, Wiener_weights] = MIRO_patch_3DFiltering(similar_blocks,similar_noisy_blocks,D_3d, sigma)

m_Shape = size(similar_blocks);
Wiener_weights = zeros(m_Shape(2),m_Shape(3));

for i = 1:m_Shape(2)
    for j = 1: m_Shape(3)
        
        Var = norm(mean(sigma(:,i,j))^2);
        
        tem_Vct_Trans = similar_blocks(:, i, j)'*D_3d;
        
        Norm_2 = norm(tem_Vct_Trans.^2,1);
        m_weight = Norm_2/(Norm_2 + Var);
        
        if m_weight ~= 0
            Wiener_weights(i,j) = 1./(m_weight^2 .* Var) ;
        end
        
        tem_Vct_Trans = m_weight .* (similar_noisy_blocks(:, i, j)'*D_3d);
        similar_blocks(:, i, j) = real(D_3d*(tem_Vct_Trans)')./m_Shape(1);
    end
end

end
