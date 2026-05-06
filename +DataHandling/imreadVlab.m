function [image, metadata] = imreadVlab(filename)
%IMREADVLAB Read in VLab image data from a given folder.
%
%   [IMAGE, METADATA] = IMREADVLAB(FILENAME)
%
%   Input:
%   folder - the folder containing the data
%
%   Outputs:
%   image - the image, a struct with fields:
%       pixels     = the number of pixels as (x,y,z)
%       scale      = the pixel scale, in microns, as (x,y,z)
%       channels   = the names of the channels
%       colors     = the color for each channel as (R,G,B)
%       dicChannel = the DIC channel number
%       lasers     = the laser wavelength for each channel
%       emissions  = the emsspyeion band for each channel as (min,max)
%       data       = the image data as (x,y,z,channel)
%   metadata - the meta data, a struct with fields:
%       keys      = the meta data keys (the names for the meta data)
%       values    = the meta data values (the values for the meta data)
%       hashtable = a Java Hashtable of keys and their values

% Initialize the image data.
image = [];
metadata = [];

% Assume the data is h5
[folder, ~, ~] = fileparts(filename);

% Read metadata
metadata_file = fullfile(folder, "metadata.json");
f = fopen(metadata_file);
if f < 0
    ME = MException('H5:MetaData', ['Cannot find ' metadata_file '!']);
    throw(ME);
end
chars = fread(f, '*char');
fclose(f);
vlab_meta = jsondecode(chars');

first_frame = h5read(filename, '/data', ...
    [1, 1, 1, 1, 1], ...
    [vlab_meta.shape_x, vlab_meta.shape_y, vlab_meta.shape_z, vlab_meta.shape_c, 1]);
%image.data = permute(first_frame, [2 1 3 4]);
image.data = first_frame;
image.pixels = [vlab_meta.shape_x, vlab_meta.shape_y, vlab_meta.shape_z];

if isfield(vlab_meta, 'xy_microns')
    
    image.scale = [vlab_meta.xy_microns, ...
        vlab_meta.xy_microns, ...
        vlab_meta.z_microns];
else
    image.scale = [0.4, 0.4, 1.5];
end

image.channels = {'red', 'green', 'blue', 'RFP', 'GCaMP'};
image.colors(1,:) = [1,0,0];
image.colors(2,:) = [0,1,0];
image.colors(3,:) = [0,0,1];
image.colors(4,:) = [1,1,1];
image.colors(5,:) = [1,0,1];

image.dicChannel = nan;

% Initialize the image excitation/emission information.
image.lasers = nan(5,1);
image.emissions = nan(5,1);

%write metadata
hashtable = java.util.Hashtable;
fNames = fieldnames(vlab_meta);

for k=1:length(fNames) 
        hashtable.put(fNames{k}, vlab_meta.(fNames{k}));
end

keys = arrayfun(@char, hashtable.keySet.toArray, 'UniformOutput', false);
values = cellfun(@(x) hashtable.get(x), keys, 'UniformOutput', false);

metadata.keys = keys;
metadata.values = values;
metadata.hashtable = hashtable;

