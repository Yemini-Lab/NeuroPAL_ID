function [Final_img_0, m_Weight_0, m_Kaiser] = MIRO_Collaborative_Wiener_Initialization(img, blk_size, max_i)

m_shape = size(img);
% K = kaiser(blk_size, Beta_Kaiser);
K = parzenwin(blk_size);
m_Kaiser = (K * K');
Final_img_0 = zeros(m_shape(1),m_shape(2),max_i);
m_Weight_0 = Final_img_0;

end