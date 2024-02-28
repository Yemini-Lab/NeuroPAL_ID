import sys

import numpy as np
import pandas as pd
import scipy
from scipy.io import loadmat
from tqdm import tqdm
from zephir.annotator.data.annotations_io import Annotation, AnnotationTable, Worldline, WorldlineTable
from zephir.annotator.data.transform import coords_from_idx
from zephir.methods import *
from zephir.methods import *
from zephir.utils import io

from pathlib import Path


def convert_array_to_list(array):
    """
    Convert a numpy structured array into a list of dictionaries.
    """
    if array.dtype.names is None:  # It's a regular ndarray
        return array.tolist()
    else:  # It's a structured array, convert each element to a dictionary
        return [convert_struct_to_dict(item) for item in array]


def convert_struct_to_dict(mat_struct):
    """
    Recursively convert a MATLAB struct loaded with scipy.io.loadmat
    into a nested Python dictionary.
    """
    if mat_struct is None:
        return None
    if isinstance(mat_struct, np.ndarray):
        # Handle the case where it's a structured array
        if mat_struct.dtype.names is not None:
            result = {}
            for name in mat_struct.dtype.names:
                # Recurse into each field
                element = mat_struct[name][0]  # Assuming single-element struct arrays
                result[name] = convert_array_to_list(element)
            return result
        else:
            return convert_array_to_list(mat_struct)
    else:
        return mat_struct


def load_annotations(file_path):
    """
    Load MATLAB .mat file and convert its 'annotations' contents into a Python dictionary.
    """
    data = scipy.io.loadmat(file_path)
    annotations = data['annotations']
    return convert_struct_to_dict(annotations)


def cellid_to_annotator(video_path, metadata, data):
    shape = (metadata["ny"], metadata["nx"], metadata["nz"])
    names = list(data.keys())

    A = AnnotationTable()
    W = WorldlineTable()
    processed = []

    # Generate worldline.h5
    for eachIdx in tqdm(range(len(names)), desc="Processing wordlines...", leave=True):
        if eachIdx in processed:
            pass
        else:
            w = Worldline()
            w.id = eachIdx
            w.name = names[eachIdx]
            W._insert_and_preserve_id(w)

    # Generate annotations.h5
    frames = range(metadata["nt"])

    annotation_idx = 0
    no_annotations = 0

    for t in tqdm(frames, desc='Processing frames...', leave=True):
        for eachWL in tqdm(range(len(names)), desc='Processing annotations...', leave=False):
            a = Annotation()
            a.id = annotation_idx + 1
            a.t_idx = t
            try:
                position = (valid_worldlines[names[eachWL]]['t'][t]['y'], valid_worldlines[names[eachWL]]['t'][t]['x'], valid_worldlines[names[eachWL]]['t'][t]['z'])
            except:
                no_annotations += 1
            (a.y, a.x, a.z) = coords_from_idx(position, shape)
            a.worldline_id = eachWL
            a.provenance = valid_worldlines[names[eachWL]]['provenance']
            if a.x.size > 0 and a.y.size > 0 and a.z.size > 0:
                A.insert(a)
                annotation_idx += 1

    '''
    for eachWL in tqdm(range(len(names)), desc='Processing annotations...', leave=True):
        for t in tqdm(frames, desc='Processing frames...', leave=False):
            a = Annotation()
            a.id = annotation_idx + 1
            a.t_idx = t
            try:
                position = (valid_worldlines[names[eachWL]]['t'][t]['y'], valid_worldlines[names[eachWL]]['t'][t]['x'], valid_worldlines[names[eachWL]]['t'][t]['z'])
            except:
                no_annotations += 1
            (a.y, a.x, a.z) = coords_from_idx(position, shape)
            a.worldline_id = eachWL
            a.provenance = valid_worldlines[names[eachWL]]['provenance']
            if a.x.size > 0 and a.y.size > 0 and a.z.size > 0:
                A.insert(a)
                annotation_idx += 1
    '''

    A.to_hdf(video_path / "annotations.h5")
    print(f"Saved annotations for {len(frames)-no_annotations}/{len(frames)} frames to {video_path / 'annotations.h5'}.", flush=True)

    W.to_hdf(video_path / "worldlines.h5")
    print(f"Saved worldlines to {video_path / 'worldlines.h5'}.", flush=True)


cache_path = sys.argv[1]
meta_path = sys.argv[2]
video_path = Path(sys.argv[3]).parent
video_neurons = load_annotations(cache_path)
video_info = scipy.io.loadmat(meta_path)

valid_worldlines = {}
invalid_worldlines = []

print(video_info['info'][0][0])

for i in tqdm(range(4), desc="Extracting video metadata...", leave=True):
    metadata = {
        'path': video_info['info'][0][0][0][0],
        'nx': video_info['info'][0][0][1][0][0],
        'ny': video_info['info'][0][0][2][0][0],
        'nz': video_info['info'][0][0][3][0][0],
        'nc': video_info['info'][0][0][4][0][0],
        'nt': video_info['info'][0][0][5][0][0]
    }

for i in tqdm(range(len(video_neurons['worldline'])), desc="Validating neuron structure...", leave=True):
    if isinstance(video_neurons['worldline'][i][0][0][0][0], str) and isinstance(video_neurons['worldline'][i][0][0][2],
                                                                                 np.ndarray):
        # print(f"Validated {video_neurons['worldline'][i][0][0][0][0]} wordline integrity.")
        valid_worldlines[video_neurons['worldline'][i][0][0][0][0]] = {
            'provenance': video_neurons['provenance'][i][0],
            'color': video_neurons['worldline'][i][0][0][2][0],
            't': {}
        }

        for eachFrame in range(len(video_neurons['rois'][i][0])):
            try:
                valid_worldlines[video_neurons['worldline'][i][0][0][0][0]]['t'][eachFrame] = {
                    'x': video_neurons['rois'][i][0][eachFrame][0][0],
                    'y': video_neurons['rois'][i][0][eachFrame][1][0],
                    'z': video_neurons['rois'][i][0][eachFrame][2][0]
                }
            except:
                print(f"Failed on frame {eachFrame}.", flush=True)
                quit()
    else:
        invalid_worldlines += [i]
        # print(f"{video_neurons['worldline'][i][0][0][0][0]} wordline integrity compromised: Name -> {isinstance(video_neurons['worldline'][i][0][0][0][0], str)} ({type(video_neurons['worldline'][i][0][0][0])}); Color -> {isinstance(video_neurons['worldline'][i][0][0][2], np.ndarray)} ({type(video_neurons['worldline'][i][0][0][2])}).")

print(f"Ignoring worldlines {invalid_worldlines} due to lack of IDs.", flush=True)
print(f"Validated {len(valid_worldlines.keys())}/{len(video_neurons['worldline'])} ({round((len(valid_worldlines.keys()) / len(video_neurons['worldline'])) * 100)}%) worldlines across {len(video_neurons['rois'][i][0])} frames.", flush=True)
cellid_to_annotator(video_path, metadata, valid_worldlines)