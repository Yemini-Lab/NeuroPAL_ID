# ZephOD
Object/feature detection model selector algorithm. Current user version: `v0.2.0`.

## Getting Started

1. Clone git repository: 
  ```bash
  git clone https://github.com/venkatachalamlab/zephod.git
  ```  

2. Checkout the current version:
```bash
git checkout v0.2.0
```
Use the following command to see what's new in the most recent tagged version:
```bash
git show v0.2.0
```

3. Make sure that following Python libraries are installed (prefer conda over pip):
    - docopt
    - h5py
    - matplotlib
    - numpy
    - opencv
    - pandas
    - pathlib
    - pytorch
    - scipy
    - scikit-image
    - tqdm

4. Install (development mode):
  ```bash
  (base) zephod> python setup.py develop
  ```
5. Train:
  ```bash
  train_zephod --dataset=. --model=<yourmodelname> [options]
  ```
6. Run:
  ```bash
  zephod --dataset=. --model=<yourmodelname> [options]
  ```

## Current default channels
- `Richardson-Lucy Deconvolution`
- `0-255 Look-up Table`
- `Thresholding` (low=50, high=200)
- `Sharpening` ([-3, 16, -3] kernel)

## Currently available pretrained models
- `celegans`: pan-neuronal fluorescence image of freely-moving *C. elegans* worms
