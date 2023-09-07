function [y_hat_wi] = MIRO_Fast_Wiener_Video(z, y_hat, sigma,sampling)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This algorithm is adapted from the article:
%
%  [1] K. Dabov, A. Foi, and K. Egiazarian, "Video denoising by sparse 3D
%  transform-domain collaborative filtering," European Signal Processing
%  Conference (EUSIPCO-2007), September 2007.
%
% Copyright © 2007 Tampere University of Technology. All rights reserved.
% This work should only be used for nonprofit purposes.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NumberOfFrames = size(z,3);

%% Select transforms ('dct', 'dst', 'hadamard', or anything that is listed by 'help wfilters'):
transform_2D_Wiener_name = 'dct';     %% transform used for the Wiener filt. of size N1_wiener x N1_wiener
transform_3rd_dim_name   = 'haar'; %% tranform used in the 3-rd dim, the same for HT and Wiener filt.


%% Wiener filtering parameters:
denoiseFramesW      = min(9, NumberOfFrames);
N1_wiener           = sampling;
Nstep_wiener        = N1_wiener-1;
N2_wiener           = 8;
Ns_wiener           = 7;
Npr_wiener          = 5;
tau_match_wiener    = 1500;
beta_wiener         = 2.0;
dsub_wiener         = 3;
Nb_wiener           = 2;

%% Block-matching parameters:
stepFSW             = 1;

%%
if sigma > 30
    N1_wiener = 8;
    tau_match_wiener    = 3000;
end

%%
z = single(z);

%% Create transform matrices, etc.

decLevel3          = 0;    %% dec. level for the wavelet transform in the 3rd dimension

[TforW, TinvW]     = getTransfMatrix(N1_wiener, transform_2D_Wiener_name); %% get (normalized) forward and inverse transform matrices

if (strcmp(transform_3rd_dim_name, 'haar') == 1 || strcmp(transform_3rd_dim_name(end-2:end), '1.1') == 1)
    %%% Fast internal transform is used, no need to generate transform
    %%% matrices.
    hadper_trans_single_den         = {};
    inverse_hadper_trans_single_den = {};
else
    %%% Create transform matrices. The transforms are later computed by
    %%% matrix multiplication with them
    for hh = [1 2 4 8 16 32]
        [Tfor3rd, Tinv3rd]   = getTransfMatrix(hh, transform_3rd_dim_name, decLevel3);
        hadper_trans_single_den{hh}         = single(Tfor3rd); %#ok<AGROW> 
        inverse_hadper_trans_single_den{hh} = single(Tinv3rd'); %#ok<AGROW> 
    end
end

%% 2D Kaiser windows that scale the reconstructed blocks

Wwin2D_wiener    = kaiser(N1_wiener, beta_wiener) * kaiser(N1_wiener, beta_wiener)'; % Kaiser window used in the aggregation of the Wiener filt. part
l2normLumChrom = ones(NumberOfFrames,1); %%% NumberOfFrames == nSl !

%%
y_hat_wi = fast_wiener_video(z, single(y_hat), hadper_trans_single_den, Nstep_wiener, N1_wiener, N2_wiener, ...
    'unused_arg', tau_match_wiener*N1_wiener*N1_wiener/(255*255), (Ns_wiener-1)/2, sigma, 'unused arg', single(TforW), single(TinvW)', inverse_hadper_trans_single_den, 'unused arg', dsub_wiener*dsub_wiener/255, l2normLumChrom, Wwin2D_wiener, (Npr_wiener-1)/2, stepFSW, denoiseFramesW, Nb_wiener );

y_hat_wi = double(y_hat_wi);

return;


%% auxiliary functions 

function [Tforward, Tinverse] = getTransfMatrix (N, transform_type, dec_levels)

if exist('dec_levels', 'var') ~= 1
    dec_levels = 0;
end

if N == 1
    Tforward = 1;
elseif strcmp(transform_type, 'hadamard') == 1
    Tforward    = hadamard(N);
elseif (N == 8) && strcmp(transform_type, 'bior1.5')==1 % hardcoded transform so that the wavelet toolbox is not needed to generate it
    Tforward =  [ 0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274;
       0.219417649252501   0.449283757993216   0.449283757993216   0.219417649252501  -0.219417649252501  -0.449283757993216  -0.449283757993216  -0.219417649252501;
       0.569359398342846   0.402347308162278  -0.402347308162278  -0.569359398342846  -0.083506045090284   0.083506045090284  -0.083506045090284   0.083506045090284;
      -0.083506045090284   0.083506045090284  -0.083506045090284   0.083506045090284   0.569359398342846   0.402347308162278  -0.402347308162278  -0.569359398342846;
       0.707106781186547  -0.707106781186547                   0                   0                   0                   0                   0                   0;
                       0                   0   0.707106781186547  -0.707106781186547                   0                   0                   0                   0;
                       0                   0                   0                   0   0.707106781186547  -0.707106781186547                   0                   0;
                       0                   0                   0                   0                   0                   0   0.707106781186547  -0.707106781186547];   
elseif (N == 8) && strcmp(transform_type, 'dct')==1 % hardcoded transform so that the signal processing toolbox is not needed to generate it
    Tforward = [ 0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274   0.353553390593274;
       0.490392640201615   0.415734806151273   0.277785116509801   0.097545161008064  -0.097545161008064  -0.277785116509801  -0.415734806151273  -0.490392640201615;
       0.461939766255643   0.191341716182545  -0.191341716182545  -0.461939766255643  -0.461939766255643  -0.191341716182545   0.191341716182545   0.461939766255643;
       0.415734806151273  -0.097545161008064  -0.490392640201615  -0.277785116509801   0.277785116509801   0.490392640201615   0.097545161008064  -0.415734806151273;
       0.353553390593274  -0.353553390593274  -0.353553390593274   0.353553390593274   0.353553390593274  -0.353553390593274  -0.353553390593274   0.353553390593274;
       0.277785116509801  -0.490392640201615   0.097545161008064   0.415734806151273  -0.415734806151273  -0.097545161008064   0.490392640201615  -0.277785116509801;
       0.191341716182545  -0.461939766255643   0.461939766255643  -0.191341716182545  -0.191341716182545   0.461939766255643  -0.461939766255643   0.191341716182545;
       0.097545161008064  -0.277785116509801   0.415734806151273  -0.490392640201615   0.490392640201615  -0.415734806151273   0.277785116509801  -0.097545161008064];
elseif (N == 8) && strcmp(transform_type, 'dst')==1 % hardcoded transform so that the PDE toolbox is not needed to generate it
    Tforward = [ 0.161229841765317   0.303012985114696   0.408248290463863   0.464242826880013   0.464242826880013   0.408248290463863   0.303012985114696   0.161229841765317;
       0.303012985114696   0.464242826880013   0.408248290463863   0.161229841765317  -0.161229841765317  -0.408248290463863  -0.464242826880013  -0.303012985114696;
       0.408248290463863   0.408248290463863                   0  -0.408248290463863  -0.408248290463863                   0   0.408248290463863   0.408248290463863;
       0.464242826880013   0.161229841765317  -0.408248290463863  -0.303012985114696   0.303012985114696   0.408248290463863  -0.161229841765317  -0.464242826880013;
       0.464242826880013  -0.161229841765317  -0.408248290463863   0.303012985114696   0.303012985114696  -0.408248290463863  -0.161229841765317   0.464242826880013;
       0.408248290463863  -0.408248290463863                   0   0.408248290463863  -0.408248290463863                   0   0.408248290463863  -0.408248290463863;
       0.303012985114696  -0.464242826880013   0.408248290463863  -0.161229841765317  -0.161229841765317   0.408248290463863  -0.464242826880013   0.303012985114696;
       0.161229841765317  -0.303012985114696   0.408248290463863  -0.464242826880013   0.464242826880013  -0.408248290463863   0.303012985114696  -0.161229841765317];
elseif (N == 7) && strcmp(transform_type, 'dct')==1 % hardcoded transform so that the signal processing toolbox is not needed to generate it
    Tforward =[ 0.377964473009227   0.377964473009227   0.377964473009227   0.377964473009227   0.377964473009227   0.377964473009227   0.377964473009227;
       0.521120889169602   0.417906505941275   0.231920613924330                   0  -0.231920613924330  -0.417906505941275  -0.521120889169602;
       0.481588117120063   0.118942442321354  -0.333269317528993  -0.534522483824849  -0.333269317528993   0.118942442321354   0.481588117120063;
       0.417906505941275  -0.231920613924330  -0.521120889169602                   0   0.521120889169602   0.231920613924330  -0.417906505941275;
       0.333269317528993  -0.481588117120063  -0.118942442321354   0.534522483824849  -0.118942442321354  -0.481588117120063   0.333269317528993;
       0.231920613924330  -0.521120889169602   0.417906505941275                   0  -0.417906505941275   0.521120889169602  -0.231920613924330;
       0.118942442321354  -0.333269317528993   0.481588117120063  -0.534522483824849   0.481588117120063  -0.333269317528993   0.118942442321354];   
elseif strcmp(transform_type, 'dct') == 1
    Tforward    = dct(eye(N));
elseif strcmp(transform_type, 'dst') == 1
    Tforward    = dst(eye(N));
elseif strcmp(transform_type, 'DCrand') == 1
    x = randn(N); x(1:end,1) = 1; [Q,~] = qr(x); 
    if (Q(1) < 0)
        Q = -Q; 
    end
    Tforward = Q';
else %% a wavelet decomposition supported by 'wavedec'
    %%% Set periodic boundary conditions, to preserve bi-orthogonality
    dwtmode('per','nodisp');  
    
    Tforward = zeros(N,N);
    for i = 1:N
        Tforward(:,i)=wavedec(circshift([1 zeros(1,N-1)],[dec_levels i-1]), log2(N), transform_type);  %% construct transform matrix
    end
end

%%% Normalize the basis elements
Tforward = (Tforward' * diag(sqrt(1./sum(Tforward.^2,2))))'; 

%%% Compute the inverse transform matrix
Tinverse = inv(Tforward);

return;