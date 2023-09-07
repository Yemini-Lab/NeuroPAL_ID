%% Compile functions for Unbiased NLM
%
% Use this function if the precompiled MEX files do not work on your
% machine. Beware, you will need a supported compiler.
% Please, For more information, visit https://www.mathworks.com/support/compilers.

mex -v -compatibleArrayDims MIRO_image2vectors_double.c
mex -v -compatibleArrayDims MIRO_vectors_nlmeans_double.c

pause(1)
clc
