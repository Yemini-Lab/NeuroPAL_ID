# Import ZephIR package
from zephir.main import *
import sys
from subprocess import check_output

# ZephIR is mostly run with terminal commands
# Subprocess library will be used to emulate this
import subprocess

# Define path to dataset directory
dataset = Path(sys.argv[1])
routine = sys.argv[2]

if routine == 'recommend_frames':
    # Determine the best frames to annotate as reference frames
    output = subprocess.run(f'recommend_frames --dataset={dataset} --channel=1', shell=True)
elif routine == 'annotator':
    # Launch annotator to create annotations for reference frames
    # Run this cell then open in a web browser: localhost:5001
    output = subprocess.Popen(f'annotator --dataset={dataset} --port=5001', shell=True)
elif routine == 'tracker':
    # Launch ZephIR to track keypoints as defined in fully-annotated reference frames
    # User-tunable options are defined in the included args.json file

    # Non-default arguments include:
    # channel=1
    # fovea_sigma=5.0
    # grid_shape=35
    # lambda_n=0.1
    # lr_ceiling=0.06
    # lr_floor=0.01
    # z_compensator=4.0

    output = subprocess.run(f'zephir --dataset={dataset} --load_args=True', shell=True)
elif routine == 'tracer':
    # Launch trace extraction to extract fluorescence intensity using tracked centers
    output = subprocess.run(f'extract_traces --dataset={dataset} --channel=1', shell=True)
else:
    print(f'Invalid routine request: {routine}.')
