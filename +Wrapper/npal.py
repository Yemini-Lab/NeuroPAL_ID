"""
npal.py: Core middle man between NeuroPAL_ID's MATLAB code and its various Python-based dependencies.

Usage:
    npal.py -h | --help
    npal.py -v | --version
    npal.py --operation=<operation> --dataset=<dataset>

Options:
    -h --help                           	show this message and exit.
    -v --version                        	show version information and exit.
    --operation=<operation>                 indicates which action is to be executed.
    --dataset=<dataset>  					path to data directory to analyze.
"""

import source.routines.zephir_wrapper as zephir_wrapper
from source.data_loader import load_config
from __version__ import __version__
from docopt import docopt
import sys


def wrap(label, result):
    print("wrap func tbd")


def main():
    args = {}
    raw_args = docopt(__doc__, version=f'NPAL Core {__version__}')
    for each_key in raw_args.keys():
        args[each_key.replace('--', '')] = raw_args[each_key]

    config = load_config(args['config'])
    config['is_deployed'] = getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS')
    config['version'] = __version__

    match args['operation']:
        case "zephir_convert":
            result_label, result = zephir_wrapper.convert(**args)

        case "zephir_recommend_frames":
            result_label, result = zephir_wrapper.recommend_frames(**args)

        case "zephir_track":
            result_label, result = zephir_wrapper.track_neurons(**args)

        case "zephir_extract":
            result_label, result = zephir_wrapper.extract_activity(**args)

        case _:
            return

    wrap(result_label, result)


if __name__ == '__main__':
    main()
