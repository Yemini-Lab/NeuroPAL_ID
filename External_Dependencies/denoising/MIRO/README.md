MIRO
=====

MIRO (Multiscale Image Restoration through Optimally-sparse representation) is a software for microlocal noise correction designed for fluorescence microscopy. Thanks to the optimal sparsity of the shearlet domain and a physics-based noise estimation, MIRO improves the quality of microscopy images acquired using any of the most common camera sensors. This yields a stable and effective noise correction improving the reliability of image analysis and reconstruction.

## Citation ##

## Examples ##

![](Figures/Image_TIRF.png)
*Noise correction of three-color TIRFM images at different SNRs*. Raw images of a fixed BPAE cell were obtained at camera exposure times of 10 ms (A), 20 ms (B), 50 ms (C), and 100 ms (D). (E-H) The relative images after MIRO processing. Zoomed-in images corresponding to the dashed area for each SNR level before (I,K,M,O) and after processing (J,L,N,P). Scale bars: 5 &mu;m (A), 2 &mu;m (I).


![](Figures/Image_Confocal.png)
*Sub-diffraction-limited confocal microscopy at low illumination power using a GaAsP PMT.* 
Images of fluorescently-labeled microtubules obtained using a LSCM equipped with a GaAsP PMT detector (A, B), where the pinhole size was set to 1 and 0.2 Airy units (AU), respectively. 
The laser power between images remained unchanged. In image (B), it is clear that the detrimental effect of low SNR cancels the resolution improvement given by the the closed pinhole. 
After MIRO processing, the image quality is recovered to restore the expected sub-diffraction-limited resolution (C). 
(D-I) Zoomed-in images relative to the dashed (D, F, H) and solid (E, G, I) boxed areas of (A-C) as marked in (A). Scale bars: 10 &mu;m (A), 1 &mu;m (D,E).


![](Figures/Image_SIM1.png)
*Noise-controlled SIM reconstructions*. Cross-sections of 3D-reconstructions (*xy* and *yz*) of fluorescently-labeled tubulin filaments: widefield (WF; A,B), SIM reconstruction with regularization parameter fixed to $w=5\times{}10^{-4}$ (Wiener; C,D), noise-controlled true-Wiener (TW; E,F), flat-noise (FN; G,H), and notch-filtered flat-noise SIM reconstruction (NF; I,J), and MIRO-processed Wiener reconstruction (MIRO; K,L).
All data are reproduced from the datasets in [Smith et al. 2021].
Scale bars: 4 &mu;m (A), 0.8 &mu;m (A, inset).


![](Figures/Image_SIM2.png)
*Correction of reconstruction artifacts in simulated SIM images*. (A) SIM reconstruction from a representative frame of a simulated SIM dataset from [Huang et al. 2018]. (B) A frame from the same dataset as (A) reconstructed using running average (i.e. rolling reconstruction). (C,D) The SIM reconstruction in (A,B) after Hessian artifact minimization. This method is based on the computation of Hessian penalty across sequential frames assuming a structural continuity along the *x*, *y*, and *t* axes as a-priori knowledge. Here, rolling reconstruction is usually applied in pre-processing to further mitigate temporal noise fluctuations (D). (E,F) The images in (A,B) after MIRO processing. 
In this case, each frame is first processed individually (microlocal noise correction). 
Then, non-local similarities across the sample are evaluated in both space and time in order to apply a Wiener filter to groups of similar patches. 
The goal of this grouping is to allow the use of a higher-dimensionality transform to maximize the input sparsity during the Wiener filtering. Importantly, patches are grouped only if they have a minimum similarity score and no assumption about temporal continuity or sample dynamics is necessary. (G-L) Zoomed-in images of (A-F) corresponding to the area marked by the dashed box in (A). Scale bars: 4 &mu;m (A), 1 &mu;m (G).


## System Requirements ##

### Hardware Requirements ###
A standard computer with enough RAM to support MATLAB 2021b. For minimum performance, this will be a computer with about 4 GB of RAM. For optimal performance, we recomend the following specs:

RAM: 16+ GB; 
CPU: 6+ cores, 3.2+ GHz/core.

### Software Requirements ###
MATLAB 2021b+ 
MATLAB "Image Processing" Toolbox
Windows OS 64 bit, Linux 64 bit or Mac OS X 64 bit

## Installation ##

### Graphic Interface ###
To run MIRO graphic interface\*:

 - Double-click the MIRO_app.mlappinstall file in the App folder.
 - In MATLAB, go to App>My App and double-click on MIRO_app.
 - To test the program you can use the images provided in the folder MIRO/App/Test_Images.

\* currently the NLM optional filter is supported for Windows OS only.
 
### MATLAB Command Line ###

 - Extract the MIRO folder in your preferred location.
 - Run the MIRO_install.m script
 - Run the MIRO_Demo script inthe MIRO/Demo folder to see the code usage or in the command line type help MIRO.

### Notes ###

The provided MEX file for the NLM optional filter supports Windows OS only. However, the source code is provided in the MIRO/MIRO_functions/NLM folder.
To compile your own MEX file check the compile_MIRO_nlm script. 

## Creators ##

Biagio Mandracchia

## Acknowledgments ##

*Digital Shearlet Transform*: [ShearLab](https://shearlab.math.lmu.de).

*Resolution Estimation*: [Parameter-free image resolution estimation](https://www.nature.com/articles/s41592-019-0515-7).

*Optional filters*: the Unbiased Non-local Means filter has been adapted from the work of [I. Frosio and J. Kautz](https://ieeexplore.ieee.org/document/8463600) and [D. Kroon](https://mathworks.com/matlabcentral/fileexchange/27395-fast-non-local-means-1d-2d-color-and-3d?s_tid=prof_contriblnk).
The Fast Wiener filter makes use of some compiled functions from
[the unit of computing sciences of Tampere University](https://webpages.tuni.fi/foi/GCF-BM3D/)

