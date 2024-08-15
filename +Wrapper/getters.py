"""
To ease the pain of ensuring compatibility with new data structures or datasets,
this file collects key IO functions for data, metadata, and annotations
that may be edited by a user to fit their particular use case.
"""

import os
import h5py
import json
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Optional
from pynwb import NWBHDF5IO
from pims import ND2_Reader
import numpy as np
import cv2

nwbfile = None
nd2file = None

# default getters
def get_slice(dataset: Path, t: int, filename: Optional[str] = None) -> np.ndarray:
    """Return a slice at specified index t.
    This should return a 4-D numpy array containing multi-channel volumetric data
    with the dimensions ordered as (C, Z, Y, X).
    """
    global nwbfile
    global nd2file

    if filename is None:
        h5_filename = dataset / "data.h5"
    else:
        filename = Path(dataset / filename)

        if filename.suffix == '.h5':
            f = h5py.File(dataset / filename, 'r')
            frame = f["data"][t]
        elif filename.suffix == '.nwb':
            if nwbfile is None:
                io = NWBHDF5IO(filename, mode="r")
                nwbfile = io.read()

            if 'CalciumImageSeries' in nwbfile.acquisition.keys():
                targ_mod = nwbfile.acquisition['CalciumImageSeries']
            else:
                for eachKey in nwbfile.acquisition.keys():
                    if 'Calcium' in eachKey:
                        targ_mod = nwbfile.acquisition[eachKey]

            if 'targ_mod' not in locals():
                raise KeyError(f"Unable to find any Calcium key in {filename} acquisition module.")

            frame = targ_mod.data[t, :, :, :, :].astype(np.uint8)
            frame = np.transpose(frame, [3, 2, 1, 0])

        elif filename.suffix == '.nd2':
            if nd2file is None:
                nd2file = ND2_Reader(filename)

            if 't' in nd2file.sizes:
                nd2file.bundle_axes = ['c', 'z', 'y', 'x']
                frame = (nd2file[t] * 255).astype(np.uint8)
            else:
                raise KeyError(f"Unable to find time dimension in {filename}.")
        else:
            h5_filename = dataset / filename

        #if t % 13 == 0:
        #    cache_loc = dataset / f'frame-{t}.npy'
        #    np.save(cache_loc, frame)

    return frame


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
