import os
import sys
import h5py
import re
from pynwb import load_namespaces, get_class
from pynwb.file import MultiContainerInterface, NWBContainer
import skimage.io as skio
from collections.abc import Iterable
import numpy as np
from pynwb import register_class
from hdmf.utils import docval, get_docval, popargs
from pynwb.ophys import ImageSeries
from pynwb.core import NWBDataInterface
from hdmf.common import DynamicTable
from hdmf.utils import docval, popargs, get_docval, get_data_shape, popargs_to_dict
from pynwb.file import Device
import pandas as pd
import numpy as np
from pynwb import NWBFile, TimeSeries, NWBHDF5IO
from pynwb.epoch import TimeIntervals
from pynwb.file import Subject
from pynwb.behavior import SpatialSeries, Position
from pynwb.image import ImageSeries
from pynwb.ophys import OnePhotonSeries, OpticalChannel, ImageSegmentation, Fluorescence, CorrectedImageStack, \
    MotionCorrection, RoiResponseSeries, ImagingPlane
from datetime import datetime
from datetime import timedelta
from dateutil import tz
import pandas as pd
import scipy.io as sio
from datetime import date, timedelta
import tifffile
import argparse
from ndx_multichannel_volume import CElegansSubject, OpticalChannelReferences, OpticalChannelPlus, ImagingVolume, \
    VolumeSegmentation, MultiChannelVolume


parser = argparse.ArgumentParser(description='NeuroPAL_ID\'s built-in NWB converter.')
parser.add_argument('--OpenDandi', type=str, default='null', help='Open Dandi page after converting?')
parser.add_argument('--author', type=str, default='null', help='Author name')
parser.add_argument('--institution', type=str, default='null', help='Institutional affiliation')
parser.add_argument('--description', type=str, default='null', help='Description')
parser.add_argument('--related_pubs', type=str, default='null', help='Related Publications')
parser.add_argument('--image_path', type=str, required=True, help='Image path')
parser.add_argument('--mat_file', type=str, required=True, help='MAT file path')
parser.add_argument('--id_bool', type=str, default='null', help='ID Boolean')
parser.add_argument('--csv_bool', type=str, default='null', help='CSV Boolean')
parser.add_argument('--gcamp_bool', type=str, default='null', help='GCAMP Boolean')
parser.add_argument('--annotation_bool', type=str, default='null', help='Annotation Boolean')
parser.add_argument('--segmentation_bool', type=str, default='null', help='Segmentation Boolean')
parser.add_argument('--proceed', type=int, default=0, help='Proceed')
parser.add_argument('--activity_bool', type=str, default='null', help='Activity Boolean')
parser.add_argument('--device_name', type=str, default='null', help='Device Name')
parser.add_argument('--manufacturer', type=str, default='null', help='Manufacturer')
parser.add_argument('--device_channels', type=str, default='null', help='Device Channels')
parser.add_argument('--device_description', type=str, default='null', help='Device Description')
parser.add_argument('--filename', type=str, default='null', help='Custom filename')

args = parser.parse_args()

for key, value in vars(args).items():
    if isinstance(value, str) and key not in ["mat_file","image_path"]:
        setattr(args, key, value.replace('_', ' '))

def gen_file(description, identifier, start_date_time, lab, institution, pubs):
    nwbfile = NWBFile(
        session_description=description,
        identifier=identifier,
        session_start_time=start_date_time,
        lab=lab,
        institution=institution,
        related_publications=pubs
    )

    return nwbfile


def create_im_vol(device, channels, location="head", grid_spacing=[0.3208, 0.3208, 0.75],
                  grid_spacing_unit="micrometers", origin_coords=[0, 0, 0], origin_coords_unit="micrometers",
                  reference_frame="Worm head"):
    # channels should be ordered list of tuples (name, description)

    OptChannels = []
    OptChanRefData = []
    for name, des, wave in channels:
        excite = float(wave.split('-')[0])
        emiss_mid = float(wave.split('-')[1])
        emiss_range = float(wave.split('-')[2][:-1])
        OptChan = OpticalChannelPlus(
            name=name,
            description=des,
            excitation_lambda=excite,
            excitation_range=[excite - 1.5, excite + 1.5],
            emission_range=[emiss_mid - emiss_range / 2, emiss_mid + emiss_range / 2],
            emission_lambda=emiss_mid
        )

        OptChannels.append(OptChan)
        OptChanRefData.append(wave)

    OpticalChannelRefs = OpticalChannelReferences(
        name='OpticalChannelRefs',
        channels=OptChanRefData
    )

    imaging_vol = ImagingVolume(
        name='ImagingVolume',
        optical_channel_plus=OptChannels,
        Order_optical_channels=OpticalChannelRefs,
        description='NeuroPAL image of C elegan brain',
        device=device,
        location=location,
        grid_spacing=grid_spacing,
        grid_spacing_unit=grid_spacing_unit,
        origin_coords=origin_coords,
        origin_coords_unit=origin_coords_unit,
        reference_frame=reference_frame
    )

    return imaging_vol, OpticalChannelRefs, OptChannels


def create_vol_seg(imaging_vol, blobs):
    vs = VolumeSegmentation(
        name='VolumeSegmentation',
        description='Neuron centers for multichannel volumetric image',
        imaging_volume=imaging_vol
    )

    voxel_mask = []

    for i, row in blobs.iterrows():
        x = row['X']
        y = row['Y']
        z = row['Z']
        ID = row['ID']

        voxel_mask.append([np.uint(x), np.uint(y), np.uint(z), 1, str(ID)])

    vs.add_roi(voxel_mask=voxel_mask)

    return vs


def create_image(data, name, description, imaging_volume, opt_chan_refs, resolution=[0.3208, 0.3208, 0.75],
                 RGBW_channels=[0, 1, 2, 3]):
    image = MultiChannelVolume(
        name=name,
        Order_optical_channels=opt_chan_refs,
        resolution=resolution,
        description=description,
        RGBW_channels=RGBW_channels,
        data=data,
        imaging_volume=imaging_volume
    )

    return image


'''
Create NWB file from tif file of raw image, neuroPAL software created mat file and csv files of blob locations
'''


def create_file_FOCO(folder, reference_frame):
    worm = folder.split('/')[-1]

    path = folder

    for file in os.listdir(path):
        if file[-4:] == '.tif':
            imfile = path + '/' + file

        elif file[-4:] == '.mat' and file[-6:] != 'ID.mat':
            matfile = path + '/' + file

        elif file == 'blobs.csv':
            blobs = path + '/' + file

    data = np.transpose(skio.imread(imfile))  # data in XYZC
    # data = data.astype('uint16')
    mat = sio.loadmat(matfile)

    scale = np.asarray(mat['info']['scale'][0][0]).flatten()
    prefs = np.asarray(mat['prefs']['RGBW'][0][0]).flatten() - 1  # subtract 1 to adjust for matlab indexing from 1

    dt = worm.split('-')
    session_start = datetime(int(dt[0]), int(dt[1]), int(dt[2]), tzinfo=tz.gettz("US/Pacific"))

    nwbfile = gen_file('Worm head', worm, session_start, 'Kato lab', 'UCSF', "")

    nwbfile.subject = CElegansSubject(
        subject_id=worm,
        # age = "T2H30M",
        # growth_stage_time = pd.Timedelta(hours=2, minutes=30).isoformat(),
        date_of_birth=session_start,
        # currently just using the session start time to bypass the requirement for date of birth
        growth_stage='YA',
        growth_stage_time=pd.Timedelta(hours=2, minutes=30).isoformat(),
        cultivation_temp=20.,
        description=dt[3] + '-' + dt[4],
        species="http://purl.obolibrary.org/obo/NCBITaxon_6239",
        sex="O",  # currently just using O for other until support added for other gender specifications
        strain="OH16230"
    )

    device = nwbfile.create_device(
        name="Microscope",
        description="One-photon microscope Weill",
        manufacturer="Leica"
    )

    channels = [("mNeptune 2.5", "Chroma ET 700/75", "561-700-75m"), ("Tag RFP-T", "Chroma ET 605/70", "561-605-70m"),
                ("CyOFP1", "Chroma ET 605/70", "488-605-70m"), ("GFP-GCaMP", "Chroma ET 525/50", "488-525-50m"),
                ("mTagBFP2", "Chroma ET 460/50", "405-460-50m"),
                ("mNeptune 2.5-far red", "Chroma ET 700/75", "639-700-75m")]

    ImagingVol, OptChannelRefs, OptChannels = create_im_vol(device, channels, location="head", grid_spacing=scale,
                                                            reference_frame=reference_frame)

    csv = pd.read_csv(blobs)

    vs = create_vol_seg(ImagingVol, csv)

    image = create_image(data, 'NeuroPALImageRaw', worm, ImagingVol, OptChannelRefs, resolution=scale,
                         RGBW_channels=[0, 2, 4, 1])

    nwbfile.add_acquisition(image)

    neuroPAL_module = nwbfile.create_processing_module(
        name='NeuroPAL',
        description='neuroPAL image data and metadata',
    )

    processed_im_module = nwbfile.create_processing_module(
        name='ProcessedImage',
        description='Pre-processed image. Currently median filtered and histogram matched to original neuroPAL images.'
    )

    proc_imvol, proc_optchanrefs, proc_optchanplus = create_im_vol(device, [channels[i] for i in [0, 2, 4, 1]],
                                                                   location="head", grid_spacing=scale,
                                                                   reference_frame=reference_frame)

    proc_imfile = datapath + '/NP_FOCO_hist_med/' + worm + '/hist_med_image.tif'

    proc_data = np.transpose(skio.imread(proc_imfile), (2, 1, 0, 3))
    # proc_data = proc_data.astype('uint16')

    proc_image = create_image(proc_data, 'Hist_match_med_filt', worm, proc_imvol, proc_optchanrefs, resolution=scale,
                              RGBW_channels=[0, 1, 2, 3])

    neuroPAL_module.add(vs)
    neuroPAL_module.add(ImagingVol)
    neuroPAL_module.add(OptChannelRefs)
    neuroPAL_module.add(OptChannels)

    processed_im_module.add(proc_image)
    processed_im_module.add(proc_optchanrefs)
    processed_im_module.add(proc_optchanplus)
    processed_im_module.add(proc_imvol)

    io = NWBHDF5IO(datapath + '/nwb/' + worm + '.nwb', mode='w')
    io.write(nwbfile)
    io.close()


def extract_data(mat, index):
    try:
        return mat['worm'][0][0][index][0]
    except:
        return 'N/A'


def create_file_yemini():
    # Leverage arguments to extract data.
    worm = args.image_path.split('/')[-1]
    path = args.image_path

    if args.csv_bool != 'False':
        csvfile = args.csv_bool
    if args.gcamp_bool != 'False':
        gcampfile = args.gcamp_bool
    if args.activity_bool != 'False':
        zephirfile = args.activity_bool
    if args.segmentation_bool != 'False':
        segmentationpath = args.segmentation_bool

    # Populate master dictionary with metadata pulled from .mat
    mat = sio.loadmat(args.mat_file)
    master_dict = {
        'name': re.search(r'\b\d{8}\b', args.mat_file).group(),
        'path': args.mat_file,
        'info': {
            'author': {
                'lab': args.author.replace('_', ' '),
                'institution': args.institution.replace('_', ' '),
                'description': args.description.replace('_', ' '),
                'related_pubs': args.related_pubs.replace('_', ' '),
            },
            'region': extract_data(mat, 0),
            'age': extract_data(mat, 1),
            'sex': extract_data(mat, 2),
            'strain': extract_data(mat, 3),
            'notes': extract_data(mat, 4),
            'scale': np.asarray(mat['info']['scale'][0][0]).flatten(),
            'prefs': np.asarray(mat['prefs']['RGBW'][0][0]).flatten() - 1,
            # subtract 1 to adjust for matlab indexing from 1
        },
        'data': np.transpose(mat['data'] * 4095, (1, 0, 2, 3)),
    }

    # Try to extract session date.
    match = re.search(r'\b(\d{4})(\d{2})(\d{2})\b', master_dict['path'])
    if match:
        year, month, day = map(int, match.groups())
        date_time_obj = datetime(year, month, day, tzinfo=tz.gettz("US/Pacific"))
        master_dict['info']['session_start_datetime'] = date_time_obj
        date_obj = date(year, month, day)
        master_dict['info']['session_start'] = date_obj
    else:
        master_dict['info']['session_start_datetime'] = 'N/A'
        master_dict['info']['session_start'] = 'N/A'

    reference_frame = f"worm {master_dict['info']['region']}"


    # Generate file.
    nwbfile = gen_file(f'{master_dict["info"]["author"]["description"]}', master_dict["name"],
                       master_dict["info"]["session_start_datetime"], master_dict['info']['author']['lab'],
                       master_dict['info']['author']['institution'], master_dict['info']['author']['related_pubs'])

    # Populate subject data.
    nwbfile.subject = CElegansSubject(
        subject_id=master_dict["name"],
        # age = "T2H30M",
        # growth_stage_time = pd.Timedelta(hours=2, minutes=30).isoformat(),
        # date_of_birth=session_start - timedelta(days=2),
        # currently just using the session start time to bypass the requirement for date of birth
        growth_stage=master_dict["info"]["age"],
        # growth_stage_time=pd.Timedelta(hours=2, minutes=30).isoformat(),
        # cultivation_temp=20.,
        description=master_dict['info']['author']['description'],
        species="http://purl.obolibrary.org/obo/NCBITaxon_6239",
        sex=master_dict["info"]["sex"],
        # currently just using O for other until support added for other gender specifications
        strain=master_dict["info"]["strain"]
    )

    # Populate device data.
    device = nwbfile.create_device(
        name=args.device_name,
        description=args.device_description,
        manufacturer=args.manufacturer
    )

    # Populate imaging data.
    if master_dict["info"]["prefs"][3] == 4:
        channels = [("mTagBFP2", "Semrock FF01-445/45-25 Brightline", "405-445-45m"),
                    ("CyOFP1", "Semrock FF02-617/73-25 Brightline", "488-610-40m"),
                    ("mNeptune 2.5", "Semrock FF01-731/137-25 Brightline", "561-731-70m"),
                    ("GFP-GCaMP", "Semrock FF02-525/40-25 Brightline", "488-525-25m"),
                    ("Tag RFP-T", "Semrock FF02-617/73-25 Brightline", "561-610-40m")]
    elif master_dict["info"]["prefs"][3] == 3:
        channels = [("mTagBFP2", "Semrock FF01-445/45-25 Brightline", "405-445-25m"),
                    ("CyOFP1", "Semrock FF02-617/73-25 Brightline", "488-610-40m"),
                    ("mNeptune 2.5", "Semrock FF01-731/137-25 Brightline", "561-731-70m"),
                    ("Tag RFP-T", "Semrock FF02-617/73-25 Brightline", "561-610-40m"),
                    ("GFP-GCaMP", "Semrock FF02-525/40-25 Brightline", "488-525-25m")]

    ImagingVol, OptChannelRefs, OptChannels = create_im_vol(device, channels, location=master_dict["info"]["region"],
                                                            grid_spacing=master_dict["info"]["scale"],
                                                            reference_frame=reference_frame)

    image = create_image(master_dict["data"], 'NeuroPALImageRaw', master_dict["name"], ImagingVol, OptChannelRefs,
                         resolution=master_dict["info"]["scale"],
                         RGBW_channels=master_dict["info"]["prefs"])

    nwbfile.add_acquisition(image)

    neuroPAL_module = nwbfile.create_processing_module(
        name='NeuroPAL',
        description='neuroPAL image data and metadata',
    )
    neuroPAL_module.add(ImagingVol)
    neuroPAL_module.add(OptChannelRefs)
    neuroPAL_module.add(OptChannels)

    # Check for CSV file, populate if detected.
    if args.csv_bool != 'False':
        csvfile = args.csv_bool
        csv = pd.read_csv(csvfile, skiprows=6)

        blobs = csv[['Real X (um)', 'Real Y (um)', 'Real Z (um)', 'User ID']]
        blobs = blobs.rename(columns={'Real X (um)': 'X', 'Real Y (um)': 'Y', 'Real Z (um)': 'Z', 'User ID': 'ID'})
        blobs['X'] = round(blobs['X'].div(master_dict["info"]["scale"][0]))
        blobs['Y'] = round(blobs['Y'].div(master_dict["info"]["scale"][1]))
        blobs['Z'] = round(blobs['Z'].div(master_dict["info"]["scale"][2]))
        blobs = blobs.astype({'X': 'int16', 'Y': 'int16', 'Z': 'int16'})

        vs = create_vol_seg(ImagingVol, blobs)
        neuroPAL_module.add(vs)

    # Check for GCaMP video, populate if detected.
    if args.gcamp_bool != 'False':
        gcampfile = args.gcamp_bool
        gcamp = sio.loadmat(gcampfile)

        try:
            gcdata = gcamp['data']
        except:
            gcdata = gcamp['gcamp']

        gcdata = np.transpose(gcdata, (3, 1, 0, 2))  # convert data to TXYZ

        try:
            gcscale = np.asarray(gcamp['worm_data']['info'][0][0][0][0][1]).flatten()
        except:
            gcscale = []

        gc_optchan = ("GFP-GCaMP", "Semrock FF02-525/40-25 Brightline", "488-525-25m")

        excite = float(gc_optchan[2].split('-')[0])
        emiss_mid = float(gc_optchan[2].split('-')[1])
        emiss_range = float(gc_optchan[2].split('-')[2][:-1])

        gcchan = OpticalChannel(
            name=gc_optchan[0],
            description="Semrock FF02-525/40-25 Brightline",
            emission_lambda=emiss_mid
        )

        gcplane = nwbfile.create_imaging_plane(
            name='GCamp_implane',
            description='Imaging plane for GCamp data acquisition',
            excitation_lambda=float(gc_optchan[2].split('-')[0]),
            optical_channel=gcchan,
            location=master_dict["info"]["region"],
            indicator='GFP',
            device=device,
            grid_spacing=gcscale,
            grid_spacing_unit='um'
        )

        gcamp = OnePhotonSeries(
            name='GCaMP_series',
            description='Time Series GCaMP activity data',
            data=gcdata,
            unit='grey count values from 0-255',
            resolution=1.0,
            rate=4.0,
            imaging_plane=gcplane,
        )

        nwbfile.add_acquisition(gcamp)

        gcamp_module = nwbfile.create_processing_module(
            name='GCaMP',
            description='GCaMP time series data and metadata'
        )
        gcamp_module.add(gcplane)
        gcamp_module.add(gcchan)

    # Check for activity data, populate if detected.
    if args.activity_bool != 'False':
        activityfile = args.activity_bool

        df = pd.read_csv(activityfile)
        df = df.T

        print(df)

        zephir = RoiResponseSeries(
            name='ZephIR_tracing',
            description='Positional ROIs for traced neurons.',
            unit='pixels',
            rois=zeph5['x', 'y', 'z'],
            control=zeph5['worldline_id'],
            timestamps=zeph5['t_idx'],
            data=activity_frame
        )

    # Check for annotation file, populate if detected.
    if args.annotation_bool != 'False':
        zephirfile = args.annotation_bool

        # Open the h5 file
        file = h5py.File(zephirfile, 'r')

        # Convert to pandas DataFrame
        data = {}
        for key in file.keys():
            data[key] = file[key][...]

        zeph5 = pd.DataFrame(data)
        activity_frame = pd.DataFrame(columns=['worldline_id', 'activity'])

        for index, row in zeph5.iterrows():
            eachNeuron = row['worldline_id']
            neuron_activity = []

            for eachTimestamp in zeph5['t_idx']:
                pos_x = row['x']
                pos_y = row['y']
                pos_z = row['z']
                neuron_activity.append(gcdata[eachTimestamp, pos_x, pos_y, pos_z])

            activity_frame.loc[eachNeuron] = [eachNeuron, neuron_activity]

        # Don't forget to close the file
        file.close()

        keypoints = SpatialSeries(
            name='zephir-keypoints',
            description='Positional ROIs for traced neurons.',
            unit='pixels',
            reference_frame='t=0',
            timestamps=zeph5['t_idx'],
            data=activity_frame,
            control=zeph5['worldline_id'],
            control_description='Neuron names'
        )

        zephir = Position(
            spatial_series=keypoints,
            name='ZephIR positioning'
        )

        zephir_module = nwbfile.create_processing_module(
            name='ZephIR output',
            description='neuroPAL image data and metadata',
        )

        zephir_module.add(zephir)

    text = f"{master_dict['name'].replace(' ', '-')}-{master_dict['info']['session_start']}.nwb"

    io = NWBHDF5IO(worm + f"{master_dict['name'].replace(' ', '-')}-{master_dict['info']['session_start']}.nwb",
                   mode='w')
    io.write(nwbfile)
    io.close()


create_file_yemini()
