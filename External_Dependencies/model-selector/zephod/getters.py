"""
To ease the pain of ensuring compatibility with new data structures or datasets,
this file collects key IO functions for data and annotations
that may be edited by a user to fit their particular use case.
"""

import h5py
import json
import numpy as np
import pandas as pd
from pathlib import Path


# default getters
def get_slice(dataset: Path, t: int) -> np.ndarray:
    """Return a slice at specified index t.
    This should return a 4-D numpy array containing multichannel volumetric data
    with the dimensions ordered as (C, Z, Y, X).
    """
    h5_filename = dataset / "data.h5"
    f = h5py.File(h5_filename, 'r')
    return f["data"][t]


def get_times(dataset_path: Path) -> np.ndarray:
    """Return time indices in a dataframe.
    This should return a 1-D numpy array containing integer indices for get_slice().
    """
    h5_filename = dataset_path / "data.h5"
    f = h5py.File(h5_filename, 'r')
    return np.arange(len(f["times"][:]))


def get_metadata(dataset: Path) -> dict:
    """Load and return metadata for the dataset as a Python dictionary.
    This should contain at least the following:
    - shape_t
    - shape_c
    - shape_z
    - shape_y
    - shape_x
    """
    json_filename = dataset / "metadata.json"
    with open(json_filename) as json_file:
        metadata = json.load(json_file)
    return metadata


def get_annotation_df(dataset: Path) -> pd.DataFrame:
    """Load and return annotations as an ordered pandas dataframe.
    This should contain the following:
    - t_idx: time index of each annotation
    - x: x-coordinate as a float between (0, 1)
    - y: y-coordinate as a float between (0, 1)
    - z: z-coordinate as a float between (0, 1)
    - worldline_id: track or worldline ID as an integer
    - provenance: scorer or creator of the annotation as a byte string
    """
    with h5py.File(dataset / 'annotations.h5', 'r') as f:
        data = pd.DataFrame()
        for k in f:
            data[k] = f[k]
    return data


def get_annotation(annotation, t, exclusive_prov=None, exclude_self=True):
    annot = np.stack(
        [(annotation['x'][annotation['t_idx'] == t]).astype(float) * 2 - 1,
         (annotation['y'][annotation['t_idx'] == t]).astype(float) * 2 - 1,
         (annotation['z'][annotation['t_idx'] == t]).astype(float) * 2 - 1
         ], axis=-1
    )
    worldline_id = annotation['worldline_id'][annotation['t_idx'] == t]
    provenance = np.array(annotation['provenance'][annotation['t_idx'] == t])
    if exclusive_prov is not None:
        annot = annot[provenance == exclusive_prov, :]
        worldline_id = worldline_id[provenance == exclusive_prov]
        provenance = provenance[provenance == exclusive_prov]
    elif exclude_self:
        annot = annot[provenance != b'ZEIR', :]
        worldline_id = worldline_id[provenance !=  b'ZEIR']
        provenance = provenance[provenance != b'ZEIR']

    u, i, c = np.unique(worldline_id, return_index=True, return_counts=True)
    ovc_idx = np.where(c > 1)[0]
    for j in ovc_idx:
        i[j] = np.where(worldline_id == u[j])[0][-1]
    return u, annot[i, ...], provenance[i]
