import sys
import scipy
import numpy as np
from tqdm import tqdm


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


cache_path = sys.argv[1]
video_neurons_validation = scipy.io.loadmat(cache_path)
video_neurons = load_annotations(cache_path)

valid_worldlines = {}
invalid_worldlines = []

for i in tqdm(range(len(video_neurons['worldline'])), desc="Validating neuron structure...", leave=True):
    if isinstance(video_neurons['worldline'][i][0][0][0][0], str) and isinstance(video_neurons['worldline'][i][0][0][2],
                                                                                 np.ndarray):
        # print(f"Validated {video_neurons['worldline'][i][0][0][0][0]} wordline integrity.")
        valid_worldlines[video_neurons['worldline'][i][0][0][0][0]] = {
            'provenance': video_neurons['provenance'][i],
            'color': video_neurons['worldline'][i][0][0][2],
            't': {}
        }

        for eachFrame in range(len(video_neurons['rois'][i][0])):
            valid_worldlines[video_neurons['worldline'][i][0][0][0][0]]['t'][eachFrame] = {
                'x': video_neurons['rois'][i][0][eachFrame][0],
                'y': video_neurons['rois'][i][0][eachFrame][1],
                'z': video_neurons['rois'][i][0][eachFrame][2]
            }
    else:
        invalid_worldlines += [i]
        # print(f"{video_neurons['worldline'][i][0][0][0][0]} wordline integrity compromised: Name -> {isinstance(video_neurons['worldline'][i][0][0][0][0], str)} ({type(video_neurons['worldline'][i][0][0][0])}); Color -> {isinstance(video_neurons['worldline'][i][0][0][2], np.ndarray)} ({type(video_neurons['worldline'][i][0][0][2])}).")

print(f"Ignoring worldlines {invalid_worldlines} due to lack of IDs.", flush=True)
print(f"Validated {len(valid_worldlines.keys())}/{len(video_neurons['worldline'])} ({round((len(valid_worldlines.keys()) / len(video_neurons['worldline'])) * 100)}%) worldlines across {len(video_neurons['rois'][i][0])} frames.", flush=True)

