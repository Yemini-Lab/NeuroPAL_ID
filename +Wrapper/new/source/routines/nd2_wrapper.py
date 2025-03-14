import os
import warnings
from os import PathLike
from typing import Union, Tuple

import nd2
import numpy as np
import pandas as pd
from dask.array import Array
from nd2.structures import Metadata
from numpy import ndarray

from ..helpers import writer


def read(
    dataset: Union[str, PathLike],
    is_lazy: bool = False,
    **kwargs
) -> Tuple[Metadata, Array | ndarray]:
    """
    Read an ND2 dataset and return its metadata and volume data.

    Parameters
    ----------
    dataset : str or PathLike
        Path to the ND2 file.
    is_lazy : bool, optional
        If True, use dask-based lazy reading (default: False).
    **kwargs
        Additional keyword arguments (currently unused).

    Returns
    -------
    metadata : Metadata
        ND2 metadata object.
    volume : dask.array.Array or numpy.ndarray
        Image volume. A dask array if is_lazy=True, otherwise a NumPy array.
    """
    # One-liner for metadata is possible, but clarity can be improved
    with nd2.ND2File(dataset) as f:
        metadata = f.metadata

    # nd2.imread handles its own open/close but doesn't expose the ND2File
    if is_lazy:
        volume = nd2.imread(dataset, dask=True)
    else:
        volume = nd2.imread(dataset)

    return metadata, volume


def convert(
    dataset: Union[str, PathLike],
    target_path: Union[str, PathLike],
    is_lazy: bool = False,
    **kwargs
) -> Tuple[int, str]:
    """
    Convert an ND2 dataset to a specified file format using a writer function.

    Parameters
    ----------
    dataset : str or PathLike
        Path to the ND2 file.
    target_path : str or PathLike
        Path to the output file with a known extension (e.g., .tiff).
    is_lazy : bool, optional
        If True, use dask-based lazy reading (default: False).
    **kwargs
        Additional keyword arguments (currently unused).

    Returns
    -------
    code : int
        Zero if successful, nonzero otherwise.
    status : str
        Message describing success or failure of the write operation.
    """
    metadata, volume = read(dataset=dataset, is_lazy=is_lazy)

    # Extract extension without the leading period
    fmt = os.path.splitext(target_path)[1].lstrip(".")
    func_string = f"write_to_{fmt}"

    if hasattr(writer, func_string):
        write_func = getattr(writer, func_string)
        code, status = write_func(
            source=volume,
            documentation=metadata,
            dimensions=np.shape(volume),
            target_path=target_path
        )
    else:
        status = f"No known write function for target format: {fmt}"
        warnings.warn(status, UserWarning)
        code = 1

    return code, status


def framedata(dataset: Union[str, PathLike], **kwargs) -> pd.DataFrame:
    """
    Extract frame-level information from ND2 events into a Pandas DataFrame.

    Parameters
    ----------
    dataset : str or PathLike
        Path to the ND2 file.
    **kwargs
        - target_headers : list of str, optional
            A list of event keys to extract into the DataFrame.
            If not provided, use all keys from the first event.

    Returns
    -------
    pd.DataFrame
        A DataFrame of per-frame metadata extracted from ND2 events.
    """
    with nd2.ND2File(dataset) as f:
        events = f.events()

    target_headers = kwargs.get("target_headers", None)
    headers = list(events[0].keys()) if (events and not target_headers) else target_headers

    rows = [
        {h: entry.get(h, None) for h in headers}
        for entry in events
    ]

    return pd.DataFrame(rows, columns=headers)
