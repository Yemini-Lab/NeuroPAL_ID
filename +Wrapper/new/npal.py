"""
npal.py: Core middle man between NeuroPAL_ID's MATLAB code and its various Python-based dependencies.

Usage:
    npal.py -h | --help
    npal.py -v | --version
    npal.py --operation=<operation> --config=<config> [options]
    npal.py --operation=<operation> --dataset=<dataset> [options]
    npal.py --operation=<operation> --dataset=<dataset> --config=<config> [options]

Options:
    -h --help                           show this message and exit.
    -v --version                        show version information and exit.
    -d --debug                          whether to enable debug prints.  [default: False]
    -p --profile                        whether to profile the script. [default: False]
    --operation=<operation>             indicates which action is to be executed.
    --dataset=<dataset>                 path to data directory to analyze.
    --config=<config>                   path to config file.
"""

import cProfile
import traceback
from docopt import docopt
from typing import Any, Optional

import matlab.engine

import source.routines.zephir_wrapper as zephir
from source.data_loader import load_config
from source.helpers.formats import *


def debug(out: Union[str, dict], title: str = None):
    if debug_mode:
        if title is not None or isinstance(out, dict):
            out = wrap(message=out, title=f"{sys._getframe().f_back.f_code.co_name}/{title}")

        print(out, flush=True)


def get_engine():
    """Seeks out matlab engine object.

    Returns:
        target_engine: The matlab.engine.MatlabEngine object.
        can_hook: Bool indicating whether the NeuroPAL_ID engine was found and hooked.
    """

    # Look for existing MATLAB sessions.
    existing_sessions = matlab.engine.find_matlab()
    debug(f"Shared MATLAB sessions: {existing_sessions}")

    # If at least one session was found, hook into it. If not, create a new session.
    can_hook = len(existing_sessions) > 0
    if can_hook:
        if 'NeuroPAL' in existing_sessions:
            session = 'NeuroPAL'
        else:
            session = existing_sessions[0]

        target_engine = matlab.engine.connect_matlab(session)
        state = f"Hooked NeuroPAL_ID engine..."
    else:
        target_engine = matlab.engine.start_matlab()
        state = f"Could not hook NeuroPAL_ID engine...\n" \
                f"Built new engine..."

    # Update state so NeuroPAL_ID knows what's going on.
    set_state(target_engine=target_engine, state=state)

    if profile_mode:
        pr.print_stats()

    return target_engine, can_hook


def set_task(target_engine: Optional[matlab.engine.MatlabEngine] = None,
             task: Union[str, int] = None, finish_last: bool = False):
    """Sets new task in MATLAB progress dialogue.

    Args:
        target_engine: The matlab.engine.MatlabEngine object containing the target progress dialogue.
        task: String label that will be placed in the progress dialogue.
        finish_last: Bool indicating whether the last task on the list should be removed.
    """

    if target_engine is None and is_hooked is True:
        target_engine = engine

    if finish_last:
        target_engine.Program.Wrappers.core.remove_task(task)

    if task is not None:
        target_engine.Program.Wrappers.core.add_task(task)


def set_state(target_engine: Optional[matlab.engine.MatlabEngine] = None,
              state: str = '', progress: float = 0.0):
    """Sets state in MATLAB progress dialogue.

    Args:
        target_engine: The matlab.engine.MatlabEngine object containing the target progress dialogue.
        state: String label that will be placed in the progress dialogue.
        progress: Float that the progress dialogue's value will be set to.
    """

    if target_engine is None and is_hooked is True:
        target_engine = engine

    debug(f"{state} (Progress: {progress})")
    target_engine.Program.Wrappers.core.state(state, progress)


def pass_data(results: Any,
              labels: Optional[str] = None,
              target_engine: Optional[matlab.engine.MatlabEngine] = None):
    """Passes data into target MATLAB engine's workspace.

    Args:
        results: The actual data to be passed.
        labels: Name of the variable that the data will be assigned to within the workspace.
        target_engine: The matlab.engine.MatlabEngine object containing the target progress dialogue.
    """

    if target_engine is None and len(engine) > 0:
        target_engine = engine

    if labels is None:
        labels = [traceback.format_stack()[-3:]]

    set_state(target_engine=target_engine, state=f"Passing data to engine...")
    if len(results) == 1 and len(labels) == 1:
        target_engine.workspace[labels] = results
    else:
        for each_label, each_result in labels, results:
            target_engine.workspace[each_label] = each_result

    target_engine.Program.Wrappers.core.signal(labels)


def execute(func: str, **kwargs):
    """Calls wrapper functions based on operation code.

    Args:
        func: The stack string that will be resolved into a wrapper function.

    Returns:
        result: Data to be passed from wrapper function to MATLAB.
        result_label: Name data is to be assigned in the MATLAB workspace.
    """

    set_state(state="Running execution manager")
    match func:
        case "zephir_convert":
            result_label, result = zephir.convert(**kwargs)

        case "zephir_recommend_frames":
            result_label, result = zephir.calculate_recommended_frames(**kwargs)

        case "zephir_track":
            result_label, result = zephir.track_neurons(**kwargs)

        case "zephir_extract":
            result_label, result = zephir.extract_activity(**kwargs)

        case _:
            return

    return result_label, result


def main(**kwargs):
    if profile_mode:
        pr.enable()

    set_state(state=f"Loading config")
    config = load_config(kwargs['config'])
    config['is_deployed'] = getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS')
    set_state(state=f"Deployment mode: {config['is_deployed']}")
    config['version'] = 0.1
    config['feed'] = {'state': set_state, 'task': set_task}
    debug(out=config, title='config')

    try:
        results = []
        result_labels = []
        if ',' not in kwargs['operation']:
            result_labels, results = execute(func=kwargs['operation'], **config)
        else:
            operations = kwargs['operation'].split(',')
            for each_operation in operations:
                result_label, result = execute(each_operation, **config)
                result_labels += [result_label]
                results += [result]

        pass_data(result_labels, results)
    except Exception as e:
        debug(e)
        engine.Program.Wrappers.core.signal(e)

    if profile_mode:
        pr.print_stats()
        pr.disable()


args = {}
raw_args = docopt(__doc__, version=f'NPAL Core 0.1')

debug_mode = bool(raw_args['--debug'])
debug("Debug mode enabled...")

profile_mode = bool(raw_args['--profile'])
if profile_mode:
    debug("Profiling mode enabled...")
    pr = cProfile.Profile()

engine, is_hooked = get_engine()

for each_key in raw_args.keys():
    args[each_key.replace('--', '')] = raw_args[each_key]

debug(out=args, title="CLI Arguments")
main(**args)
