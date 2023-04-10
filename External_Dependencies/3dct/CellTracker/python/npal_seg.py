import os
import cv2
import sys
import csv
import math
import itertools
import numpy as np
from PIL import Image
import tensorflow.keras as keras
import skimage.morphology as morphology
import scipy.ndimage.measurements as snm
from tensorflow.keras.models import Model
from skimage.feature import peak_local_max
from tensorflow.keras.models import load_model
from tensorflow.keras.layers import Conv3D, Input
from skimage.morphology import remove_small_objects
from scipy.ndimage import filters, distance_transform_edt
from skimage.segmentation import find_boundaries, watershed
from skimage.segmentation import relabel_sequential, find_boundaries

dirname = Path(sys.argv[1])
seg_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(dirname))))), 'seg_data')
data_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(dirname))))), 'seg_data', 'data')
model_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(dirname))))), 'seg_data', 'models', 'unet')
weight_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(dirname))))), 'seg_data', 'models', 'unet-weights')

z_siz = len([f for f in os.listdir(data_path) if os.path.isfile(os.path.join(data_path, f))])
cell_num = 0
min_size = float(sys.argv[2])
z_xy_ratio = float(sys.argv[3])
noise_level = float(sys.argv[4])
shrink = (24, 24, 2)

unet_model = load_model(model_path)
unet_model.save_weights(weight_path)
unet_model.load_weights(weight_path)

class SegResults:
    """
    Class to store the segmentation result.

    Attributes
    ----------
    image_cell_bg : numpy.ndarray
        The cell/non-cell predictions by 3D U-Net
    l_center_coordinates : list of tuple
        The detected centers coordinates of the cells, using voxels as the unit
    segmentation_auto : numpy.ndarray
        The individual cells predicted by 3D U-Net + watershed
    image_gcn : numpy.ndarray
        The raw image divided by 65535
    r_coordinates_segment : numpy.ndarray
        Transformed from l_center_coordinates, with the z coordinates corrected by the resolution relative to x-y plane
    """

    def __init__(self):
        self.image_cell_bg = None
        self.l_center_coordinates = None
        self.segmentation_auto = None
        self.image_gcn = None
        self.r_coordinates_segment = None

    def update_results(self, image_cell_bg, l_center_coordinates, segmentation_auto,
                       image_gcn, r_coordinates_segment):
        """Update the attributes of a SegResults instance"""
        self.image_cell_bg = image_cell_bg
        self.l_center_coordinates = l_center_coordinates
        self.segmentation_auto = segmentation_auto
        self.image_gcn = image_gcn
        self.r_coordinates_segment = r_coordinates_segment

def read_image_ts(vol, path, name, z_range, print_=False):
    """
    Read a 3D image at time vol

    Parameters
    ----------
    vol : int
        A specific volume
    path : str
        Folder path
    name : str
        File name
    z_range : tuple
        Range of layers
    print_ : bool
        Whether print the image shape or not

    Returns
    -------
    img_array : numpy.ndarray
        An array of the image with shape (row, column, layer)
    """
    image_raw = []
    for z in range(z_range[0], z_range[1]):
        image_raw.append(cv2.imread(f"{path}/npal_worm_c1_{z}.tif"))

    img_array = np.array(image_raw)
    img_array = img_array[:, :, :, :-2]
    img_array = np.squeeze(img_array)
    img_array = img_array.transpose((1, 2, 0))
    if print_:
        print("Load images with shape:", img_array.shape)
    return img_array

def _watershed(image_cell_bg, method, min_size, cell_num):
    """
    Segment the cell regions by watershed method
    """
    image_watershed2d_wo_border, _ = watershed_2d(image_cell_bg[0, :, :, :, 0], z_range=z_siz,
                                                  min_distance=7)
    _, image_watershed3d_wi_border, min_size, cell_num = watershed_3d(
        image_watershed2d_wo_border, samplingrate=[1, 1, z_xy_ratio], method=method,
        min_size=min_size, cell_num=cell_num, min_distance=3)
    segmentation_auto, fw, inv = relabel_sequential(image_watershed3d_wi_border)
    min_size = min_size
    if method == "min_size":
        cell_num = cell_num
    return segmentation_auto

def _normalize_image(image, noise_level):
    """
    Normalize an 3D image by local contrast normalization

    Parameters
    ----------
    image : numpy.ndarray
        A 3D image to be normalized
    noise_level : float
        The parameter to suppress the enhancement of the background noises

    Returns
    -------
    numpy.ndarray
        The normalized image
    """
    image_norm = image - np.median(image)
    image_norm[image_norm < 0] = 0
    return lcn_gpu(image_norm, noise_level, filter_size=(27, 27, 1))

def lcn_gpu(img3d, noise_level=5, filter_size=(27, 27, 1)):
    """
    Local contrast normalization by gpu

    Parameters
    ----------
    img3d : numpy.ndarray
        The raw 3D image
    noise_level : float
        The parameter to suppress the enhancement of the background noises
    filter_size : tuple, optional
        the window size to apply the normalization along x, y, and z axis. Default: (27, 27, 1)

    Returns
    -------
    norm : numpy.ndarray
        The normalized 3D image

    Notes
    -----
    The normalization in the edge regions currently used zero padding based on keras.Conv3D function,
    which is different with the lcn_cpu function (uses "reflect" padding).
    """
    img3d_siz = img3d.shape
    volume = filter_size[0] * filter_size[1] * filter_size[2]
    conv3d_model = conv3d_keras(filter_size, img3d_siz)
    img3d = np.expand_dims(img3d, axis=(0,4))
    avg = conv3d_model.predict(img3d) / volume
    diff_sqr = np.square(img3d - avg)
    std = np.sqrt(conv3d_model.predict(diff_sqr) / volume)
    norm = np.divide(img3d - avg, std + noise_level)
    return norm[0, :, :, :, 0]

def conv3d_keras(filter_size, img3d_siz):
    """
    Generate a keras model for applying 3D convolution

    Parameters
    ----------
    filter_size : tuple
    img3d_siz : tuple

    Returns
    -------
    keras.Model
        The keras model to apply 3D convolution
    """
    inputs = Input((img3d_siz[0], img3d_siz[1], img3d_siz[2], 1))
    conv_3d = Conv3D(1, filter_size, kernel_initializer=keras.initializers.Ones(), padding='same')(inputs)
    return Model(inputs=inputs, outputs=conv_3d)

def watershed_2d(image_pred, z_range=21, min_distance=7):
    """
    Segment cells in each layer of the 3D image by 2D _watershed

    Parameters
    ----------
    image_pred :
        the binary image of cell region and background (predicted by 3D U-net)
    z_range :
        number of layers
    min_distance :
        the minimum cell distance allowed in the result

    Returns
    -------
    bn_output :
        binary image (cell/bg) removing boundaries detected by _watershed
    boundary :
        image of cell boundaries
    """
    boundary = np.zeros(image_pred.shape, dtype='bool')
    for z in range(z_range):
        bn_image = image_pred[:, :, z] > 0.5
        dist = distance_transform_edt(bn_image, sampling=[1, 1])
        dist_smooth = filters.gaussian_filter(dist, 2, mode='constant')

        local_maxi = peak_local_max(dist_smooth, min_distance=min_distance, indices=False)
        markers = morphology.label(local_maxi)
        labels_ws = watershed(-dist_smooth, markers, mask=bn_image)
        labels_bd = find_boundaries(labels_ws, connectivity=2, mode='outer', background=0)

        boundary[:, :, z] = labels_bd

    bn_output = image_pred > 0.5
    bn_output[boundary == 1] = 0

    return bn_output, boundary

def watershed_3d(image_watershed2d, samplingrate, method, min_size, cell_num, min_distance):
    dist = distance_transform_edt(image_watershed2d, sampling=samplingrate)
    dist_smooth = filters.gaussian_filter(dist, (2, 2, 0.3), mode='constant')
    local_maxi = peak_local_max(dist_smooth, min_distance=min_distance, exclude_border=0, indices=False)
    markers = morphology.label(local_maxi)
    labels_ws = watershed(-dist_smooth, markers, mask=image_watershed2d)
    if method == "min_size":
        cell_num = np.sum(np.sort(np.bincount(labels_ws.ravel())) >= min_size) - 1
    elif method == "cell_num":
        min_size = np.sort(np.bincount(labels_ws.ravel()))[-cell_num - 1]
    else:
        raise ("The method parameter should be either min_size or cell_num")
    labels_clear = remove_small_objects(labels_ws, min_size=min_size, connectivity=3)

    labels_bd = find_boundaries(labels_clear, connectivity=3, mode='outer', background=0)
    labels_wo_bd = labels_clear.copy()
    labels_wo_bd[labels_bd == 1] = 0
    labels_wo_bd = remove_small_objects(labels_wo_bd, min_size=min_size, connectivity=3)

    return labels_wo_bd, labels_clear, min_size, cell_num

def _get_sizes_padded_im(img_siz_i, out_centr_siz_i):
    """
    Calculate the sizes and number of subregions to prepare the padded sub_images

    Parameters
    ----------
    img_siz_i : int
        Size of raw sub_images along axis i
    out_centr_siz_i : int
        Size of the center of the prediction by unet, along axis i

    Returns
    -------
    temp_siz_i : int
        Size of the padded sub_images along axis i
    num_axis_i : int
        Number of the subregions (as inputs for unet) along axis i
    """
    num_axis_i = int(math.ceil(img_siz_i * 1.0 / out_centr_siz_i))
    temp_siz_i = num_axis_i * out_centr_siz_i
    return temp_siz_i, num_axis_i

def unet3_prediction(img, model, shrink=(24, 24, 2)):
    """
    Predict cell/non-cell regions by applying 3D U-net on each sub-sub_images.

    Parameters
    ----------
    img : numpy.ndarray
        Shape: (sample, x, y, z, channel), the normalized images to be segmented.
    model : keras.Model
        The pre-trained 3D U-Net model.
    shrink : tuple
        The surrounding voxels to make pad. It is also used to discard surrounding regions of each predicted sub-region.

    Returns
    -------
    out_img : numpy.ndarray
        Predicted cell regions, shape: (sample, x, y, z, channel)
    """
    out_centr_siz1 = model.output_shape[1] - shrink[0] * 2  # size of the center part of the prediciton by unet
    out_centr_siz2 = model.output_shape[2] - shrink[1] * 2
    out_centr_siz3 = model.output_shape[3] - shrink[2] * 2

    x_siz, y_siz, z_siz = img.shape[1:4]  # size of the input sub_images

    _x_siz, _num_x = _get_sizes_padded_im(x_siz,
                                          out_centr_siz1)  # size of the expanded sub_images and number of subregions
    _y_siz, _num_y = _get_sizes_padded_im(y_siz, out_centr_siz2)
    _z_siz, _num_z = _get_sizes_padded_im(z_siz, out_centr_siz3)

    before1, before2, before3 = shrink  # "pad_width" for numpy.pad()
    after1, after2, after3 = before1 + (_x_siz - x_siz), before2 + (_y_siz - y_siz), before3 + (_z_siz - z_siz)

    img_padded = np.pad(img[0, :, :, :, 0], ((before1, after1), (before2, after2), (before3, after3)), 'reflect')
    img_padded = np.expand_dims(img_padded, axis=(0, 4))

    slice_prediction_center = np.s_[0, before1: before1 + out_centr_siz1,
                              before2: before2 + out_centr_siz2,
                              before3: before3 + out_centr_siz3, 0]

    unet_siz1, unet_siz2, unet_siz3 = model.input_shape[1:4]  # size of the input for the unet model

    # the expanded sub_images was predicted on each sub-sub_images
    expanded_img = np.zeros((1, _x_siz, _y_siz, _z_siz, 1), dtype='float32')
    for i, j, k in itertools.product(range(_num_x), range(_num_y), range(_num_z)):
        slice_prediction = np.s_[:, i * out_centr_siz1: i * out_centr_siz1 + unet_siz1,
                           j * out_centr_siz2: j * out_centr_siz2 + unet_siz2,
                           k * out_centr_siz3: k * out_centr_siz3 + unet_siz3, :]
        slice_write = np.s_[0, i * out_centr_siz1: (i + 1) * out_centr_siz1,
                      j * out_centr_siz2: (j + 1) * out_centr_siz2,
                      k * out_centr_siz3: (k + 1) * out_centr_siz3, 0]
        prediction_subregion = model.predict(img_padded[slice_prediction])
        expanded_img[slice_write] = prediction_subregion[slice_prediction_center]
    out_img = expanded_img[:, 0:x_siz, 0:y_siz, 0:z_siz, :]
    return out_img

def save_img3(z_siz, img, path, use_8_bit: bool):
    """
    Save a 3D image (at t=1) as 2D image sequence

    Parameters
    ----------
    z_siz : int
        The layer number of the 3D image
    img : numpy.ndarray
        The 3D image to be saved. Shape: (row, column, layer)
    path : str
        The path of the image files to be saved.
        It should use formatted string to indicate volume number and then layer number, e.g. "xxx_t%04d_z%04i.tif"
    use_8_bit: bool
        The array will be transformed to 8-bit or 16-bit before saving as image.
    """
    dtype = np.uint8 if use_8_bit else np.uint16
    for z in range(0, z_siz):
        img2d = img[:, :, z - 1].astype(dtype)
        Image.fromarray(img2d).save(path % (1, z))

segresult = SegResults()

for file in os.listdir(seg_path):
    if file.endswith(".tif"):
        os.replace(os.path.join(seg_path,file), os.path.join(data_path,file))

image_raw = read_image_ts(1, data_path, 'npal_worm_c1_%i.tif', (0, z_siz), print_=False)

# image_gcn will be used to correct tracking results
image_gcn = (image_raw.copy() / 65536.0)

# pre-processing: local contrast normalization
image_norm = np.expand_dims(_normalize_image(image_raw, noise_level), axis=(0, 4))

# predict cell-like regions using 3D U-net
image_cell_bg = unet3_prediction(image_norm, unet_model, shrink=shrink)

if np.max(image_cell_bg) <= 0.5:
    raise ValueError("No cell was detected by 3D U-Net! Try to reduce the noise_level.")

# segment connected cell-like regions using _watershed
segmentation_auto = _watershed(image_cell_bg, 'min_size', min_size, cell_num)
if np.max(segmentation_auto) == 0:
    raise ValueError("No cell was detected by watershed! Try to reduce the min_size.")

# calculate coordinates of the centers of each segmented cell
l_center_coordinates = snm.center_of_mass(segmentation_auto > 0, segmentation_auto,
                                          range(1, segmentation_auto.max() + 1))

# Transform the coordinates with different units along z
new_disp = np.array(l_center_coordinates).copy()
new_disp[:, 2] = new_disp[:, 2] * z_xy_ratio
r_coordinates_segment = new_disp

segresult.update_results(image_cell_bg, l_center_coordinates, segmentation_auto, image_gcn, r_coordinates_segment)
r_coordinates_segment_t0 = segresult.r_coordinates_segment.copy()

# Assuming the desired filename is "neuron_info.csv"
filename = os.path.join(seg_path, "neuron_info.csv")

# Open the file for writing
with open(filename, 'w', newline='') as csvfile:

    # Create the csv writer object
    writer = csv.writer(csvfile)

    # Loop through the neuron_info list and write each row to the csv file
    for x, y, z in l_center_coordinates:
        writer.writerow([round(x, 2), round(y, 2), round(z, 2)])

# save the segmented cells of volume #1
save_img3(z_siz=z_siz, img=segresult.segmentation_auto,
          path=os.path.join(seg_path,'auto_vol1','auto_t%i_z%i.tif'), use_8_bit=True)
