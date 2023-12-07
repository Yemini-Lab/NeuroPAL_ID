import os
import sys
import pandas as pd
from scipy.io import loadmat
import numpy as np
import h5py
from typing import Tuple, Optional
from zephir.annotator import *
from zephir.__version__ import __version__
from zephir.methods import *
from zephir.models.container import Container
from zephir.utils import io
from zephir.annotator.data.annotations_io import Annotation, AnnotationTable, Worldline, WorldlineTable
from zephir.annotator.data.transform import coords_from_idx
from pathlib import Path
from dataclasses import asdict
from tqdm import tqdm

dataset = Path(sys.argv[1])
video_path = Path(sys.argv[2])
#annotation_path = Path(sys.argv[3])
metadata_path = Path(sys.argv[3])
color_stack = Path(sys.argv[4])
csv_path = Path(sys.argv[5])

def load_annotations(dataset: Optional[Path] = None
                     ) -> Tuple[AnnotationTable, WorldlineTable]:
    if dataset is None:
        dataset = Path(".")
    annotation_file = dataset / "annotations.h5"
    if annotation_file.exists():
        annotations = AnnotationTable.from_hdf(dataset)
    else:
        annotations = AnnotationTable()
    worldline_file = dataset / "worldlines.h5"
    if worldline_file.exists():
        worldlines = WorldlineTable.from_hdf(worldline_file)
    else:
        worldlines = WorldlineTable.from_annotations(annotations)
    return (annotations, worldlines)

def save_annotations(annotations: AnnotationTable,
                     worldlines: WorldlineTable,
                     dataset: Path = None,
                     current_frame=None) -> None:
    if dataset is None:
        dataset = Path(".")
    if ".nwb" in str(dataset):
        dataset = Path(str(dataset).replace('.nwb',''))
    annotation_file_path = dataset / "annotations.h5"
    print(f"Saved annotations to {annotation_file_path}.", flush=True)

    # File doesn't exist, just save
    annotations.to_hdf(annotation_file_path)
    # Save worldlines
    worldlines.to_hdf(dataset / "worldlines.h5")
    print(f"Saved worldlines to {dataset / 'worldlines.h5'}.", flush=True)

def cellid_to_annotator(dataset, video_path, metadata_path, color_stack, csv_path):
    gcamp = video_path
    metadata = io.get_metadata(metadata_path)
    shape = (metadata["shape_y"], metadata["shape_x"], metadata["shape_z"])

    # Read the CSV file
    csv_data = pd.read_csv(csv_path)
    names = csv_data['Name'].values
    ids = csv_data['TrackID'].values

    A = AnnotationTable()
    W = WorldlineTable()
    processed = []

    #Generate worldline.h5
    for eachNeuron in tqdm(range(len(ids)), desc="Processing wordlines...", leave=False):
        if ids[eachNeuron] in processed:
            pass
        else:
            w = Worldline()
            w.id = ids[eachNeuron]
            w.name = names[eachNeuron]
            W._insert_and_preserve_id(w)

    # Check if 'Frame' column exists, case-insensitive
    frame_col = next((col for col in csv_data.columns if col.lower() == 'frame'), None)
    if frame_col:
        frames = np.unique(csv_data[frame_col].values)

        for t in tqdm(frames, desc="Processing annotations...", leave=False):
            frame_data = csv_data[csv_data[frame_col] == t]

            for i, (index, row) in enumerate(frame_data.iterrows()):
                a = Annotation()
                a.id = i + 1
                a.t_idx = t
                position = (row['Y'], row['X'], row['Z'])
                (a.y, a.x, a.z) = coords_from_idx(position,shape)
                a.worldline_id = row['TrackID']
                a.provenance = b"NPAL"
                A.insert(a)

            save_annotations(A, W, color_stack)
            save_annotations(A, W, gcamp)
    else:
        frames = [0, 1]  # Default frames if 'Frame' column is not present

        for t in tqdm(frames, desc="Processing annotations...", leave=False):
            for i, (index, row) in enumerate(csv_data.iterrows()):
                a = Annotation()
                a.id = i + 1
                a.t_idx = t
                position = (row['Y'], row['X'], row['Z'])
                #print(position)
                (a.y, a.x, a.z) = coords_from_idx(position,shape)
                a.worldline_id = row['TrackID']
                a.provenance = b"NPAL"
                A.insert(a)

            save_annotations(A, W, color_stack)
            save_annotations(A, W, gcamp)


cellid_to_annotator(dataset, video_path, metadata_path, color_stack, csv_path)