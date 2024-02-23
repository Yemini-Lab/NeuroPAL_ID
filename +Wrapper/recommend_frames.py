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
    --save_to_metadata=<save_to_metadata>  	save t_ref to metadata.json. [default: True]
    --verbose=<verbose>  					return score plots during search. [default: False]
"""

from collections import OrderedDict
from docopt import docopt

from zephir.__version__ import __version__
#from zephir.methods.build_pdists import get_all_pdists
from skimage.transform import resize
from zephir.utils.utils import *
from zephir.utils.io import *
import numpy as np
import sys


def dist_corrcoef(image_1, image_2):
    """Return a distance between two images corresponding to 1 minus the
    correlation coefficient between them. This can go from 0 to 2."""

    dist = 0
    for x1, x2 in zip(image_1, image_2):
        dist += (1 - np.corrcoef(x1.ravel(), x2.ravel())[0, 1])/len(image_1)
    return dist


def get_thumbnail(dataset, channel, t, scale):
    """Return low-resolution thumbnail of data volume."""

    v = get_slice(dataset, t)
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


def get_all_pdists(dataset, shape_t, channel,
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

    print('Compiling thumbnails...')
    thumbnails = [get_thumbnail(dataset, channel, t, scale) for t in range(shape_t)]

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
    for i in (tqdm(range(shape_t), desc='Calculating distances', unit='frames') if pbar else range(shape_t)):

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


def recommend_frames(
    dataset, n_frames, n_iter, t_list, channel,
    save_to_metadata, verbose
):

    if str(dataset)[-1] == '"':
        dataset = Path(str(dataset)[:-1])
    if str(dataset)[0] == '"':
        dataset = Path(str(dataset)[1:])

    metadata = get_metadata(dataset)
    shape_t = metadata['shape_t']
    if t_list is None:
        t_list = list(range(shape_t))

    print('Building frame correlation graph...')
    d_full = get_all_pdists(dataset, shape_t, channel, pbar=True)
    d_slice = (d_full[t_list, :])[:, t_list]

    scores = np.mean(d_slice, axis=-1)
    opt_score, med_idx = np.min(scores), np.argmin(scores)

    i_ref = [med_idx]
    t_ref = [t_list[med_idx]]
    s_ref = [opt_score]
    scores = d_slice[med_idx, :]
    pbar = tqdm(range(n_frames - 1), desc='Optimizing reference frames', unit='n_frames', leave=False, file=sys.stdout)
    for i in pbar:
        d_adj = np.append(
            d_slice.copy()[:, :, None],
            np.tile(scores[None, :, None], (d_slice.shape[0], 1, 1)),
            axis=-1
        )
        d_opt = np.min(d_adj, axis=-1)
        iscores = np.mean(d_opt, axis=-1)
        opt_score, new_midx = np.min(iscores), np.argmin(iscores)

        i_ref.append(new_midx)
        t_ref.append(t_list[new_midx])
        s_ref.append(opt_score)
        scores = d_opt[new_midx, :]

    print(f'\nIterating over found reference frames...')
    n_i = 0
    while True:
        if 0 <= n_iter <= n_i:
            break
        kscore = opt_score
        for i in range(n_frames):
            i_ref_temp = i_ref.copy()
            i_ref_temp.pop(i)
            d_adj = d_slice.copy()[:, :, None]
            for t in i_ref_temp:
                d_adj = np.append(
                    d_adj,
                    np.tile(d_slice.copy()[t, None, :, None],
                            (d_adj.shape[0], 1, 1)),
                    axis=-1
                )

            iscores = np.mean(np.min(d_adj, axis=-1), axis=-1)
            jscore, new_midx = np.min(iscores), np.argmin(iscores)

            if jscore < kscore:
                i_ref[i] = new_midx
                t_ref[i] = t_list[new_midx]
                kscore = jscore

        if kscore < opt_score:
            opt_score = kscore
            n_i += 1
        else:
            break

    if save_to_metadata:
        update_metadata(dataset, {f't_ref_fn{len(t_list)}': [int(i) for i in t_ref]})

    return t_ref


def main():
    args = docopt(__doc__, version=f'ZephIR recommend_frames {__version__}')
    #print(args, '\n')

    t_ref = recommend_frames(
        dataset=Path(args['--dataset']).parent,
        n_frames=int(args['--n_frames']),
        n_iter=int(args['--n_iter']),
        t_list=eval(args['--t_list']) if args['--t_list'] else None,
        channel=int(args['--channel']) if args['--channel'] else None,
        save_to_metadata=args['--save_to_metadata'] in ['True', 'Y', 'y'],
        verbose=args['--verbose'] in ['True', 'Y', 'y'],
    )

    return t_ref


if __name__ == '__main__':
    t_ref = main()
    t_ref.sort()
