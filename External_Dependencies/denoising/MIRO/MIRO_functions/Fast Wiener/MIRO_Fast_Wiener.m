function y_est = MIRO_Fast_Wiener(z, y_hat, sigma, smp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This algorithm is adapted from the article:
%
%  [1] K. Dabov, A. Foi, V. Katkovnik, and K. Egiazarian, "Image Denoising 
%  by Sparse 3D Transform-Domain Collaborative Filtering," 
%  IEEE Transactions on Image Processing, vol. 16, no. 8, August, 2007.
%
% Copyright (c) 2006-2011 Tampere University of Technology.
% All rights reserved.
% This work should only be used for nonprofit purposes.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('y','var')
    y        = []; %% default 
end

%%  Specify the std. dev. of the corrupting noise

if (exist('sigma','var') ~= 1)
    sigma               = 25; 
else
    sigma               = sigma*255;
end

%% Select transforms ('dct', 'dst', 'hadamard', or anything that is listed by 'help wfilters'):
transform_2D_Wiener_name = 'dct';     %% transform used for the Wiener filt. of size N1_wiener x N1_wiener
transform_3rd_dim_name   = 'haar';    %% transform used in the 3-rd dim, the same for HT and Wiener filt.


N1                  = 8;   %% N1 x N1 is the block size used for the hard-thresholding (HT) filtering
beta                = 2.0; %% parameter of the 2D Kaiser window used in the reconstruction

%% Wiener filtering parameters:
N1_wiener           = smp;
Nstep_wiener        = 3;
N2_wiener           = 32;
Ns_wiener           = 39;
tau_match_wiener    = 400;
beta_wiener         = 2.0;

%% Block-matching parameters:

stepFSW             = 1;
smallLNW            = 'not used in np';

%% Create transform matrices, etc.

[TforW, TinvW] = getTransfMatrix(N1_wiener, transform_2D_Wiener_name, 0); %% get (normalized) forward and inverse transform matrices

if (strcmp(transform_3rd_dim_name, 'haar') == 1) || (strcmp(transform_3rd_dim_name(end-2:end), '1.1') == 1)
    %%% If Haar is used in the 3-rd dimension, then a fast internal transform is used, thus no need to generate transform
    %%% matrices.
    hadper_trans_single_den         = {};
    inverse_hadper_trans_single_den = {};
else
    %%% Create transform matrices. The transforms are later applied by
    %%% matrix-vector multiplication for the 1D case.
    for hpow = 0:ceil(log2(max(N2,N2_wiener)))
        h = 2^hpow;
        [Tfor3rd, Tinv3rd]   = getTransfMatrix(h, transform_3rd_dim_name, 0);
        hadper_trans_single_den{h}         = single(Tfor3rd); %#ok<AGROW>
        inverse_hadper_trans_single_den{h} = single(Tinv3rd'); %#ok<AGROW>
    end
end

%% 2D Kaiser windows used in the aggregation of block-wise estimates

if beta_wiener==2 && beta==2 && N1_wiener==8 && N1==8 % hardcode the window function so that the signal processing toolbox is not needed by default
    Wwin2D = [ 0.1924    0.2989    0.3846    0.4325    0.4325    0.3846    0.2989    0.1924;
        0.2989    0.4642    0.5974    0.6717    0.6717    0.5974    0.4642    0.2989;
        0.3846    0.5974    0.7688    0.8644    0.8644    0.7688    0.5974    0.3846;
        0.4325    0.6717    0.8644    0.9718    0.9718    0.8644    0.6717    0.4325;
        0.4325    0.6717    0.8644    0.9718    0.9718    0.8644    0.6717    0.4325;
        0.3846    0.5974    0.7688    0.8644    0.8644    0.7688    0.5974    0.3846;
        0.2989    0.4642    0.5974    0.6717    0.6717    0.5974    0.4642    0.2989;
        0.1924    0.2989    0.3846    0.4325    0.4325    0.3846    0.2989    0.1924];
    Wwin2D_wiener = Wwin2D;
else
    Wwin2D_wiener    = kaiser(N1_wiener, beta_wiener) * kaiser(N1_wiener, beta_wiener)'; % Kaiser window used in the aggregation of the Wiener filt. part
end

% convert z to double precision if needed
z = double(z);

% convert y to double precision if needed
y = double(y);

% if z's range is [0, 255], then convert to [0, 1]
if (max(z(:)) > 10) 
    z = z / 255;
end

% if y's range is [0, 255], then convert to [0, 1]
if (max(y(:)) > 10) 
    y = y / 255;
end

if (size(z,3) ~= 1) || (size(y,3) ~= 1)
    error('Only grayscale 2D images.');
end

%%
y_est = fast_wiener(single(z), single(y_hat), hadper_trans_single_den, Nstep_wiener, N1_wiener, N2_wiener, ...
    'unused arg', tau_match_wiener*N1_wiener*N1_wiener/(255*255), (Ns_wiener-1)/2, (sigma/255), 'unused arg', single(TforW), single(TinvW)', inverse_hadper_trans_single_den, Wwin2D_wiener, smallLNW, stepFSW, single(ones(N1_wiener)) );

%% Calculate the final estimate's PSNR, print it, and show the denoised image next to the noisy one
y_est = double(y_est);

return;

%% Auxiliary functions 

function [Tforward, Tinverse] = getTransfMatrix (N, transform_type, dec_levels)
%
% Create forward and inverse transform matrices, which allow for perfect
% reconstruction. The forward transform matrix is normalized so that the 
% l2-norm of each basis element is 1.
%
% [Tforward, Tinverse] = getTransfMatrix (N, transform_type, dec_levels)
%
%  INPUTS:
%
%   N               --> Size of the transform (for wavelets, must be 2^K)
%
%   transform_type  --> 'dct', 'dst', 'hadamard', or anything that is 
%                       listed by 'help wfilters' (bi-orthogonal wavelets)
%                       'DCrand' -- an orthonormal transform with a DC and all
%                       the other basis elements of random nature
%
%   dec_levels      --> If a wavelet transform is generated, this is the
%                       desired decomposition level. Must be in the
%                       range [0, log2(N)-1], where "0" implies
%                       full decomposition.
%
%  OUTPUTS:
%
%   Tforward        --> (N x N) Forward transform matrix
%
%   Tinverse        --> (N x N) Inverse transform matrix
%

if exist('dec_levels') ~= 1 
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
elseif strcmp(transform_type, 'dct') == 1, Tforward    = dct(eye(N)); elseif strcmp(transform_type, 'dst') == 1, Tforward    = dst(eye(N)); 
elseif strcmp(transform_type, 'DCrand') == 1, x = randn(N); x(1:end,1) = 1; [Q,~] = qr(x); 
    if (Q(1) < 0), Q = -Q; end; Tforward = Q';
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

