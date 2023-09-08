import sys
import pandas as pd
from scipy.io import loadmat
import numpy as np

from zephir.annotator import *
from zephir.__version__ import __version__
from zephir.methods import *
from zephir.models.container import Container
from zephir.utils import io
from zephir.annotator.annotation_io import Annotation, AnnotationTable, Worldline, WorldlineTable
from zephir.annotator.data.transform import coords_from_idx
from pathlib import Path
from dataclasses import asdict

dataset = Path(sys.argv[1])
video_path = Path(sys.argv[2])
annotation_path = Path(sys.argv[3])
metadata_path = Path(sys.argv[4])
color_stack = Path(sys.argv[5])
csv_path = Path(sys.argv[6])

def save_annotations(annotations: AnnotationTable,
                     worldlines: WorldlineTable,
                     dataset: Path = None) -> None:

    if dataset is None:
        dataset = Path(".")

    annotations.to_hdf(dataset / "annotations.h5")
    worldlines.to_hdf(dataset / "worldlines.h5")

def cellid_to_annotator(dataset, video_path, annotation_path, metadata_path, color_stack, csv_path):
    gcamp = video_path
    metadata = io.get_metadata(metadata_path.parent)
    shape = (metadata["shape_y"], metadata["shape_x"], metadata["shape_z"])
    print(shape)

    # Read the CSV file
    csv_data = pd.read_csv(csv_path)
    positions = [tuple(map(float, pos.split(','))) for pos in csv_data['positions']]
    names = csv_data['name'].values

    # Convert positions to numpy array
    positions = np.array(positions)
    positions[:, 2] -= 1

    A = AnnotationTable()
    W = WorldlineTable()

    a = Annotation()
    for t in [0, 1]:
        for i, position in enumerate(positions):
            a = Annotation()
            w = Worldline()
            w.id = i
            w.name = names[i]
            a.id = i + 1
            a.t_idx = t
            (a.y, a.x, a.z) = coords_from_idx(position, shape)
            # account for movement in z
            # if t==2:
            #     a.z = a.z+.04
            # flip in special cases
            # a.z = 1-a.z
            # a.x = 1-a.x
            a.worldline_id = i
            a.provenance = b"NPAL"
            A.insert(a)
            # W.insert(w)
            if t == 0:
                W._insert_and_preserve_id(w)

    save_annotations(A, W, color_stack)
    save_annotations(A, W, gcamp)


cellid_to_annotator(dataset, video_path, annotation_path, metadata_path, color_stack, csv_path)
