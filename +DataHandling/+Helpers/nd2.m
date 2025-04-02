classdef nd2
    % ND2 Class for handling and extracting metadata and images from 
    % ND2 files.
    %
    %   Glossary:
    %   - reader = A class defined by the bioformats API which facilitates
    %       lazy loading & writing from ND2 files.
    
    properties (Access = public, Constant)
        % Keys used to identify voxel resolution.
        key_map = dictionary( ...
            'xy_scale', {'dCalibration'}, ...
            'z_scale', {'dZStep'});

        % Keys used to identify channel metadata
        channel_keys = { ...
            'ChannelName', ...
            'ChannelOrder', ...
            'ChannelCount', ...
            'ChannelColor'}; 
        
        name_substr = 'Global Name #'; % Base substring used to identify channel names globally
    end
    
    methods (Static, Access = public)
        %% Functions merged from agnostic volume reader branch.
        function obj = get_reader(path)
            %GET_READER Returns a reader object.
            %
            %   Inputs:
            %   - path: string/char representing a filepath.
            %
            %   Outputs:
            %   - obj: Bioformats-compatible Java object 
            %       (loci.formats.ChannelSeparator)

            % Check whether the path ends in .nd2.
            if ~endsWith(path, '.nd2')
                % If not, raise an error.
                error( ...
                    'Non-nd2 file passed to nd2 get_reader function: \n%s', ...
                    path)
            end
            
            % Call bioformats function to generate reader object.
            obj = bfGetReader(path);
        end

        function dimensions = get_dimensions(reader)
            %GET_DIMENSIONS Return the dimensions of a given ND2 reader
            % object's image array.
            %
            %   Inputs:
            %   - reader: Bioformats-compatible Java object 
            %       (loci.formats.ChannelSeparator)
            %
            %   Outputs:
            %   - dimensions: Struct describing the dimensions of the
            %       array.

            % Validate input by checking its class.
            if ~isa(reader, 'loci.formats.ChannelSeparator')
                error("Invalid file of class %s passed to nd2" + ...
                    "get_dimensions function.", class(reader));
            end

            % Get order of dimensions. Note that we call a char
            % conversion here because the reader will return a java object
            % by default.
            order_of_dimensions = char(reader.getDimensionOrder);

            % Initialize dimension struct.
            dimensions = struct();

            % Iterate over all dimensions in order.
            for d=1:length(order_of_dimensions)
                % Get the name of this dimension (e.g. "X", "Y", etc).
                dimension_label = order_of_dimensions(d);

                % Get the appropriate function to obtain this dimension's
                % size from the reader (e.g. "GetSizeX", "GetSizeY", etc).
                dimension_func = sprintf("getSize%s", dimension_label);

                % call this function and assign its output to the struct.
                dimensions.(lower(dimension_label)) = reader.(dimension_func);
            end
        end

        function [bit_depth, datatype] = get_datatype(reader)
            %GET_DATATYPE Return the native datatype of a given ND2 reader
            % object's image array. Note that "native" here refers to the
            % actual datatype you will encounter if you load the image.
            % This distiction is important to make because it may differ
            % from the datatype you receive when lazy loading using
            % the bioformats reader.
            %
            %   Inputs:
            %   - reader: Bioformats-compatible Java object 
            %       (loci.formats.ChannelSeparator)
            %
            %   Outputs:
            %   - bit_depth: Integer describing the bit depth of the
            %       reader's image array (e.g. 8 for uint8, 16 for uint16).
            %   - datatype: String/char representing the matlab-compatible
            %       class name that corresponds to this bit depth (e.g.
            %       'uint8', 'uint16', etc).

            % Validate input by checking its class.
            if ~isa(reader, 'loci.formats.ChannelSeparator')
                error("Invalid file of class %s passed to nd2" + ...
                    "get_dimensions function.", class(reader));
            end

            % Get the datatype from the reader object.
            datatype = char(reader.getMetadataStore().getPixelsType(0));

            % Extract bit depth from datatype.
            bit_depth = str2double(extract(datatype, digitsPattern));

            % Check whether this bit depth is matlab-compatible by 
            % calculating the remainder after division of by 8;
            is_matlab_compatible = mod(bit_depth, 8) == 0;

            % If this bit depth is not matlab-compatible...
            if ~is_matlab_compatible
                % Define valid bit_depths.
                valid_bit_depths = 8:8:64;

                % Calculate the distance between the real bit depth and
                % each valid bit depth.
                dist_from_true_bit_depth = bit_depth - valid_bit_depths;

                % Find the smallest distance.
                smallest_dist = min(abs(dist_from_true_bit_depth));

                % Set the bit depth equal to the closest valid bit depth.
                % Note that during the read process, we check whether this
                % matches the datatype of the array we receive from the
                % reader and run a conversion should they not match.
                bit_depth = valid_bit_depths( ...
                    find(valid_bit_depths, smallest_dist));

                % Compose the appropriate class name for new bit depth.
                datatype = sprintf("uint%.f", bit_depth);
            end
        end

        function xyz_array = get_voxel_resolution(reader)
            %GET_VOXEL_RESOLUTION Return an array representing the voxel
            % resolution (also known as the grid spacing).
            %
            %   Inputs:
            %   - reader: Bioformats-compatible Java object 
            %       (loci.formats.ChannelSeparator)
            %
            %   Outputs:
            %   - xyz_array: Numerical 1x3 array representing the voxel
            %       resolution returned by the reader. Sorted in the
            %       order xyz, and the x and y should match.

            % Validate input by checking its class.
            if ~isa(reader, 'loci.formats.ChannelSeparator')
                error("Invalid file of class %s passed to nd2" + ...
                    "get_dimensions function.", class(reader));
            end

            % Generate a metadata store object from the reader.
            metadata_store = reader.getMetadataStore();

            % Extract the x, y, and z resolution from the metadata store.
            xyz_array = [ ...
                metadata_store.getPixelsPhysicalSizeX(0).value, ...
                metadata_store.getPixelsPhysicalSizeY(0).value, ...
                metadata_store.getPixelsPhysicalSizeZ(0).value];
            xyz_array = double(xyz_array);
        end

        %% Functions merged from slow_merge.
        function [image_array, metadata] = open(filepath)
            %OPEN Open an ND2 file, returning image data and metadata.
            %
            %   Inputs:
            %   - filepath: string/char representing the path to an ND2 
            %       file.
            %
            %   Outputs:
            %   - obj: Numerical array representing image data.
            %   - metadata: Struct containing relevant metadata.

            % Get Bio-Formats reader object.
            f = bfGetReader(filepath); 

            % Initialize metadata struct.
            metadata = struct();

            % Save filepath to metadata.
            metadata.path = filepath;

            % Get datatype from reader object.
            [metadata.bit_depth, ~] = DataHandling.Helpers.nd2.get_datatype;

            % Get voxel resolution from reader object.
            metadata.scale = DataHandling.Helpers.nd2.get_voxel_resolution;

            % Get array dimensions.
            metadata.dimensions = DataHandling.Helpers.nd2.get_dimensions(f);
            
            % Get what channel data we can.
            metadata.channels = DataHandling.Helpers.nd2.get_channels(f);

            % Read file data.
            image_array = bfOpen(filepath); 

            % Obtain image array, which is the first index in the cell
            % array returned by bfOpen.
            image_array = image_array{1};
        end

        function write_obj = convert_to(format, source)
            %CONVERT_TO Convert the nd2 file into a given format.
            %
            %   Inputs:
            %   - format: String/char representing the file format the
            %       Nikon image is to be converted to (e.g. 'npal', 'nwb')
            %   - source: Either String/char representing path to nd2 file
            %       or nd2 reader object.
            %
            %   Outputs:
            %   - new_file: Path to converted file.

            Program.GUI.dialogues.add_task('Converting ND2 file...');
            Program.GUI.dialogues.step('Identifying helper class...');

            % Construct the expected name of requested format's helper
            % class.
            write_class = sprintf("DataHandling.Helpers.%s", format);

            % Check if this class exists.
            if ~exist(write_class, 'class')
                % If it doesn't, raise error.
                error("No helper class found for format %s.", format)
            else
                write_class = eval(write_class);
            end

            % Construct the new path by swapping the given format in
            % for the nd2 substring.
            new_path = strrep(source, 'nd2', format);

            % Get nd2 reader object by calling get_reader.
            Program.GUI.dialogues.step('Generating Nikon reader...');
            source = DataHandling.Helpers.nd2.get_reader(source);
            Program.GUI.dialogues.step('Reading metadata...');

            % Get the datatype of the image array.
            [bit_depth, dtype] = DataHandling.Helpers.nd2.get_datatype(source);

            % Get the dimensions of the image array.
            dims = DataHandling.Helpers.nd2.get_dimensions(source);

            % Get the voxel_resolution of the image array.
            voxel_resolution = DataHandling.Helpers.nd2.get_voxel_resolution(source);

            % Call the helper class's create_file function.
            Program.GUI.dialogues.step('Initializing new file...');
            new_path = write_class.create_file( ...
                new_path, 'dtype', dtype, ...
                'scale', voxel_resolution, ...
                'dims', [dims.x, dims.y, dims.z, dims.c, dims.t]);

            % Get this new file's reader object.
            write_obj = write_class.get_reader(new_path);
            write_obj.Properties.Writable = true;

            % Calculate the maximum possible array size of given system's
            % memory. Note that we limit the maximum chunk size to 90% of
            % the maximum possible array to leave a compute buffer.
            Program.GUI.dialogues.step('Performing memory analysis...');
            if ispc
                % If system is running Windows, use Matlab's memory()
                % function.
                max_arr = memory().MaxPossibleArrayBytes * 0.90;
            else
                % If system is running MacOS/Unix, use system call and
                % parse output.
                [~, max_arr] = system('sysctl hw.memsize | awk ''{print $2}''');
                max_arr = str2double(max_arr) * 0.90;
            end

            % Using the datatype, calculate the bytes occupied by each
            % element within the image array.
            switch dtype
                case 'single'
                    bytes_per_el = 4;
                case 'double'
                    bytes_per_el = 8;
                otherwise
                    bytes_per_el = str2double(dtype(5:end))/8;
            end

            % Calculate the total memory occupied by the image array.
            ttl_bytes = dims.y * dims.x * dims.z * ...
                dims.c * dims.t * bytes_per_el;

            % If the total memory occupied by the image array is smaller
            % than or equal to the maximum possible array size allowed by
            % the system's memory constraints, write plane-wise. Otherwise,
            % write chunk-wise.
            write_planewise = ttl_bytes <= max_arr && ttl_bytes < 1e9;

            if write_planewise
                % If writing plane-wise...
                Program.GUI.dialogues.add_task('Writing without chunking...');
                Program.GUI.dialogues.step('Reading entire Nikon volume...');

                % Get a cell array of all nd2 planes in the file.
                d_cell = bfopen(char(source.getCurrentFile));
                d_cell = d_cell{1};

                % Get the number of planes in the nd2 file.
                n_planes = length(d_cell);

                % Initialize the data array.
                data = zeros(dims.y, dims.x, dims.z, ...
                    dims.c, dims.t, bit_depth);

                % For each plane...
                for pidx = 1:n_planes
                    Program.GUI.dialogues.set_value(pidx/n_planes);

                    % Get the z, c, and t coordinates corresponding to this
                    % plane index.
                    [~, z, c, t] = DataHandling.Helpers.nd2.parse_plane_idx(d_cell{pidx, 2});
                    
                    % Write this plane to the data array, indexing into the
                    % t dimension only if there is more than one frame.
                    if dims.t > 1 
                        Program.GUI.dialogues.step(sprintf( ...
                            'Caching plane %.f/%.f (z = %.f, c = %.f, t = %.f)', ...
                            pidx, n_planes, z, c, t));
                        data(:, :, z, c, t) = d_cell{pidx, 1};

                    else
                        Program.GUI.dialogues.step(sprintf( ...
                            'Caching plane %.f/%.f (z = %.f, c = %.f)', ...
                            pidx, n_planes, z, c));
                        data(:, :, z, c) = d_cell{pidx, 1};
                    end
                end

                % Write data to file.
                Program.GUI.dialogues.step(sprintf( ...
                    'Writing %.f planes to file...', n_planes));
                write_obj.data = data;
                Program.GUI.dialogues.resolve();
                
            else           
                % If writing chunk-wise...
                if dims.t > 1
                    Program.GUI.dialogues.add_task('Writing frame-wise...');
                    % For videos, chunk along the time dimension.
            
                    % Get the number of bytes in one full frame.
                    bytes_per_frame = ttl_bytes / dims.t;

                    % Calculate the maximum number of frames to process at
                    % once.
                    chunk_size_t = max(1, ...
                        floor(max_arr / bytes_per_frame));
            
                    % Initialize the start of our first chunk as frame 1.
                    t_start = 1;

                    % While the first index of our chunks is lower than or
                    % equal to the total number of frames...
                    while t_start <= dims.t

                        % Calculate the end point of our current chunk.
                        t_end = min(t_start + chunk_size_t - 1, dims.t);
                        Program.GUI.dialogues.set_value(t_end/dims.t);
                        Program.GUI.dialogues.step(sprintf( ...
                            'Frames %.f-%.f (out of %.f)', ...
                            t_start, t_end, nt));
            
                        % Read this chunk of frames.
                        this_chunk = DataHandling.Helpers.nd2.get_plane( ...
                            source, ...
                            'x', 1:dims.x, 'y', 1:dims.y, 'z', 1:dims.z, ...
                            'c', 1:dims.c, 't', t_start:t_end);
            
                        % Write this chunk to our new file.
                        write_obj.data(:,:,:,:, t_start:t_end) = this_chunk;
            
                        % Move the chunk window.
                        t_start = t_end + 1;
                    end
            
                else
                    % For images, chunk along the z dimension.
                    Program.GUI.dialogues.add_task('Writing slice-wise...');
            
                    % Get the number of bytes in one z-slice.
                    bytes_per_z_slab = ttl_bytes / dims.z;

                    % Calculate the maximum number of z-slices to process
                    % at once.
                    chunk_size_z = max(1, floor(max_arr / bytes_per_z_slab));
            
                    % Initialize the start of our first chunk as slice 1.
                    z_start = 1;

                    % While the first index of our chunks is lower than or
                    % equal to the total number of z-slices...
                    while z_start <= dims.z

                        % Calculate the end point of our current chunk.
                        z_end = min(z_start + chunk_size_z - 1, dims.z);

                        Program.GUI.dialogues.set_value(z_end/dims.t);
                        Program.GUI.dialogues.step(sprintf( ...
                            'Slices %.f-%.f (out of %.f)', ...
                            z_start, z_end, dims.z));
            
                        % Read this chunk of z-slices.
                        this_chunk = DataHandling.Helpers.nd2.get_plane( ...
                            source, ...
                            'x', 1:dims.x, 'y', 1:dims.y, 'z', z_start:z_end, ...
                            'c', 1:dims.c);

                        this_chunk = cast(this_chunk, dtype);
            
                        % Write this chunk to our new file.
                        write_obj.data(:, :, z_start:z_end, :) = this_chunk;
            
                        % Move the chunk window.
                        z_start = z_end + 1;
                    end
                end
                
                Program.GUI.dialogues.resolve();
            end

            Program.GUI.dialogues.resolve();
        end

        function arr = read(obj, varargin)
            p = inputParser();
    
            addParameter(p, 'z_range',    []);
            addParameter(p, 'c_range',    []);
            addParameter(p, 't_range',    []);
    
            parse(p, varargin{:});

            if isfield(cursor, 'c1') || isprop(cursor, 'c1')
                arr = DataHandling.Helpers.nd2.get_plane( ...
                    obj, ...
                    'z', cursor.z1:cursor.z2, ...
                    'c', cursor.c1:cursor.c2, ...
                    'x', cursor.x1:cursor.x2, ...
                    'y', cursor.y1:cursor.y2);
            else
                arr = DataHandling.Helpers.nd2.get_plane( ...
                    obj, ...
                    'z', cursor.z1:cursor.z2, ...
                    'c', 1:obj.getSizeC, ...
                    'x', cursor.x1:cursor.x2, ...
                    'y', cursor.y1:cursor.y2);
            end
        end

        function np_file = to_npal(file)
            %CONVERTND2 Convert an ND2 file to NeuroPAL format.
            %
            % nd2_file = the ND2 file to convert
            % np_file = the NeuroPAL format file

            Program.GUI.dialogues.add_task('Reading Nikon metadata...');
            f = bfGetReader(file);                                              % Get reader object.

            nx = f.getSizeX;                                                    % Get width.
            ny = f.getSizeY;                                                    % Get height.
            nz = f.getSizeZ;                                                    % Get depth.
            nc = f.getSizeC;                                                    % Get channel count.
            nt = f.getSizeT;                                                    % Get frame count.

            bits = f.getMetadataStore.getPixelsSignificantBits(0).getValue();   % Get bit depth.
            bit_depth = sprintf("uint%.f", bits);                               % Convert bit depth to class string.

            data = [];                                                          % Initialize data as proportionate zero array.

            info = struct('file', {file});                                      % Initialize info struct.
            info.scale = DataHandling.Helpers.nd2.parse_scale(f);               % Set image scale

            info.channel_names = DataHandling.Helpers.nd2.get_channel_names(f);           % Get channel names.
            channels = Program.Handlers.channels.parse_info(info.channel_names);          % Get channel indices from names.
            
            [~, has_duplicate, duplicate_indices] = Program.Validation.check_for_duplicate_fluorophores(channels);
            if has_duplicate && ~isempty(duplicate_indices)
                Program.Handlers.channels.add_reference(info.channel_names{duplicate_indices})
            end

            info.RGBW = arrayfun(@(x) find(channels == x), 1:4, 'UniformOutput', false);                    % Set RGBW indices.
            if iscell(info.RGBW)
                info.RGBW = cell2mat(info.RGBW);
            end

            info.DIC = find(ismember(channels, 5));                             % Set DIC if present, else set to 0.
            if isempty(info.DIC)
                info.DIC = 0;
            end

            info.GFP = find(ismember(channels, 6));                             % Set GFP is present, else set to 0.
            if isempty(info.GFP)
                info.GFP = 0;
            end

            info.bit_depth = bit_depth;
            
            % Determine the gamma.
            info.gamma = Program.Handlers.channels.config{'default_gamma'};     % Set gamma to default since we can't get it from ND2 hashtable.
            
            % Initialize the user preferences.
            prefs.RGBW = info.RGBW;
            prefs.DIC = info.DIC;
            prefs.GFP = info.GFP;
            prefs.gamma = info.gamma;
            prefs.rotate.horizontal = false;
            prefs.rotate.vertical = false;
            prefs.z_center = ceil(nz / 2);
            prefs.is_Z_LR = true;
            prefs.is_Z_flip = true;
            
            % Initialize the worm info.
            worm.body = 'Head';
            worm.age = 'Adult';
            worm.sex = 'XX';
            worm.strain = '';
            worm.notes = '';
            
            % Save the ND2 file to our MAT file format.
            np_file = strrep(file, 'nd2', 'mat');
            version = Program.information.version;
            Program.GUI.dialogues.resolve();

            Program.GUI.dialogues.add_task('Writing metadata...');
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');
            Program.GUI.dialogues.resolve();

            Program.GUI.dialogues.add_task('Running Nikon write routine...');
            DataHandling.Helpers.nd2.write_data(np_file, f);
            Program.GUI.dialogues.resolve();
        end

        function channel_struct = get_channels(reader)            
            channel_struct = struct( ...
                'names', {DataHandling.Helpers.nd2.get_channel_names(reader)}, ...
                'order', {Program.Handlers.channels.parse_order(names)}, ...
                'has_bools', {Program.Handlers.channels.parse_presence(names)});
        end

        function names = get_channel_names(reader)
            names = {};

            if isstring(reader) || ischar(reader)
                reader = bfGetReader(reader);
            end

            for c = 1:reader.getSizeC
                names{end+1} = string(reader.getMetadataStore.getChannelName(0, c - 1));
            end

            names = string(names);
        end


        function [f_nc, f_ch_names, f_ch_order] = channels_from_file(file)
            [~, ~, fmt] = fileparts(file);

            switch fmt
                case '.nd2'
                    f_data = bfopen(file);
                    f_metadata = f_data{cellfun(@(x)isa(x,'java.util.Hashtable'), f_data)};
                    f_metadata_keys = string(f_metadata.keySet.toArray);
                    f_ch_idx = contains(f_metadata_keys, 'Global Name #');
                    f_ch_str = string({f_metadata_keys{f_ch_idx}});
                    f_ch_order = string({f_ch_str{end:-1:1}});
                    f_ch_names = string(cellfun(@(x)f_metadata.get(x), f_ch_order, 'UniformOutput', false));
                    f_ch_names = f_ch_names(f_ch_names~="NA");
                    f_nc = length(f_ch_names);

                    fprintf("File %s contains %.f channels in this order:\n%s\n%s.", file, f_nc, join(f_ch_order, ', '), join(f_ch_names, ', '))

                case '.nwb'
                case '.mat'
            end
        end

        function [sorted_names, permute_record] = autosort(channels)
            Program.GUI.dialogues.add_task('Interpreting channel names...');
            channels = string(channels(:));
            n_names = numel(channels);
        
            f_ch_names_lower = lower(channels);
        
            labels_order = keys(Program.channel_handler.fluorophore_mapping);
        
            labels = strings(n_names, 1);
        
            for j = 1:numel(labels_order)
                key = labels_order{j};
                synonyms = Program.channel_handler.fluorophore_mapping(key);
                synonyms_lower = lower(string(synonyms{1}));
        
                is_match = ismember(f_ch_names_lower, synonyms_lower);
                labels(is_match) = key;
            end
        
            sorted_names = strings(0, 1);
            permute_record = [];
        
            for j = 1:numel(labels_order)
                key = labels_order{j};

                idx = find(labels == key);

                sorted_names = [sorted_names; channels(idx)];
                permute_record = [permute_record; idx];
            end
        
            unmatched_idx = find(labels == "");
            if ~isempty(unmatched_idx)
                sorted_names = [sorted_names; channels(unmatched_idx)];
                permute_record = [permute_record; unmatched_idx];
            end

            Program.GUI.dialogues.resolve();
        end

        function obj = get_plane(file, varargin)
            % GET_PLANE Extract a specific plane or slice from the ND2 file based on the given coordinates.
            %
            % Parameters:
            %   varargin - Input parser options for x, y, z, c, t dimensions.
            %
            % Returns:
            %   obj - Multidimensional array containing image planes.

            if ischar(file) || isstring(file)
                file = Program.GUIPreferences.instance().image_dir;
            end

            % Set up input parser to handle variable input arguments
            p = inputParser;
            addOptional(p, 'x', 1:file.getSizeX);
            addOptional(p, 'y', 1:file.getSizeY);
            addOptional(p, 'z', 1:file.getSizeZ);
            addOptional(p, 'c', 1:file.getSizeC);
            addOptional(p, 't', 1);
            parse(p, varargin{:});
        
            % Determine starting positions for extraction (zero-based)
            x0 = min(p.Results.x);
            y0 = min(p.Results.y);
        
            % Calculate the extraction dimensions
            width = max(p.Results.x);
            height = max(p.Results.y);
        
            % Set the number of planes in each dimension
            numZ = numel(p.Results.z);
            numC = numel(p.Results.c);
            numT = numel(p.Results.t);
        
            % Preallocate array to hold the extracted image planes
            obj = zeros(height, width, numZ, numC, numT, ...
                'like', file.getMetadataStore.getPixelsSignificantBits(0).getValue());
        
            % Loop through z, c, and t indices to retrieve planes
            for idxZ = 1:numZ
                for idxC = 1:numC
                    for idxT = 1:numT
                        % Retrieve coordinates in zero-based format
                        z = p.Results.z(idxZ);
                        c = p.Results.c(idxC);
                        t = max(p.Results.t(idxT), 1);
        
                        % Calculate the index for the specific plane in the reader object
                        planeIndex = file.getIndex(z - 1, c - 1, t - 1) + 1;
        
                        % Retrieve the plane data for the specified index
                        plane = bfGetPlane(file, planeIndex, x0, y0, width, height);
        
                        % Store the retrieved plane in the multidimensional array
                        obj(:, :, idxZ, idxC, idxT) = plane;
                    end
                end
            end
        end
    end

    methods (Static, Access = private)
        function [p, z, c, t] = parse_plane_idx(plane_idx)
            if ~isstring(plane_idx)
                plane_idx = string(plane_idx);
            end

            p = str2double(regexp(plane_idx, 'plane\s+(\d+)/\d+', 'tokens', 'once'));
            z = str2double(regexp(plane_idx, 'Z=(\d+)/\d+', 'tokens', 'once'));
            c = str2double(regexp(plane_idx, 'C=(\d+)/\d+', 'tokens', 'once'));
            t = str2double(regexp(plane_idx, 'T=(\d+)/\d+', 'tokens', 'once'));
        end

        function write_data(np_file, nd2_reader)
            Program.GUI.dialogues.step('Performing pre-write memory analysis...');
            np_write = matfile(np_file, "Writable", true);
        
            nx = nd2_reader.getSizeX;
            ny = nd2_reader.getSizeY;
            nz = nd2_reader.getSizeZ;
            nc = nd2_reader.getSizeC;
            nt = nd2_reader.getSizeT;
        
            % Maximum memory to use for a single chunk:
            if ispc
                max_arr = memory().MaxPossibleArrayBytes * 0.90;
            else
                [~, max_arr] = system('sysctl hw.memsize | awk ''{print $2}''');
                max_arr = str2double(max_arr) * 0.90;
            end
        
            % Determine the data class from config:
            dclass = Program.config.defaults{'class'};

            % Pre-allocate the entire output in the MAT-file:
            np_write.data = zeros(ny, nx, nz, nc, nt, dclass);
        
            switch dclass
                case 'single'
                    bytes_per_el = 4;
                case 'double'
                    bytes_per_el = 8;
                otherwise
                    bytes_per_el = str2double(dclass(5:end))/8;
            end

            ttl_bytes = ny * nx * nz * nc * nt * bytes_per_el;

            if ttl_bytes <= max_arr
                Program.GUI.dialogues.step('Reading entire Nikon volume...');
                d_cell = bfopen(char(source.getCurrentFile));

                d_cell = d_cell{1};
                n_planes = length(d_cell);
                data = zeros(ny, nx, nz, nc, nt, dclass);

                for pidx = 1:n_planes
                    Program.GUI.dialogues.set_value(pidx/n_planes);
                    [~, z, c, t] = DataHandling.Helpers.nd2.parse_plane_idx(d_cell{pidx, 2});
                    
                    if nt > 1 
                        Program.GUI.dialogues.step(sprintf( ...
                            'Caching plane %.f/%.f (z = %.f, c = %.f, t = %.f)', ...
                            pidx, n_planes, z, c, t));
                        data(:, :, z, c, t) = d_cell{pidx, 1};

                    else
                        Program.GUI.dialogues.step(sprintf( ...
                            'Caching plane %.f/%.f (z = %.f, c = %.f)', ...
                            pidx, n_planes, z, c));
                        data(:, :, z, c) = d_cell{pidx, 1};
                    end
                end

                Program.GUI.dialogues.step(sprintf( ...
                    'Writing %.f planes to file...', n_planes));
                np_write.data = data;
                
            else                
                if nt > 1
                    % --- For movies (nt > 1), chunk along the time dimension. ---
            
                    % Number of bytes in one full frame: (ny x nx x nz x nc)
                    bytes_per_frame = ttl_bytes / nt;

                    % Calculate how many frames to process at once:
                    chunk_size_t = max(1, floor(max_arr / bytes_per_frame));
            
                    t_start = 1;
                    while t_start <= nt
                        t_end = min(t_start + chunk_size_t - 1, nt);
                        Program.GUI.dialogues.set_value(t_end/nt);
                        Program.GUI.dialogues.step(sprintf( ...
                            'Frames %.f-%.f (out of %.f)', ...
                            t_start, t_end, nt));
            
                        % Read multiple frames in one go:
                        this_chunk = DataHandling.Helpers.nd2.get_plane( ...
                            nd2_reader, ...
                            'x', 1:nx, 'y', 1:ny, 'z', 1:nz, ...
                            'c', 1:nc, 't', t_start:t_end);
            
                        % Convert class and assign to MAT-file:
                        np_write.data(:,:,:,:, t_start:t_end) = ...
                            DataHandling.Types.to_standard(this_chunk);
            
                        % Move chunk window
                        t_start = t_end + 1;
                    end
            
                else
                    % --- Single time point: chunk along the z dimension. ---
            
                    % Number of bytes in one z-slab: (ny x nx x nc)
                    bytes_per_z_slab = ttl_bytes / nz;
                    % Calculate how many z-planes we can process at once:
                    chunk_size_z = max(1, floor(max_arr / bytes_per_z_slab));
            
                    z_start = 1;
                    while z_start <= nz
                        z_end = min(z_start + chunk_size_z - 1, nz);

                        Program.GUI.dialogues.set_value(z_end/nt);
                        Program.GUI.dialogues.step(sprintf( ...
                            'Slices %.f-%.f (out of %.f)', ...
                            z_start, z_end, nz));
            
                        % Read a chunk of z-slices:
                        this_chunk = DataHandling.Helpers.nd2.get_plane( ...
                            nd2_reader, ...
                            'x', 1:nx, 'y', 1:ny, 'z', z_start:z_end, ...
                            'c', 1:nc);
            
                        % Convert class and assign to MAT-file:
                        np_write.data(:,:, z_start:z_end, :) = ...
                            DataHandling.Types.to_standard(this_chunk);
            
                        % Move chunk window
                        z_start = z_end + 1;
                    end
                end
            end
        end

        function scale = parse_scale(reader, pfx)
            key_map = DataHandling.Helpers.nd2.key_map;

            if ~exist('pfx', 'var')
                xy_scale = DataHandling.Helpers.nd2.get_keys(reader, key_map('xy_scale'), 'globals');
                z_scale = DataHandling.Helpers.nd2.get_keys(reader, key_map('z_scale'), 'globals');

                if isempty(xy_scale) || isempty(z_scale)
                    DataHandling.Helpers.nd2.parse_scale(reader, 'Global ');
                end

            else
                xy_scale = DataHandling.Helpers.nd2.get_keys(reader, sprintf("%s %s", pfx, key_map('xy_scale')), 'globals');
                z_scale = DataHandling.Helpers.nd2.get_keys(reader,  sprintf("%s %s", pfx, key_map('xy_scale')), 'globals');

            end

            if isempty(xy_scale) || isempty(z_scale)
                scale = [0 0 0];

            else
                scale = [ ...
                    str2num(xy_scale) ...
                    str2num(xy_scale) ...
                    str2num(z_scale)];
                
            end
        end

        function obj = get_keys(reader, query, scope)
            % GET_KEYS Retrieve specific keys from the file metadata.
            %
            % Parameters:
            %   file - File reader object.
            %   query - Query string for key matching.
            %   scope - Scope ('globals' or 'series') for metadata search.
            %
            % Returns:
            %   obj - Metadata values corresponding to the queried keys.

            if iscell(query)
                query = query{1};
            end

            [globals, series] = DataHandling.Helpers.nd2.parse_keys(reader); % Parse metadata into globals and series.
            keys = struct('globals', {fieldnames(globals)}, 'series', {fieldnames(series)}); % Structure for keys.

            % Handle optional 'scope' argument
            if ~exist('scope', 'var')
                % Default case returns both global and series keys
                obj = struct( ...
                    'globals', {DataHandling.Helpers.nd2.get_keys(reader, query, 'globals')}, ...
                    'series', {DataHandling.Helpers.nd2.get_keys(reader, query, 'series')});
                return
            end

            % Retrieve and process keys within the specified scope
            target_keys = keys.(scope);
            idx = contains(target_keys, DataHandling.Helpers.java.to_valid(query)); % Match query to keys.
            str = string(target_keys(idx));
            order = string({str{end:-1:1}}); % Reverse order for certain operations.

            % Extract values based on scope and matched keys
            switch scope
                case 'globals'
                    values = string(cellfun(@(x)globals.(x), order, 'UniformOutput', false));
                case 'series'
                    values = string(cellfun(@(x)series.(x), order, 'UniformOutput', false));
            end

            % Filter out any "NA" values
            obj = values(values ~= "NA");
        end

        function [globals, series] = parse_keys(reader)
            % PARSE_KEYS Parse global and series metadata tables if not already parsed.
            %
            % Parameters:
            %   file - File reader object containing metadata.
            %
            % Returns:
            %   globals - Parsed global metadata table.
            %   series - Parsed series metadata table.

            persistent g_table % Persistent global metadata table
            persistent s_table % Persistent series metadata table

            % Parse global metadata only if not already done
            if isempty(g_table)
                g_table = DataHandling.Helpers.java.parse_hashtable(reader.getGlobalMetadata);
            end

            % Parse series metadata only if not already done
            if isempty(s_table)
                s_table = DataHandling.Helpers.java.parse_hashtable(reader.getSeriesMetadata);
            end

            globals = g_table;
            series = s_table;
        end
    end
end