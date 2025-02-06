from pathlib import Path

import mat73
import scipy.io as sio

from .validation import is_file


def load_mat(path):
    try:
        data = sio.loadmat(path)
    except:
        data = mat73.loadmat(path)

        return data


def load_neuropal_file(path):
    data = load_mat(path)

    if not is_file('neuropal', data):
        return

    return data


def load_config(path):
    data = load_mat(path)
    d_keys = data.keys()

    #if not is_file('config', data):
    #    return data

    for each_arg in d_keys:
        match each_arg:
            case 'dataset':
                data[each_arg] = Path(data[each_arg].replace('"', ''))

            case "save_mode" | "sort_mode":
                data[each_arg] = str(data[each_arg])

            case "save_to_metadata" | "verbose" | "motion_predict" | "exclude_self" | "include_all" | "cuda" | \
                 "allow_rotation" | "debleach":
                data[each_arg] = bool(data[each_arg])

            case "nx" | "ny" | "nz" | "nt" | "nc" | "channel" | "grid_shape" | "nn_max" | "rma_channel":
                data[each_arg] = int(data[each_arg])

            case "clip_grad" | "lambda_t" | "lambda_d" | "lambda_n" | "lr_ceiling" | "lr_floor" | "lr_coef" | "gamma" |\
                 "z_compensator" | "dist_thresh" | "cutoff":
                data[each_arg] = float(data[each_arg])

            case _:
                if each_arg[:2] == "n_":
                    data[each_arg] = int(data[each_arg])

                elif (data[each_arg][0] == "[" and data[each_arg][-1:]) or data[each_arg] == "None":
                    data[each_arg] = eval(data[each_arg])

                elif data[each_arg] in ["True", "true", "False", "false", "Y", "y", "N", "n"]:
                    data[each_arg] = bool(data[each_arg])

    return data


def load_vt_cache(path):
    data = load_mat(path)

    if not is_file('vt_cache', data):
        return

    return data
