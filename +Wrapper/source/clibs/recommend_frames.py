"""
recommend_frames.py: search and determine optimal reference frames to annotate for ZephIR.

Determine median frames to recommend as reference frames via k-medoids clustering
based on thumbnail distances (see build_pdists). Clustering is done iteratively,
such that one cluster is determined at a time. n_iter > 0 will re-iterate over
the existing list of median frames to fine-tune recommendations.

Usage:
    recommend_frames.py -h | --help
    recommend_frames.py -v | --version
    recommend_frames.py --dataset=<dataset> [options]

Options:
    -h --help                           	show this message and exit.
    -v --version                        	show version information and exit.
    --dataset=<dataset>  					path to data directory to analyze.
    --n_frames=<n_frames>  					number of reference frames to search for. [default: 5]
    --n_iter=<n_iter>  						number of iterations for optimizing results; -1 to uncap. [default: 0]
    --t_list=<t_list>  						frames to analyze.
    --channel=<channel>  					data channel to use for calculating correlation coefficients.
    --nx=<nx>  	                            size of x-axis.
    --ny=<ny>  	                            size of y-axis.
    --nz=<nz>  	                            number of slices.
    --nc=<nc>  	                            number of channels.
    --nt=<nt>  	                            number of frames.
    --save_to_metadata=<save_to_metadata>  	save t_ref to metadata.json. [default: True]
    --verbose=<verbose>  					return score plots during search. [default: False]
"""

import h5py.defs
import h5py.utils
import h5py.h5ac
import h5py._proxy

from collections import OrderedDict
from docopt import docopt

from zephir.__version__ import __version__
#from zephir.methods.build_pdists import get_all_pdists
from skimage.transform import resize
from zephir.utils.utils import *
from zephir.utils.io import *
from getters import *
import numpy as np
import sys


def dist_corrcoef(image_1, image_2):
    """Return a distance between two images corresponding to 1 minus the
    correlation coefficient between them. This can go from 0 to 2."""

    dist = 0
    for x1, x2 in zip(image_1, image_2):
        dist += (1 - np.corrcoef(x1.ravel(), x2.ravel())[0, 1])/len(image_1)
    return dist


def get_thumbnail(dataset, filename, channel, t, scale):
    """Return low-resolution thumbnail of data volume."""

    v = get_slice(dataset, t, filename)
    if channel is not None:
        v = v[channel]
    elif len(v.shape) == 4:
        v = np.max(v, axis=0)
    tmg = []
    new_shape = np.array([max(1, l//s) for l, s in zip(v.shape, scale)])
    for d in range(len(v.shape)):
        mip = np.max(v, axis=d)
        tmg.append(resize(mip, np.delete(new_shape, d)))
    return tmg


def get_all_pdists(dataset, filename, shape_t, channel,
                   dist_fn=dist_corrcoef,
                   load=True, save=True,
                   scale=(4, 16, 16),
                   pbar=False
                   ) -> np.ndarray:
    """Return all pairwise distances between the first shape_t frames in a dataset."""

    f = dataset / 'null.npy'
    if load or save:
        if channel is not None:
            f = dataset / f'pdcc_c{channel}.npy'
        else:
            f = dataset / f'pdcc.npy'
    if f.is_file() and load:
        pdcc = np.load(str(f), allow_pickle=True)
        if pdcc.shape == (shape_t, shape_t):
            return pdcc

    thumbnails = []
    for t in tqdm(range(shape_t), desc='Compiling thumbnails from rf...', unit='frames', file=sys.stdout):
        thumbnails += [get_thumbnail(dataset, filename, channel, t, scale)]

    d = np.zeros((shape_t, shape_t))
    for i in (tqdm(range(shape_t), desc='Calculating distances', unit='frames', file=sys.stdout) if pbar else range(shape_t)):
        for j in range(i+1, shape_t):
            dist = dist_fn(thumbnails[i], thumbnails[j])
            if np.isnan(dist):
                d[i, j] = 2.0
            else:
                d[i, j] = dist

    d_full = d + np.transpose(d)
    if save:
        np.save(str(f), d_full, allow_pickle=True)

    return d_full


def get_partial_pdists(dataset, shape_t, p_list, channel,
                       dist_fn=dist_corrcoef,
                       load=True,
                       scale=(4, 16, 16),
                       pbar=False
                       ) -> np.ndarray:
    """Return pairwise distances between shape_t frames and their parents in a dataset."""

    f = dataset / 'null.npy'
    if load:
        if channel is not None:
            f = dataset / f'pdcc_c{channel}.npy'
        else:
            f = dataset / f'pdcc.npy'
    d_full = None
    if f.is_file() and load:
        d_full = np.load(str(f), allow_pickle=True)

    print('Compiling thumbnails...')
    thumbnails = [get_thumbnail(dataset, channel, t, scale) for t in range(shape_t)]

    d_partial = np.zeros(shape_t)
    for i in (tqdm(range(shape_t), desc='Calculating distances', unit='frames', file=sys.stdout) if pbar else range(shape_t)):

        if p_list[i] < 0:
            continue

        if d_full is not None and d_full.shape[1] > int(p_list[i]):
            d_partial[i] = d_full[i, int(p_list[i])]
        else:
            dist = dist_fn(thumbnails[i], thumbnails[int(p_list[i])])
            if np.isnan(dist):
                d_partial[i] = 2.0
            else:
                d_partial[i] = dist

    return d_partial
