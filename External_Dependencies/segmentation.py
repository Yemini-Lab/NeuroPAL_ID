import os
import sys

# Data Paths
seg_path = Path(sys.argv[1])
data_path = os.path.join(seg_path, "data")
model_path = os.path.join(seg_path, "models", "unet")
weight_path = os.path.join(seg_path, "models", "unet-weights")

# Model Paths
model_selector = os.path.join('.', 'model-selector', 'zephod', 'main.py')
cell_tracker = os.path.join('.', '3dct', 'CellTracker', 'python', 'npal_seg.py')

# Volume Information
cell_num = 0
min_size = float(sys.argv[2])
max_size = float(sys.argv[5])

z_xy_ratio = float(sys.argv[3])
noise_level = float(sys.argv[4])
shrink = (24, 24, 2)

z_siz = len(
    [f for f in os.listdir(data_path) if os.path.isfile(os.path.join(data_path, f))]
)

#
