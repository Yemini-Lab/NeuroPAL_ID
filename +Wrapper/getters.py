"""
To ease the pain of ensuring compatibility with new data structures or datasets,
this file collects key IO functions for data, metadata, and annotations
that may be edited by a user to fit their particular use case.
"""

import h5py
import json
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Optional
from pynwb import NWBHDF5IO
from pims import ND2_Reader

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

    filename = dataset / "data.h5" if filename is None else Path(dataset / filename)

    if filename.suffix == '.h5':
        with h5py.File(filename, 'r') as f:
            frame = f["data"][t]
        if frame.ndim == 4:
            # MATLAB writes /data as [Y X Z C T], which h5py exposes as
            # [T C Z X Y]. ZephIR expects [C Z Y X].
            frame = np.transpose(frame, [0, 1, 3, 2])
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

        frame = targ_mod.data[t, :, :, :, :]
        frame = np.transpose(frame, [3, 2, 1, 0])

    elif filename.suffix == '.nd2':
        if nd2file is None:
            try:
                nd2file = ND2_Reader(filename)
            except ImportError as exc:
                raise ImportError(
                    "Python ND2 reading requires pims_nd2, which is not "
                    "installed in this environment. Convert the video to the "
                    "chunked HDF5 data.h5 format before running ZephIR "
                    "tracking/recommendation/extraction."
                ) from exc

        if 't' in nd2file.sizes:
            nd2file.bundle_axes = ['c', 'z', 'y', 'x']
            frame = np.asarray(nd2file[t])
        else:
            raise KeyError(f"Unable to find time dimension in {filename}.")
    else:
        raise ValueError(f"Unsupported video file type: {filename.suffix}")

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
