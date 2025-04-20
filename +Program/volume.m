classdef volume < handle
    % VOLUME A class that encapsulates a volumetric (or possibly video) 
    % dataset.
    %
    %   Glossary:
    %   - helper class: This class relies on helper classes in 
    %       +DataHandling/+Helpers, one per file format. For example,
    %       +DataHandling/+Helpers/nwb.m is the helper class for nwb 
    %       files, +DataHandling/+Helpers/nd2.m is the helper class for
    %       nd2 files, etc.
    %   - cursor: A struct specifying chunking-compatible indices. Most
    %       file types we work with do not support partial indexing when
    %       lazy loading, so we need to specify entire ranges for every
    %       dimension when attempting to read a specific chunk. For
    %       example, if you're trying to access the 5th slice of the 1st
    %       frame particular video file, the cursor would look as such:
    % 
    %           cursor = struct(
    %                       'x1', {1}, ...
    %                       'x2', {size of the x dimension}, ...
    %                       'y1', {1}, ...
    %                       'y2', {size of the y dimension}, ...
    %                       'z1', {5}, ...
    %                       'z2', {5}, ...
    %                       'c1', {1}, ...
    %                       'c2', {size of the c dimension}, ...
    %                       't1', {1}, ...
    %                       't2', {1});
    %   
    %       You can use the Program.GUI.cursor class to generate cursors on
    %       the fly.
    %
    %   Example usage:
    %       vol = volume('C:\data\myImage.nwb');
    %       first_slice = vol.read('z', 1);
    
    properties
        % References to helper classes for reading/writing the volume
        read_class = [];    % (Not strictly required if we rely on read_obj below)
        read_obj  = [];     % Reader object (e.g. returned by nwbRead, bfGetReader, etc.)
        read_mod = [];      % Reader module returned by nwbRead.

        % Path info
        fmt  = '';          % Extension of the volume path (e.g. 'nwb', 'tiff')
        name = '';          % Name of volume file
        path = '';          % Complete volume path

        % Metadata
        device = [];        % The device used to capture this volume.
        subject = [];       % The subject captured in this volume.
        settings = [];      % NeuroPAL_ID settings for this volume.

        % Cursor
        x = -1;
        y = -1;
        z = -1;
        c = -1;
        t = -1;

        % Dimensionality
        nx = -1;            % Width of the volume
        ny = -1;            % Height of the volume
        nz = -1;            % Depth of the volume
        nc = -1;            % Number of channels
        nt = -1;            % Number of timepoints (frames)
        dims = [];          % Array of size (1,5): [nx, ny, nz, nc, nt]
        native_dims = [];   % Dims as loaded from file

        % Channels
        channels = {};      % Cell array for the names of each channel
        rgb = [];           % Indices of channels corresponding to [R,G,B] if relevant
        
        is_video = -1;      % Boolean indicating video vs. single-volume; -1 if uninitialized
        processing_steps = {};
        
        dtype = 0;       % Datatype numeric code
        dtype_max = [];  % Integer maximum for this volume's datatype.
        dtype_str = '';  % Datatype string, e.g. 'uint8', 'double', etc.
        is_valid_dtype = -1;
    end

    methods
        function obj = volume(path)
            %VOLUME Constructor function for the volume class.
            %
            %   Inputs:
            %   - path: String/char representing a file path.
            %
            %   Outputs:
            %   - obj: volume instance.

            % If there's an active progress dialogue, add a step indicating
            % that we're currently creating a new volume.
            Program.GUI.dialogues.step('Creating volume');

            if nargin == 0
                % If no path was given, raise an error.
                error('No path provided for volume class constructor.');
            elseif isempty(path)
                % If an empty path was given, raise an error.
                error('Empty path provided for volume class constructor.');
            else
                % If a non-empty path was given, get the extension of the
                % file it points to.
                [~, fname, fmt] = fileparts(path);
                
                % Construct the handle of this file type's prospective
                % helper class.
                fmt = fmt(2:end);
                class_handle = sprintf("DataHandling.Helpers.%s.m", fmt);

                % Check whether this class exists.
                if ~exist(class_handle, 'class')
                    % If not, throw an error.
                    error('No helper script found for format %s.', fmt)
                else
                    % If it does, set the given path as this volume's path
                    % property.
                    obj.path = path;
                    obj.name = fname;
                    obj.fmt = fmt;

                    % If this constructor was called by a function that is
                    % exclusive to videos, mark this volume as a video.
                    obj.is_video = Program.Validation.lineage() == 2;

                    % Trigger the load() function to populate the rest of
                    % the properties.
                    obj.load();
                end
            end
        end
        
        function info_struct = info(obj)
            % INFO Return a struct of the volume's public properties
            %
            %   Inputs:
            %   - obj: volume instance.
            %
            %   Outputs:
            %   - info_struct: Struct containing volume properties.
            
            % Get a lit of all of this volume's properties.
            propList = properties(obj);

            % Initialize info_struct.
            info_struct = struct();

            % Iteratively add each property to info_struct.
            for k = 1:numel(propList)
                info_struct.(propList{k}) = obj.(propList{k});
            end
        end
        
        function load(obj)
            % LOAD Populate the volume's properties with metadata read from
            % the file specified by its path property.
            %
            %   Inputs:
            %   - obj: volume instance.
            %
            %   Outputs:
            %   - obj: volume instance.
            
            % Check whetehr this is a NeuroPAL file.
            if DataHandling.Helpers.npal.is_npal_file(obj.path)
                % If so, set the appropriate helper class.
                obj.read_class = DataHandling.Helpers.npal;
            else
                % If not, define the helpers class based on the file type.
                obj.read_class = DataHandling.Helpers.(obj.fmt);
            end
            
            % Assign the reader object using the helper class.
            obj.read_obj = obj.read_class.get_reader(obj.path);

            % Read what metadata we are able to for this file type.
            metadata = obj.read_metadata();
            
            % Define the nx, ny, nz, nc, and nt properties based on the
            % array dimensions.
            obj.nx = metadata.nx;
            obj.ny = metadata.ny;
            obj.nz = metadata.nz;
            obj.nc = metadata.nc;
            obj.nt = metadata.nt;

            % Set the x, y, and z properties to half of their respective
            % dimensions maximums.
            obj.x = round(obj.nx/2);
            obj.y = round(obj.ny/2);
            obj.z = round(obj.nz/2);

            % Set the dim property such that it is a 1xndims array.
            obj.dims = [obj.nx, obj.ny, obj.nz, obj.nc, obj.nt];

            % Set the native dims property.
            obj.native_dims = metadata.native_dims;

            % Check the file's is_video propert has been initialized yet.
            if obj.is_video == -1
                % If not, set it to 1 if we have more than 1 frame.
                obj.is_video = (obj.nt > 1);
            end
            
            % Check whether the metadata specifies channel information...
            if isfield(metadata, 'channels')
                % If so, assign these to the channels property.
                obj.channels = metadata.channels;

                % Then sort these channels according to their identities.
                obj.sort_channels();
            end

            % Check whether the metadata specifies device information...
            if isfield(metadata, 'device')
                % If so, assign it to the device property.
                obj.device = metadata.device;
            else
                % If not, initialize a blank struct asn assign it to the
                % device property.
                obj.device = struct();
                obj.device.manufacturer = '';
                obj.device.voxel_resolution = [1 1 1];
            end
            
            % Check whether the metadata specifies a datatype.
            if isfield(metadata, 'dtype')
                % If so, assign it to the dtype property.
                obj.dtype = metadata.dtype;
            end

            % Check whether the metadata specified a data class string.
            if isfield(metadata, 'dtype_str')
                % If so, assign it to the dtype_str property.
                obj.dtype_str = metadata.dtype_str;
            end

            % Resolve the datatype. This essentially checks whether the
            % datatype is Matlab-compatible (i.e. base-8). We have to do
            % this because Nikon will sometimes give us uint12 arrays.
            [obj.is_valid_dtype, obj.dtype, obj.dtype_str, obj.dtype_max] = Program.Helpers.resolve_dtype(obj);

            % Check whether the metadata specified subject information.
            if isfield(metadata, 'subject')
                % If so, use it to instantiate a subject object and
                % assign it to the subject property.
                obj.subject = Program.subject(metadata);
            else
                % If not, instantiate an empty subject object.
                obj.subject = Program.subject();
            end
            
            % Validate properties. This is obsolete.
            obj.validate();
        end
        
        function data = read(obj, cursor, varargin)
            %READ This function reads a specified section of the 
            % volume's raw data array.
            %
            %   Inputs:
            %   - obj: volume instance.
            %   - cursor: A struct specifying chunking-compatible 
            %       indices.
            %   - varargin: A cell array with a variable number of
            %       elements, which represent key/value pairs of 
            %       additional input arguments to be parsed.
            %
            %   Outputs:
            %   - data: The requested array.

            % If any additional input arguments beyond the cursor were
            % were passed, we will create a cursor.
            create_cursor = ~isempty(varargin);

            % Check whether we were provided with a cursor.
            have_cursor = exist('cursor', 'var') ...
                && isa(cursor, 'Program.GUI.cursor');

            if ~have_cursor
                % If we don't have a cursor...
                if create_cursor
                    % If we have been given enough input arguments to 
                    % generate a cursor, do so using the volume
                    % dimensions and any additional input arguments.
                    cursor = Program.GUI.cursor.generate(obj.dims, ...
                        cursor, varargin{:});
                else
                    % If we have not been given enough input arguments
                    % to generate a cursor at specific coordinates,
                    % generate one based on the volume dimensions and
                    % the last slice that was read.
                    cursor = Program.GUI.cursor.generate( ...
                        obj.dims, 'z', obj.z);
                end
            end

            % Pass the volume and the cursor to the helper class's read
            % function.
            data = obj.read_class.read(obj, ...
                'cursor', cursor);

            % Some formats return double arrays on chunk read.
            % Check for this and if so, correct the datatype.
            if ~isa(data, obj.dtype_str)
                data = cast(data, obj.dtype_str);
            end
        end

        function mdata = read_metadata(obj)
            %READ_METADATA This function reads in what metadata we can
            % from a given volume's file using its helper class.
            %
            %   Inputs:
            %   - obj: volume instance.
            %
            %   Outputs:
            %   - mdata: Struct containing the metadata.

            % Get the program config.
            config = Program.config;

            % Call the helper class's get_metadata function.
            mdata = obj.read_class.get_metadata(obj);

            % Get every field the helper class was able to populate.
            mdata_fields = fieldnames(mdata);

            % If the returned struct features any unexpected fields, we
            % are likely dealing with a file containing more than one
            % volume, in which case we need to identify which volume's
            % metadata we should be using.
            if any(~ismember( ...
                    mdata_fields, ...
                    config.default.fields.md_volume))

                % Check the volume file type.
                switch obj.fmt
                    case 'nwb'
                        % If this is an nwb, then we need to get the
                        % metadata from a specific module rather than the
                        % file itself.

                        % Check whether the volume's is_video property
                        % is uninitialized.
                        if obj.is_video ~= -1
                            % If not, then check whether this volume is
                            % a video.
                            if obj.is_video
                                % If this is a video, then we know that
                                % we need to be looking at the calcium
                                % imaging acquisition module.
                                obj.read_mod = mdata_fields{ ...
                                    contains(lower(mdata_fields), ...
                                    'calcium')};
                            else
                                % If this isn't a video, then we know
                                % that we need to be looking at the
                                % non-calcium imaging acquisition module.
                                obj.read_mod = mdata_fields{ ...
                                    ~contains(lower(mdata_fields), ...
                                    'calcium')};
                            end
        
                            % Filter for metdata specific to the
                            % appropriate module.
                            mdata = mdata.(obj.read_mod);

                        else
                            % If we don't know whether or not this is a
                            % video, then we need to ask the user which
                            % volume within the NWB file they're trying
                            % to load.
                            choice = uiconfirm(Program.window, ...
                                "Which volume would you like to load?", ...
                                "NeuroPAL_ID", 'Options', mdata_fields);

                            % Update the volume's is_video property based
                            % on the user's response.
                            obj.is_video = contains(lower(choice), ...
                                'calcium');

                            % Set the chosen module as this volume's
                            % read_mod property.
                            obj.read_mod = choice;

                            % Filter for metadata specific to the chosen
                            % module.
                            mdata = mdata.(choice);
                        end

                    otherwise
                        % If we received unexpected metadata fields and
                        % this is NOT an NWB file, then we raise an error
                        % describing the issue.

                        % Get the names of the unexpected fields.
                        wtf_idx = find(~ismember( ...
                            mdata_fields, ...
                            config.default.fields.md_volume));
                        wtf_str = mdata_fields{wtf_idx};

                        % Raise the error.
                        error("%s datahandling function returned " + ...
                            "unexpected metadata fields in file %s:" + ...
                            "\n%s", upper(obj.fmt), obj.name, ...
                            join(wtf_str, ', '))
                end
            end
        end

        function [array, raw_array] = render(obj, varargin)
            %RENDER Return a selected portion of a given volume's data
            % array, processed to account for gammas, histogram limits,
            % et cetera.
            %
            %   Inputs:
            %   - obj: volume instance.
            %   - varargin: A cell array with a variable number of
            %       elements, which represent key/value pairs of 
            %       additional input arguments to be parsed.
            %
            %   Outputs:
            %   - array: The processed data array.
            %   - raw_array: The raw data array.

            if isempty(varargin)
                % If no input arguments were passed, generate a cursor
                % struct.
                cursor = Program.GUI.cursor( ...
                    'volume', obj, ...
                    'interface', Program.state().interface);

            elseif isa(varargin{1}, 'Program.GUI.cursor')
                % If additional input arguments were passed and the first
                % of these is a cursor object, set this as our cursor.
                cursor = varargin{1};

            else
                % If additional input arguments were passed and these do
                % not include a cursor, generate one.
                cursor = Program.GUI.cursor.generate( ...
                    obj.dims, varargin{:});
            
            end
            
            % Read the raw array.
            raw_array = obj.read(cursor);

            % Initialize the processed array.
            array = raw_array;

            % Initialize an array that will track any channels that will
            % need to be deleted from the processed array.
            to_delete = [];

            % Iterate over the channels represented in this array.
            for ch=cursor.c1:cursor.c2
                % Get this channel's metadata.
                channel = obj.channels{ch};

                % Get the index within the loaded array that corresponds to
                % this channel. This is important because, for example
                arr_idx = channel.arr_idx - cursor.c1 + 1;

                if channel.is_rendered
                    array(:, :, :, arr_idx) = imadjustn(array(:, :, :, arr_idx), channel.lh_in, channel.lh_out, channel.gamma);

                    if ~channel.is_rgb
                        channel_array = array(:, :, :, arr_idx);
                        pseudocolor_array = Program.render.generate_pseudocolor(channel_array, channel);
                        array(:, :, :, obj.rgb) = array(:, :, :, obj.rgb) + pseudocolor_array;
                        to_delete = [to_delete, arr_idx];
                    end
                    
                elseif channel.is_rgb
                    array(:, :, :, arr_idx) = 0;
                    
                else
                    to_delete = [to_delete, arr_idx];
                end
            end

            array(:, :, :, to_delete) = [];
    
            %array = array(:, :, :, obj.rgb);
        end
        
        function converted_instance = convert(obj, fmt)
            % CONVERT  Create a new file of format fmt, chunk-write current volume's
            % contents, and return a new volume instance referencing that file.
            %
            % Example:
            %   newVol = vol.convert('tiff');
            %

            if strcmp(obj.fmt, fmt)
                converted_instance = obj;
            end

            app = Program.app;
            app.state.now("Converting %s.%s to %s format", obj.name, obj.fmt, fmt);
            %Program.GUI.dialogue.add_task( ...
            %    sprintf("Converting %s.%s to %s format", ...
            %    obj.name, obj.fmt, fmt), 1);
            
            dtype_flag = strcmpi(fmt, 'double') || startsWith(fmt, 'uint');
            if dtype_flag
                target_dtype = fmt;

                new_name = sprintf('%s-%s', obj.name, fmt);
                target_path = strrep(obj.path, obj.name, new_name);
                
                target_helper = obj.read_class;
                target_helper.create(target_path, 'like', obj, ...
                    'dtype', target_dtype);

            else
                target_dtype = obj.dtype_str;
            
                if ~strcmp(fmt, 'npal')
                    target_path = strrep(obj.path, obj.fmt, fmt);
                else
                    npal_name = sprintf('%s-NPAL', obj.name);
                    target_path = strrep(obj.path, obj.name, npal_name);
                    target_path = strrep(target_path, obj.fmt, 'mat');
                end
            
                target_helper = feval(str2func(['DataHandling.Helpers.' fmt]));
                target_helper.create(target_path, 'like', obj);
            end
            
            % Now chunk-write from the current volume into the new file
            if obj.is_video
                chunking_method = 'framewise';
            else
                chunking_method = 'slicewise';
            end

            obj.write_chunk( ...
                target_path, ...
                'method', chunking_method, ...
                'helper', target_helper, ...
                'dtype', target_dtype);
            
            % Finally, return a new volume instance referencing the new file
            % (assuming Program.Data.volume is how you normally construct one)
            converted_instance = Program.volume(target_path);
            converted_instance.load(); % so that the new instance is ready to go
        end
        
        function write(obj, varargin)
            % WRITE  Writes a requested chunk to the volume file, using the 
            % underlying helper's writer. This is the complement of read(...).
            %
            % Example:
            %   vol.write('t',1, 'z',2, 'arr', some2Dmatrix);
            
            p = inputParser();
            addParameter(p, 't', 1);
            addParameter(p, 'z', 1);
            addParameter(p, 'c', []);
            addParameter(p, 'x', []);
            addParameter(p, 'y', []);
            addParameter(p, 'mode', 'chunk');
            addParameter(p, 'arr', []);  % array to write
            parse(p, varargin{:});
            
            if isempty(p.Results.arr)
                error('You must supply the ''arr'' parameter with data to write.');
            end
            
            % Now call the helper's write method
            obj.read_obj.write('mode', p.Results.mode, ...
                               't', p.Results.t, ...
                               'z', p.Results.z, ...
                               'c', p.Results.c, ...
                               'x', p.Results.x, ...
                               'y', p.Results.y, ...
                               'arr', p.Results.arr);
        end

        function update_channels(obj, target)
            if nargin < 2
                c_start = 1;
                c_end = obj.nc;

            elseif isnumeric(target)
                c_start = target;
                c_end = target;
            end

            for tc=c_start:c_end
                obj.channels{tc}.update;
            end

            obj.nc = length(obj.channels);
        end

        function out = get(obj, query)
            query = lower(query);
            out = [];
            switch query
                case 'rgbw'
                    out = cell2mat(cellfun(@(x)(x.arr_idx*x.is_rgb), obj.channels,'UniformOutput', false));

                case {'gfp', 'dic'}
                    found = cell2mat(cellfun(@(x)(x.arr_idx*strcmp(x.color, query)), obj.channels,'UniformOutput', false));
                    if any(found)
                        found = found(found~=0);
                    end

                case 'gamma'
                    out = cell2mat(cellfun(@(x)(x.gamma), obj.channels,'UniformOutput', false));
                    
                otherwise
            end
        end
    end

    methods (Access = private)
        function write_chunk(obj, t_file, varargin)
            p = inputParser();
            addParameter(p, 'method', 'slice');
            addParameter(p, 'helper', obj.read_class);
            addParameter(p, 'dtype', obj.dtype_str);
            parse(p, varargin{:});

            should_convert_dtype = ~strcmpi(p.Results.dtype, obj.dtype_str);
            
            switch p.Results.method
                case {'frame', 'framewise'}
                    app.state.progress('Frame (%.f/%.f)', obj.nt);
                    for this_frame = 1:obj.nt
                        app.state.progress();
                        app.state.progress('Slice (%.f/%.f)', obj.nz);
                        for this_slice = 1:obj.nz
                            app.state.progress();
                            chunk = obj.read('t', this_frame, 'z', this_slice);
                            if numel(size(chunk)) <= 4
                                null_data = zeros( ...
                                    size(chunk, 1), size(chunk, 2), 1, ...
                                    size(chunk, 3), 1, class(chunk));
                                null_data(:, :, 1, :, 1) = chunk;
                                chunk = null_data;
                            end

                            if should_convert_dtype
                                chunk = cast(chunk, p.Results.dtype);
                            end
    
                            p.Results.helper.write('mode', 'chunk', ...
                                            'file', t_file, ...
                                            't', this_frame, 'z', this_slice, ...
                                            'arr', chunk);
                        end
                    end
                case {'slice', 'slicewise'}
                    app.state.progress('Slice %.f/%.f', obj.nz);
                    for this_slice = 1:obj.nz
                        app.state.progress();
                        chunk = obj.read('z', this_slice);
                        if numel(size(chunk)) <= 3
                            null_data = zeros( ...
                                size(chunk, 1), size(chunk, 2), 1, ...
                                size(chunk, 3), class(chunk));
                            null_data(:, :, 1, :) = chunk;
                            chunk = null_data;
                        end

                        if should_convert_dtype
                            chunk = cast(chunk, p.Results.dtype);
                        end
    
                        p.Results.helper.write('mode', 'chunk', ...
                                        'file', t_file, ...
                                        'z', this_slice, ...
                                        'arr', chunk);
                    end
            end
        end

        function obj = sort_channels(obj)
            % Define the preferred color order
            order = {'red', 'green', 'blue', 'white', 'dic', 'gfp', 'gcamp'};
            
            % Extract the actual colors from each channel
            colors = cellfun(@(x)x.color, obj.channels, 'UniformOutput', false);
            
            % Map each color to its index in "order"; returns 0 if not found
            [~, idx_in_order] = ismember(colors, order);
        
            N = numel(idx_in_order);
            gui_idx = zeros(1, N);
            
            % 1) Track which recognized indices have been 'claimed' as first occurrences
            firstOccurrenceUsed = false(1, max(idx_in_order)); 
            
            % 2) Lists for duplicates and unknown
            duplicates = [];   % will store channel indices (k) for recognized duplicates
            unknowns = [];     % will store channel indices (k) for unrecognized colors
            
            % 3) First pass: assign each recognized color's first occurrence to its canonical index
            for k = 1:N
                idx = idx_in_order(k);
                if idx > 0
                    if ~firstOccurrenceUsed(idx)
                        % Assign the canonical index (first occurrence)
                        gui_idx(k) = idx;
                        firstOccurrenceUsed(idx) = true;
                    else
                        % This is a duplicate of a recognized color
                        duplicates(end+1) = k; %#ok<AGROW>
                    end
                else
                    % Unrecognized color goes in 'unknowns'
                    unknowns(end+1) = k; %#ok<AGROW>
                end
            end
            
            % 4) Figure out where to start assigning duplicates.
            %    We use 'maxRecognized' = largest canonical index that actually appeared.
            maxRecognized = max(idx_in_order);
            if isempty(maxRecognized)
                % No recognized colors at all? Start from 1
                maxRecognized = 0;
            end
            
            nextAvail = maxRecognized + 1;
            
            % 5) Assign duplicates from 'nextAvail' upwards
            for d = 1:numel(duplicates)
                k = duplicates(d);
                gui_idx(k) = nextAvail;
                nextAvail = nextAvail + 1;
            end
            
            % 6) Finally assign unknown channels after duplicates
            for u = 1:numel(unknowns)
                k = unknowns(u);
                gui_idx(k) = nextAvail;
                nextAvail = nextAvail + 1;
            end
            
            % 7) Store back into the channels
            for k = 1:N
                obj.channels{k}.gui_idx = gui_idx(k);
            end

            [~, obj.rgb] = ismember(sort(gui_idx), gui_idx);
            obj.rgb = obj.rgb(1:3);
        end


        function validate(obj)
            % VALIDATE  Ensure the volume properties have valid values.
            % Return true (logical) if all is valid, otherwise false.
            
            % Basic checks
            if obj.nx <= 1 || obj.ny <= 1 || obj.nz <= 1 || obj.nc < 1
                error(['Invalid volume dimension(s):' ...
                    '\n- nx = %.1f' ...
                    '\n- ny = %.1f' ...
                    '\n- nz = %.1f' ...
                    '\n- nc = %.1f' ...
                    '\n- nt = %.1f'], ...
                    obj.nx, obj.ny, obj.nz, obj.nc, obj.nt);
            end
            
            if obj.is_video == 1 && obj.nt <= 1
                error('Video volume is flagged, but nt (%.1f) <= 1.', ...
                    obj.nt);
            end

            if obj.nc == length(obj.channels)
                for c=1:obj.nc
                    obj.channels{c}.set('parent', obj);
                end
            else
                error( ...
                    ['Volume has %.f specified channel dimensions, ' ...
                    'but only %.f channels.'], ...
                    obj.nc, length(obj.channels));
            end
        end
    end
end
