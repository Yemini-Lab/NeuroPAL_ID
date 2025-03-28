classdef volume < handle
    % VOLUME A class that encapsulates a volumetric (or possibly video) dataset.
    %
    % This class depends on helper classes in +DataHandling/+Helpers, one
    % per file format. For example, +DataHandling/+Helpers/nwb.m, 
    % +DataHandling/+Helpers/nd2.m, etc.
    %
    % Example usage:
    %   vol = volume('C:\data\myImage.nwb');
    %   vol.load();        % read metadata
    %   dataSlice = vol.read('z',1);  % read 1st Z-slice
    %   infoStruct = vol.info();
    %
    
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
            % Constructor for the volume class
            app = Program.app;
            app.state.now('Creating volume');
            if nargin == 0
                error('No path provided for volume class constructor.');
            elseif isempty(path)
                error('Empty path provided for volume class constructor.');
            else
                [~, ~, fmt] = fileparts(path);
                fmt = fmt(2:end);
                if ~isfile(sprintf("+DataHandling\\+Helpers\\%s.m", fmt))
                    error('No helper script found for format %s.', fmt)
                else
                    obj.path = path;
                    obj.is_video = Program.Validation.lineage() == 2;
                    obj.load();
                end
            end
        end
        
        function infoStruct = info(obj)
            % INFO  Return a struct of the volume's public properties
            %
            % Example:
            %   s = vol.info();
            %
            % 's' will contain fields such as 'nx', 'ny', 'nz', 'fmt', etc.
            
            propList = properties(obj);
            infoStruct = struct();
            for k = 1:numel(propList)
                infoStruct.(propList{k}) = obj.(propList{k});
            end
        end
        
        function load(obj)
            % LOAD  Read metadata from the file, fill in dimension properties, etc.
            %
            % Example:
            %   vol = volume('myFile.nwb');
            %   vol.load();  % sets vol.nx, vol.ny, vol.nz, vol.nt, etc.

            [~, fname, ext] = fileparts(obj.path);
            obj.name = fname;
            if startsWith(ext, '.')
                ext = ext(2:end);
            end
            obj.fmt = ext;
            
            % Dynamically instantiate or retrieve a helper for this file format
            if DataHandling.Helpers.npal.is_npal_file(obj.path)
                obj.read_class = DataHandling.Helpers.npal;
                obj.read_obj = obj.read_class.get_reader(obj.path);
            else
                obj.read_class = DataHandling.Helpers.(obj.fmt);
                obj.read_obj = obj.read_class.get_reader(obj.path);
            end
            
            % The skeleton calls obj.read('metadata') to retrieve metadata
            metadata = obj.read_metadata();
            
            obj.nx = metadata.nx;
            obj.x = round(obj.nx/2);

            obj.ny = metadata.ny;
            obj.y = round(obj.ny/2);

            obj.nz = metadata.nz;
            obj.z = round(obj.nz/2);

            obj.nc = metadata.nc;
            obj.nt = metadata.nt;
            obj.dims = [obj.nx, obj.ny, obj.nz, obj.nc, obj.nt];
            obj.native_dims = metadata.native_dims;

            if obj.is_video == -1
                obj.is_video = (obj.nt > 1);
            end
            
            if isfield(metadata, 'channels')
                obj.channels = metadata.channels;
                obj.sort_channels();
            end

            if isfield(metadata, 'device')
                obj.device = metadata.device;
            else
                obj.device = struct();
                obj.device.manufacturer = '';
                obj.device.voxel_resolution = [1 1 1];
            end
            
            if isfield(metadata, 'dtype')
                obj.dtype = metadata.dtype;
            end

            if isfield(metadata, 'dtype_str')
                obj.dtype_str = metadata.dtype_str;
            end

            [obj.is_valid_dtype, obj.dtype, obj.dtype_str, obj.dtype_max] = Program.Helpers.resolve_dtype(obj);

            if isfield(metadata, 'subject')
                obj.subject = Program.subject(metadata);
            else
                obj.subject = Program.subject();
            end
            
            % Validate or do any additional initialization
            obj.validate();
        end
        
        function data = read(obj, cursor, varargin)
            create_cursor = ~isempty(varargin);
            have_cursor = exist('cursor', 'var') ...
                && isa(cursor, 'Program.GUI.cursor');

            if ~have_cursor
                if create_cursor
                    cursor = Program.GUI.cursor.generate(obj.dims, ...
                        cursor, varargin{:});
                else
                    cursor = Program.GUI.cursor.generate( ...
                        obj.dims, 'z', obj.z);
                end
            end

            data = obj.read_class.read(obj, ...
                'cursor', cursor);

            % Some formats return double arrays on chunk read.
            % Check for this and if so, correct the datatype.
            if ~isa(data, obj.dtype_str)
                data = cast(data, obj.dtype_str);
            end
        end

        function mdata = read_metadata(obj)
            config = Program.config;
            mdata = obj.read_class.get_metadata(obj);
            mdata_fields = fieldnames(mdata);
            if any(~ismember( ...
                    mdata_fields, ...
                    config.default.fields.md_volume))

                switch obj.fmt
                    case 'nwb'
                        if obj.is_video ~= -1
                            if obj.is_video
                                obj.read_mod = mdata_fields{ ...
                                    contains(lower(mdata_fields), ...
                                    'calcium')};
                            else
                                obj.read_mod = mdata_fields{ ...
                                    ~contains(lower(mdata_fields), ...
                                    'calcium')};
                            end
        
                            mdata = mdata.(obj.read_mod);

                        else
                            choice = uiconfirm(Program.window, ...
                                "Which volume would you like to load?", ...
                                "NeuroPAL_ID", 'Options', mdata_fields);
                            obj.is_video = contains(lower(choice), ...
                                'calcium');

                            obj.read_mod = choice;
                            mdata = mdata.(choice);
                        end

                    otherwise
                        wtf_idx = find(~ismember( ...
                            mdata_fields, ...
                            config.default.fields.md_volume));
                        wtf_str = mdata_fields{wtf_idx};
                        error("%s datahandling function returned " + ...
                            "unexpected metadata fields in file %s:" + ...
                            "\n%s", upper(obj.fmt), obj.name, ...
                            join(wtf_str, ', '))
                end
            end
        end

        function [array, raw_array] = render(obj, varargin)
            if isempty(varargin)
                cursor = Program.GUI.cursor( ...
                    'volume', obj, ...
                    'interface', Program.state().interface);

            elseif isa(varargin{1}, 'Program.GUI.cursor')
                cursor = varargin{1};

            else
                cursor = Program.GUI.cursor.generate( ...
                    obj.dims, varargin{:});
            
            end
            
            raw_array = obj.read(cursor);
            to_delete = [];
            array = raw_array;
    
            for ch=cursor.c1:cursor.c2
                channel = obj.channels{ch};
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
