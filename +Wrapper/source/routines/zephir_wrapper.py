from zephir.annotator.data.annotations_io import Annotation, AnnotationTable, Worldline, WorldlineTable
from zephir.annotator.data.transform import coords_from_idx
from zephir.models.container import Container

from typing import Union

from ..data_loader import load_vt_cache
from ..validation import is_valid_annotation

from ..clibs.recommend_frames import *
from ..clibs.extract_traces import *
from ..clibs.save_movie import *
from ..clibs.build_tree import *
from ..clibs.track_all import *
from ..clibs.n_io import *

import shutil
import sys


def convert(config):
    vt_cache = load_vt_cache(config['cache'])
    indices = config['dim_index']
    provenances = vt_cache['provenances']
    worldlines = vt_cache['worldlines']
    annotations = vt_cache['frames']

    W = WorldlineTable()
    for each_worldline in tqdm(worldlines, desc="Processing wordlines...", leave=True):
        if len(each_worldline['name']) > 1:
            w = Worldline()
            w.id = each_worldline['id']
            w.name = each_worldline['name']
            w.color = each_worldline['color']
            w.provenance = each_worldline['provenance']
            W._insert_and_preserve_id(w)

    A = AnnotationTable()
    volume_shape = (config['nx'], config["ny"], config["nz"])
    for each_annotation in tqdm(annotations, desc="Processing annotations...", leave=True):
        a = Annotation()

        a.id = each_annotation[indices['annotation_id']]
        a.t_idx = each_annotation[indices['t']]

        x = each_annotation[indices['x']]
        y = each_annotation[indices['y']]
        z = each_annotation[indices['z']]
        (a.y, a.x, a.z) = coords_from_idx([x, y, z], volume_shape)

        a.worldline_id = each_annotation[indices['worldline_id']]
        a.provenance = provenances[each_annotation[indices['provenance_id']]]

        if is_valid_annotation(a):
            A.insert(a)

    A.to_hdf(config['output_path'] / "annotations.h5")
    W.to_hdf(config['output_path'] / "worldlines.h5")


def recommend_frames(
        dataset: Path,
        n_frames: int, n_iter: int, t_list: Union[list, None] = None, channel: int = 0,
        save_to_metadata: Union[bool, None] = None, **kwargs):
    if t_list is None:
        t_list = list(range(kwargs['nt']))

    print('Building frame correlation graph...', flush=True)
    d_full = get_all_pdists(dataset, dataset.name, kwargs['nt'], channel, pbar=True)
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

    print(f'\nIterating over found reference frames...', flush=True)
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

    return 'recommended_frames', t_ref


def track_neurons(**kwargs):
    dataset = kwargs['dataset']
    if not (dataset / 'backup').is_dir():
        Path.mkdir(dataset / 'backup')

    if kwargs['load_checkpoint']:
        args = n_io.get_checkpoint(dataset, 'args', verbose=True, filename=dataset.name)
        state = n_io.get_checkpoint(dataset, 'state', filename=dataset.name)
        if args is None or state is None:
            print('*** CHECKPOINT EMPTY! Exiting...')
            exit()
    else:
        if kwargs['load_args'] and (dataset / 'args.json').is_file():
            with open(str(dataset / 'args.json')) as json_file:
                args = json.load(json_file)

        n_io.update_checkpoint(
            dataset,
            {'state': 'init',
             '__version__': kwargs['version'],
             'args': args},
            filename=dataset.name
        )
        state = 'init'

    # checking for available CUDA GPU
    if kwargs['cuda'] and torch.cuda.is_available():
        print('\n*** GPU available!')
        dev = 'cuda'
    # elif torch.backends.mps.is_available():
    #     dev = 'mps'
    else:
        dev = 'cpu'
    print(f'\nUsing device: {dev}\n\n')

    # building/loading variable container
    if state == 'init':

        print("Initializing...")
        container = Container(dev=dev, **kwargs)
        n_io.update_checkpoint(dataset, {'state': 'load'}, filename=dataset.name)
        state = 'load'

    else:
        container = n_io.get_checkpoint(dataset, 'container', filename=dataset.name)

    # building annotations table and tracking models
    if state == 'load':

        print("Loading...")
        container, results = build_annotations(container=container, annotation=None, **kwargs)

        n_io.update_checkpoint(dataset, {'state': 'build'}, filename=dataset.name)
        state = 'build'

    else:
        results = n_io.get_checkpoint(dataset, 'results', filename=dataset.name)

    # compiling spring network and frame tree
    if state == 'build':

        print("Building...")
        print("Building models!")
        container, zephir, zephod = build_models(
            container=container,
            dimmer_ratio=kwargs['dimmer_ratio'],
            grid_shape=(5, 2 * (kwargs['grid_shape'] // 2) + 1,
                        2 * (kwargs['grid_shape'] // 2) + 1),
            fovea_sigma=(1, kwargs['fovea_sigma'],
                         kwargs['fovea_sigma']),
            n_chunks=kwargs['n_chunks'],
        )

        print("Building springs!")
        container = build_springs(container=container, **kwargs)

        print("Building trees!")
        container = build_tree(container=container, filename=dataset.name, **kwargs)

        n_io.update_checkpoint(dataset, {'state': 'track', '_t_list': None}, filename=dataset.name)
        state = 'track'

    else:
        zephir = get_checkpoint(dataset, 'zephir', filename=dataset.name)
        zephod = get_checkpoint(dataset, 'zephod', filename=dataset.name)

    # tracking all frames in _t_list
    if state == 'track':

        print("Tracking all!")
        container, results = track_all(
            container=container, zephir=zephir, zephod=zephod, results=results,
            n_epoch_d=kwargs['n_epoch_d'] if kwargs['lambda_d'] > 0 else 0, _t_list=get_checkpoint(dataset, '_t_list'),
            filename=dataset.name, **kwargs
        )

    else:
        results = n_io.get_checkpoint(dataset, 'results', verbose=True, filename=dataset.name)

    if np.any(np.isnan(results)):
        print(f'*** WARNING: NaN found in: '
              f'{list(np.unique(np.where(np.isnan(results))[0]))}')
        results = np.where(np.isfinite(results), results, 0)
        n_io.update_checkpoint(dataset, {'results': results}, filename=dataset.name)

    save_annotations(
        container=container,
        results=results,
        save_mode=kwargs['save_mode']
    )

    save_movie(
        container=container,
        results=results,
        filename=dataset.name
    )

    now = datetime.datetime.now()
    now_ = now.strftime("%m_%d_%Y_%H_%M_%S")
    shutil.copy(dataset / 'checkpoint.pt',
                dataset / 'backup' / f'checkpoint_{now_}.pt')

    print('\n\n*** DONE!')
    return


def extract_activity(**kwargs):
    extract_traces(filename=kwargs['dataset'].name, **kwargs)
