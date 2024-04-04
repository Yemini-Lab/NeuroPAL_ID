"""
Mat2nwb: NeuroPAL_ID's NWB Conversion Tool

See /docs/Guide-parameters.md for detailed explanations and tips for using optional arguments.

Usage:
    mat2nwb -h | --help
    mat2nwb -v | --version
    mat2nwb --cache=<dataset> [options]
    mat2nwb --cache=<dataset> [options]

Options:
    -h --help                           show this message and exit.
    -v --version                        show version information and exit.
    --cache=<dataset>                   Path to cache .mat containing various arguments collected within NeuroPAL_ID.
"""

import os
import datetime
from pathlib import Path

import h5py
import numpy as np
import pandas as pd
import scipy.io as sio
import skimage.io as skio
from dateutil import tz
from docopt import docopt
from ndx_multichannel_volume import CElegansSubject, OpticalChannelReferences, OpticalChannelPlus, ImagingVolume, \
    VolumeSegmentation, PlaneSegmentation, MultiChannelVolume
from pynwb import NWBFile, NWBHDF5IO
from pynwb.behavior import SpatialSeries, Position
from pynwb.ophys import OnePhotonSeries, OpticalChannel, RoiResponseSeries


def gen_file(metadata):
    nwbfile = NWBFile(
        session_description=metadata['data_description'],
        identifier=metadata['worm_identifier'],
        session_start_time=metadata['worm_date'],
        lab=metadata['data_author'],
        institution=metadata['data_institute'],
        related_publications=metadata['data_publications']
    )

    return nwbfile


def create_im_vol(device, metadata, grid_spacing=[0.3208, 0.3208, 0.75],
                  grid_spacing_unit="micrometers", origin_coords=[0, 0, 0], origin_coords_unit="micrometers",
                  reference_frame="Worm head"):
    # channels should be ordered list of tuples (name, description)

    OptChannels = []
    OptChanRefData = []
    for eachChannel in range(len(metadata['channels'])):
        OptChan = OpticalChannelPlus(
            name=metadata['channels'][eachChannel]['fluorophore'],
            description=metadata['channels'][eachChannel]['filter'],
            excitation_lambda=float(metadata['channels'][eachChannel]['ex_lambda']),
            excitation_range=[float(metadata['channels'][eachChannel]['ex_low']),
                              float(metadata['channels'][eachChannel]['ex_high'])],
            emission_range=[float(metadata['channels'][eachChannel]['em_low']),
                            float(metadata['channels'][eachChannel]['em_high'])],
            emission_lambda=float(metadata['channels'][eachChannel]['em_lambda']),
        )

        OptChannels.append(OptChan)
        OptChanRefData.append(
            f"{metadata['channels'][eachChannel]['ex_lambda']}-{metadata['channels'][eachChannel]['em_lambda']}-{float(metadata['channels'][eachChannel]['em_high']) - float(metadata['channels'][eachChannel]['em_low'])}nm")

    order_optical_channels = OpticalChannelReferences(
        name='order_optical_channels',
        channels=OptChanRefData
    )

    imaging_vol = ImagingVolume(
        name='ImagingVolume',
        optical_channel_plus=OptChannels,
        order_optical_channels=order_optical_channels,
        description='NeuroPAL image of C elegans brain',
        device=device,
        location=metadata['worm_bodypart'],
        grid_spacing=metadata['grid_spacing'],
        grid_spacing_unit=grid_spacing_unit,
        origin_coords=origin_coords,
        origin_coords_unit=origin_coords_unit,
        reference_frame=reference_frame
    )

    return imaging_vol, order_optical_channels, OptChannels


def create_vol_seg(imaging_vol, blobs):
    vs = PlaneSegmentation(
        name='NeuroPALNeurons',
        description='Neuron centers for multichannel volumetric image',
        imaging_plane=imaging_vol,
    )

    labels = np.array(blobs['ID'].replace(np.nan, '', regex=True))

    voxel_mask = []

    for i, row in blobs.iterrows():
        x = row['X']
        y = row['Y']
        z = row['Z']
        weight = 1
        voxel_mask.append([float(x), float(y), float(z), float(1)])
        vs.add_roi(voxel_mask=voxel_mask)

    vs.add_column(
        name='ID_labels',
        description='ROI ID labels',
        data=labels,
        index=False,
    )

    return vs


def create_image(data, metadata, imaging_volume, opt_chan_refs):
    #print(np.shape(data))
    image = MultiChannelVolume(
        name='NeuroPALImageRaw',
        description=metadata['npal_volume_notes'],
        RGBW_channels=metadata['rgbw'],
        data=data.transpose(1, 0, 2, 3),
        imaging_volume=imaging_volume
    )

    return image


'''
Create NWB file from tif file of raw image, neuroPAL software created mat file and csv files of blob locations
'''

def extract_data(mat, index):
    try:
        return mat['worm'][0][0][index][0]
    except:
        return 'N/A'


def create_file_yemini(metadata):
    npal_file = sio.loadmat(metadata['mat_path'])
    npal_vol = npal_file['data']
    metadata['npal_shape'] = np.shape(npal_file['data'])
    metadata['rgbw'] = npal_file['prefs'][0][0][0][0]
    metadata['grid_spacing'] = npal_file['info'][0][0][1][0]

    reference_frame = f"worm {metadata['worm_bodypart']}"

    # Generate file.
    nwbfile = gen_file(metadata)

    # Populate subject data.
    nwbfile.subject = CElegansSubject(
        subject_id=metadata['worm_identifier'],
        age=metadata['worm_age'],
        # growth_stage_time = pd.Timedelta(hours=2, minutes=30).isoformat(),
        date_of_birth=metadata['worm_date'],
        # currently just using the session start time to bypass the requirement for date of birth
        growth_stage=metadata['worm_age'],
        # growth_stage_time=pd.Timedelta(hours=2, minutes=30).isoformat(),
        cultivation_temp=metadata['cultivation_temp'],
        description=metadata['data_description'],
        species="http://purl.obolibrary.org/obo/NCBITaxon_6239",
        sex=metadata['worm_sex'],
        # currently just using O for other until support added for other gender specifications
        strain=metadata['worm_strain']
    )

    # Populate device data.
    for eachDevice in range(len(metadata['devices'])):
        if eachDevice == 0:
            device = nwbfile.create_device(
                name=metadata['devices'][eachDevice]['name'],
                description=metadata['devices'][eachDevice]['description'],
                manufacturer=metadata['devices'][eachDevice]['manufacturer']
            )
        else:
            nwbfile.create_device(
                name=metadata['devices'][eachDevice]['name'],
                description=metadata['devices'][eachDevice]['description'],
                manufacturer=metadata['devices'][eachDevice]['manufacturer']
            )

    # Populate imaging data.
    ImagingVol, OptChannelRefs, OptChannels = create_im_vol(device, metadata,
                                                            grid_spacing=metadata['grid_spacing'],
                                                            reference_frame=reference_frame)

    image = create_image(npal_vol, metadata, ImagingVol, OptChannelRefs)
    nwbfile.add_acquisition(image)

    neuroPAL_module = nwbfile.create_processing_module(
        name='NeuroPAL',
        description=metadata['npal_volume_notes'],
    )
    nwbfile.add_imaging_plane(ImagingVol)
    neuroPAL_module.add(OptChannelRefs)
    neuroPAL_module.add(OptChannels)

    # Check for CSV file, populate if detected.
    if os.path.exists(metadata['mat_path'].with_suffix('.csv')):
        csvfile = metadata['mat_path'].with_suffix('.csv')
        csv = pd.read_csv(csvfile, skiprows=6)

        blobs = csv[['Real X (um)', 'Real Y (um)', 'Real Z (um)', 'User ID']]
        blobs = blobs.rename(columns={'Real X (um)': 'X', 'Real Y (um)': 'Y', 'Real Z (um)': 'Z', 'User ID': 'ID'})
        blobs['X'] = round(blobs['X'].div(metadata['grid_spacing'][0]))
        blobs['Y'] = round(blobs['Y'].div(metadata['grid_spacing'][1]))
        blobs['Z'] = round(blobs['Z'].div(metadata['grid_spacing'][2]))
        blobs = blobs.astype({'X': 'int16', 'Y': 'int16', 'Z': 'int16'})

        vs = create_vol_seg(ImagingVol, blobs)
        neuroPAL_module.add(vs)

    # Check for GCaMP video, populate if detected.
    if metadata['has_gcamp']:
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

    # Check for annotation file, populate if detected.
    if metadata['has_annotations']:
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

    # Check for activity data, populate if detected.
    if metadata['has_activity']:
        activityfile = args.activity_bool

        df = pd.read_csv(activityfile)
        df[df.columns[0]] = []
        df['neuron'] = []
        df['last updated'] = []
        df['function'] = []
        df['kwargs'] = []

        print(df)

        activity_traces = RoiResponseSeries(
            name='Neuronal_activity_data',
            description='Positional ROIs for traced neurons.',
            unit='pixels',
            rois=zeph5['x', 'y', 'z'],
            timestamps=zeph5['t_idx'],
            data=df.T
        )

        neuroPAL_module.add(activity_traces)

    if len(metadata['custom_file_name']) > 4:
        future_file = metadata['custom_file_name']
    else:
        future_file = f"{metadata['worm_identifier'].replace(' ', '-')}-{metadata['worm_date']}.nwb"

    io = NWBHDF5IO(os.path.join(metadata['parent_path'], future_file), mode='w')
    io.write(nwbfile)
    io.close()


def main():
    args = docopt(__doc__, version=f'NeuroPAL_ID NWB Conversion Tool')
    cache = sio.loadmat(Path(args['--cache']))

    metadata = {
        'data_author': cache['nwb_metadata'][0][0][0][0],
        'data_institute': cache['nwb_metadata'][0][0][1][0],
        'data_description': cache['nwb_metadata'][0][0][2][0],
        'data_publications': cache['nwb_metadata'][0][0][3][0],
        'devices': [],
        'channels': [],
        'worm_identifier': cache['nwb_metadata'][0][0][7][0],
        'worm_age': cache['nwb_metadata'][0][0][8][0],
        'worm_sex': cache['nwb_metadata'][0][0][9][0],
        'worm_bodypart': cache['nwb_metadata'][0][0][10][0],
        'worm_strain': cache['nwb_metadata'][0][0][11][0],
        'worm_date': datetime.datetime.utcfromtimestamp(cache['nwb_metadata'][0][0][12][0][0]),
        'cultivation_temp': float(cache['nwb_metadata'][0][0][13][0]),
        'worm_notes': cache['nwb_metadata'][0][0][14][0],
        'npal_volume_device': cache['nwb_metadata'][0][0][15][0],
        'npal_volume_notes': cache['nwb_metadata'][0][0][16][0],
        'segmentation_notes': cache['nwb_metadata'][0][0][17][0],
        'activity_notes': cache['nwb_metadata'][0][0][18][0],
        'custom_file_name': cache['nwb_metadata'][0][0][19][0],
        'parent_path': Path(cache['nwb_metadata'][0][0][20][0]),
        'mat_path': Path(cache['nwb_metadata'][0][0][21][0]),
        'has_ids': bool(cache['nwb_metadata'][0][0][22][0]),
        'has_csv': bool(cache['nwb_metadata'][0][0][23][0]),
        'has_gcamp': bool(cache['nwb_metadata'][0][0][24][0]),
        'has_annotations': bool(cache['nwb_metadata'][0][0][25][0]),
        'has_segmentations': bool(cache['nwb_metadata'][0][0][26][0]),
        'has_activity': bool(cache['nwb_metadata'][0][0][27][0])
    }

    for eachDevice in range(len(cache['nwb_metadata'][0][0][4])):
        name = cache['nwb_metadata'][0][0][4][eachDevice][0][0][0]
        manufacturer = cache['nwb_metadata'][0][0][4][eachDevice][1][0][0]
        description = cache['nwb_metadata'][0][0][4][eachDevice][2][0][0]

        metadata['devices'] += [{
            'name': name,
            'manufacturer': manufacturer,
            'description': description,
        }]

    for eachChannel in range(len(cache['nwb_metadata'][0][0][5])):
        fluorophore = cache['nwb_metadata'][0][0][5][eachChannel][0][0][0]
        filter = cache['nwb_metadata'][0][0][5][eachChannel][1][0][0]
        excitation_lambda = cache['nwb_metadata'][0][0][5][eachChannel][2][0][0]
        excitation_low = cache['nwb_metadata'][0][0][5][eachChannel][3][0][0]
        excitation_high = cache['nwb_metadata'][0][0][5][eachChannel][4][0][0]
        emission_lambda = cache['nwb_metadata'][0][0][5][eachChannel][5][0][0]
        emission_low = cache['nwb_metadata'][0][0][5][eachChannel][6][0][0]
        emission_high = cache['nwb_metadata'][0][0][5][eachChannel][7][0][0]

        metadata['channels'] += [{
            'fluorophore': fluorophore,
            'filter': filter,
            'ex_lambda': excitation_lambda,
            'ex_low': excitation_low,
            'ex_high': excitation_high,
            'em_lambda': emission_lambda,
            'em_low': emission_low,
            'em_high': emission_high,
        }]

    create_file_yemini(metadata)


if __name__ == '__main__':
    main()
