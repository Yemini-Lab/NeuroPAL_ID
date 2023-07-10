import os
import sys
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
from datetime import datetime, timedelta
import tifffile
from ndx_multichannel_volume import CElegansSubject, OpticalChannelReferences, OpticalChannelPlus, ImagingVolume, \
    VolumeSegmentation, MultiChannelVolume

full_path = sys.argv[1]


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


def create_file_yemini(folder, reference_frame):
    worm = folder.split('/')[-1]

    path = folder

    matfile = None
    csvfile = None
    gcampfile = None

    print('seeking...')
    for file in os.listdir(path):
        if file == 'head.mat' or file == 'tail.mat':
            print('found mat')
            matfile = path + '/' + file

        elif file == 'head.csv' or file == 'tail.csv':
            print('found csv')
            csvfile = path + '/' + file

        elif file == 'gcamp.mat':
            print('found gcamp')
            gcampfile = path + '/' + file

    if not csvfile:
        return

        # data = np.transpose(skio.imread(imfile), (1,0,2,3)) #data should be XYZC
    # data = data.astype('uint16')
    mat = sio.loadmat(matfile)
    gcamp = sio.loadmat(gcampfile)

    data = np.transpose(mat['data'] * 4095, (1, 0, 2, 3))

    gcdata = gcamp['data']

    gcdata = np.transpose(gcdata, (3, 1, 0, 2))  # convert data to TXYZ

    scale = np.asarray(mat['info']['scale'][0][0]).flatten()
    prefs = np.asarray(mat['prefs']['RGBW'][0][0]).flatten() - 1  # subtract 1 to adjust for matlab indexing from 1

    gcscale = np.asarray(gcamp['worm_data']['info'][0][0][0][0][1]).flatten()

    session_start = datetime(int('1990'), int('01'), int('02'), tzinfo=tz.gettz("US/Pacific"))

    nwbfile = gen_file('Worm head', worm, session_start, 'Hobert lab', 'Columbia University',
                       ["NeuroPAL: A Multicolor Atlas for Whole-Brain Neuronal Identification in C. elegans",
                        "Extracting neural signals from semi-immobilized animals with deformable non-negative matrix factorization"])

    nwbfile.subject = CElegansSubject(
        subject_id=worm,
        # age = "T2H30M",
        # growth_stage_time = pd.Timedelta(hours=2, minutes=30).isoformat(),
        date_of_birth=session_start - timedelta(days=2),
        # currently just using the session start time to bypass the requirement for date of birth
        growth_stage='YA',
        # growth_stage_time=pd.Timedelta(hours=2, minutes=30).isoformat(),
        cultivation_temp=20.,
        description=worm,
        species="http://purl.obolibrary.org/obo/NCBITaxon_6239",
        sex="O",  # currently just using O for other until support added for other gender specifications
        strain="OH16230"
    )

    device = nwbfile.create_device(
        name="Spinning disk confocal",
        description="Spinning Disk Confocal Nikon	Ti-e 60x Objective, 1.2 NA	Nikon CFI Plan Apochromat VC 60XC WI",
        manufacturer="Nikon"
    )

    if prefs[3] == 4:
        channels = [("mTagBFP2", "Semrock FF01-445/45-25 Brightline", "405-445-45m"),
                    ("CyOFP1", "Semrock FF02-617/73-25 Brightline", "488-610-40m"),
                    ("mNeptune 2.5", "Semrock FF01-731/137-25 Brightline", "561-731-70m"),
                    ("GFP-GCaMP", "Semrock FF02-525/40-25 Brightline", "488-525-25m"),
                    ("Tag RFP-T", "Semrock FF02-617/73-25 Brightline", "561-610-40m")]
    elif prefs[3] == 3:
        channels = [("mTagBFP2", "Semrock FF01-445/45-25 Brightline", "405-445-25m"),
                    ("CyOFP1", "Semrock FF02-617/73-25 Brightline", "488-610-40m"),
                    ("mNeptune 2.5", "Semrock FF01-731/137-25 Brightline", "561-731-70m"),
                    ("Tag RFP-T", "Semrock FF02-617/73-25 Brightline", "561-610-40m"),
                    ("GFP-GCaMP", "Semrock FF02-525/40-25 Brightline", "488-525-25m")]

    ImagingVol, OptChannelRefs, OptChannels = create_im_vol(device, channels, location="head", grid_spacing=scale,
                                                            reference_frame=reference_frame)

    csv = pd.read_csv(csvfile, skiprows=6)

    blobs = csv[['Real X (um)', 'Real Y (um)', 'Real Z (um)', 'User ID']]
    blobs = blobs.rename(columns={'Real X (um)': 'X', 'Real Y (um)': 'Y', 'Real Z (um)': 'Z', 'User ID': 'ID'})
    blobs['X'] = round(blobs['X'].div(scale[0]))
    blobs['Y'] = round(blobs['Y'].div(scale[1]))
    blobs['Z'] = round(blobs['Z'].div(scale[2]))
    blobs = blobs.astype({'X': 'int16', 'Y': 'int16', 'Z': 'int16'})

    vs = create_vol_seg(ImagingVol, blobs)

    image = create_image(data, 'NeuroPALImageRaw', worm, ImagingVol, OptChannelRefs, resolution=scale,
                         RGBW_channels=prefs)

    nwbfile.add_acquisition(image)

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
        location='head',
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

    neuroPAL_module = nwbfile.create_processing_module(
        name='NeuroPAL',
        description='neuroPAL image data and metadata',
    )

    neuroPAL_module.add(vs)
    neuroPAL_module.add(ImagingVol)
    neuroPAL_module.add(OptChannelRefs)
    neuroPAL_module.add(OptChannels)

    # gcamp_module = nwbfile.create_processing_module(
    #    name = 'GCaMP',
    #    description = 'GCaMP time series data and metadata'
    # )
    # gcamp_module.add(gcplane)
    # gcamp_module.add(gcchan)

    text = worm + f"\{reference_frame.replace(' ', '-')}.nwb"
    print(f"saving to {text}")
    io = NWBHDF5IO(worm + f"\{reference_frame.replace(' ', '-')}.nwb", mode='w')
    io.write(nwbfile)
    io.close()
    print('saved')


create_file_yemini(full_path, reference_frame='worm head')
