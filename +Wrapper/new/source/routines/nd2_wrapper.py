import os
import warnings
from os import PathLike
from typing import Union

import nd2
import numpy as np
import pandas as pd
from dask.array import Array
from nd2.structures import Metadata
from numpy import ndarray

from ..helpers import writer


def read(dataset: Union[str, PathLike],
         is_lazy: bool = False, **kwargs) -> tuple[Metadata, Array | ndarray]:

    metadata = nd2.ND2File(dataset).metadata

    if is_lazy:
        volume = nd2.imread(dataset, dask=True)
    else:
        volume = nd2.imread(dataset)

    return metadata, volume


def convert(dataset: Union[str, PathLike],
            target_path: Union[str, PathLike],
            is_lazy: bool = False, **kwargs) -> tuple[int, str]:

    metadata, volume = read(dataset=dataset, is_lazy=is_lazy)

    fmt = os.path.splitext(target_path)[1]
    func_string = f"write_to_{fmt}"

    if func_string in dir():
        write_func = getattr(writer, func_string)
        code, status = write_func(source=volume,
                                  dimensions=np.shape(volume),
                                  target_path=target_path)

    else:
        status = f"No known write function for target format {fmt}."
        warnings.WarningMessage(status)
        code = 1

    return code, status


def framedata(dataset: Union[str, PathLike], **kwargs) -> pd.DataFrame:
    metadata = nd2.ND2File(dataset).events()
    target_headers = kwargs.get('target_headers', None)
    headers = list(metadata[0].keys()) if not target_headers else target_headers

    rows = []
    for entry in metadata:
        rows.append({h: entry.get(h, None) for h in headers})

    df = pd.DataFrame(rows, columns=headers)
    return df
