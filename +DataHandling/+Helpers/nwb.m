classdef nwb
    
    properties (Access = public, Constant)
    end
    
    methods (Static)
        %% New (mat.m Inspired)
        % This section contains refactored methods designed to mirror the
        % interface of the 'mat.m' helper for consistency.

        function create(path, dims, dtype, metadata)
            % CREATE - Creates a new NWB file with a placeholder for a data array.
            % Assumes input dims are in the application's standard order: [ny, nx, nz, nc, nt].
            
            fprintf('Creating NWB file at: %s\n', path);

            % NWB requires some boilerplate metadata
            nwb_file = NwbFile( ...
                'session_description', 'session created for data storage', ...
                'identifier', char(java.util.UUID.randomUUID()), ...
                'session_start_time', datetime('now'));

            device = types.core.Device( ...
                'description', 'Microscope or acquisition device.', ...
                'manufacturer', 'Unknown');
            nwb_file.general_devices.set('Device', device);

            optical_channel = types.core.OpticalChannel( ...
                'description', 'An optical channel.', ...
                'emission_lambda', NaN);

            % Fix the SoftLink warning by creating proper reference
            device_link = types.untyped.SoftLink(device);
            
            imaging_plane = types.core.ImagingPlane( ...
                'description', 'The plane of imaging.', ...
                'device', device_link, ...
                'optical_channel', optical_channel, ...
                'imaging_rate', 1.0, ...
                'excitation_lambda', NaN, ...
                'indicator', 'n.a.', ...
                'location', 'n.a.');
            nwb_file.general_optophysiology.set('ImagingPlane', imaging_plane);

            % Extract individual dimensions
            ny = dims(1); nx = dims(2); nz = dims(3); nc = dims(4); nt = dims(5);
            
            % NWB ImageSeries expects dimensions in order: [frame, x, y] or [frame, x, y, z]
            % Since we have 5D data [ny, nx, nz, nc, nt], we need to decide how to map this
            
            % Always use the same consistent mapping for all cases:
            % NWB format: [total_frames, nx, ny, nz] where total_frames = nc * nt
            % This ensures consistency between create/write/read operations
            total_frames = nc * nt;
            nwb_dims = [total_frames, nx, ny, nz];
            initial_data = zeros(nwb_dims, dtype);
            timestamps = linspace(0, (total_frames-1)/1.0, total_frames);
            
            fprintf('Mapping: App dims [ny=%d, nx=%d, nz=%d, nc=%d, nt=%d] -> NWB dims [%d, %d, %d, %d]\n', ...
                ny, nx, nz, nc, nt, total_frames, nx, ny, nz);

            fprintf('Creating ImageSeries with dimensions: %s\n', mat2str(nwb_dims));

            data_pipe = types.untyped.DataPipe( ...
                'data', initial_data, ...
                'maxSize', nwb_dims);

            image_series = types.core.ImageSeries( ...
                'data', data_pipe, ...
                'description', 'Main data array', ...
                'timestamps', timestamps, ...
                'data_unit', 'n.a.');

            nwb_file.acquisition.set('MainImageSeries', image_series);
            
            % Store original dimensions and metadata in NWB file
            % We need to preserve the original [ny, nx, nz, nc, nt] dimensions for proper reconstruction
            
            % Store dimensions as a custom field in the ImageSeries description
            dims_str = sprintf('ORIG_DIMS:[%d,%d,%d,%d,%d]', ny, nx, nz, nc, nt);
            
            if exist('metadata', 'var') && isstruct(metadata)
                % Store user metadata in session_description field
                if isfield(metadata, 'experiment')
                    nwb_file.session_description = [nwb_file.session_description, ' - Experiment: ', metadata.experiment];
                end
                if isfield(metadata, 'subject_id')
                    nwb_file.session_description = [nwb_file.session_description, ' - Subject: ', metadata.subject_id];
                end
                
                % Add dimensions to description
                image_series.description = [image_series.description, ' - ', dims_str];
            else
                % Just store dimensions
                image_series.description = [image_series.description, ' - ', dims_str];
            end

            nwbExport(nwb_file, path);
            fprintf('Successfully created NWB file.\n');
        end

        function write(file, arr, varargin)
            % WRITE - Writes an array to the NWB file by rewriting the file.
            
            p = inputParser();
            addRequired(p, 'file');
            addRequired(p, 'arr');
            addParameter(p, 'cursor', []);
            parse(p, file, arr, varargin{:});

            fprintf('Reading NWB file for writing...\n');
            
            % Check if file exists first
            if ~exist(p.Results.file, 'file')
                error('NWB file does not exist: %s', p.Results.file);
            end
            
            nwb_obj = nwbRead(p.Results.file);

            main_var = DataHandling.Helpers.nwb.find_main_series(nwb_obj);
            if isempty(main_var)
                error('No main data series found in the acquisition group to write to.');
            end
            
            fprintf('Found data object. Rewriting data...\n');
            
            % Get array dimensions
            arr_dims = size(p.Results.arr);
            fprintf('Input array dimensions: %s\n', mat2str(arr_dims));
            
            % Handle different dimensionality cases
            if length(arr_dims) == 4
                % 4D array [ny, nx, nz, nc] - add singleton time dimension
                corrected_arr = permute(p.Results.arr, [5, 2, 1, 3, 4]); % [t, x, y, z, c] 
                corrected_arr = reshape(corrected_arr, [1, arr_dims(2), arr_dims(1), arr_dims(3), arr_dims(4)]);
            elseif length(arr_dims) == 5
                % 5D array [ny, nx, nz, nc, nt] - this is the standard app order
                % We need to reshape it to match the flattened frames dimension used in create()
                
                % Permute to [nc, nt, nx, ny, nz] to get nc and nt next to each other
                corrected_arr = permute(p.Results.arr, [4, 5, 2, 1, 3]);
                
                % Reshape to flatten the first two dimensions (nc and nt) into a single frame dimension
                % This creates an array of shape [total_frames, nx, ny, nz]
                corrected_arr = reshape(corrected_arr, [arr_dims(4) * arr_dims(5), arr_dims(2), arr_dims(1), arr_dims(3)]);

                fprintf('Corrected array dimensions for NWB: %s\n', mat2str(size(corrected_arr)));
            else
                error('Unsupported array dimensions: %d. Expected 4D or 5D array.', length(arr_dims));
            end
            
            % *** THE FIX: DIRECTLY ASSIGN THE DATA ***
            % The MatNWB library requires you to overwrite the data in place
            % rather than replacing the entire DataPipe object.
            main_var.data = corrected_arr; 

            nwbExport(nwb_obj, p.Results.file);
            fprintf('Write complete.\n');
        end

        function obj = get_reader(path)
            % GET_READER - Returns a reader object for an NWB file.
            if ~endsWith(path, '.nwb')
                error('Non-nwb file passed to nwb.get_reader function: \n%s', path)
            end
            obj = nwbRead(path);
        end

        function metadata = get_metadata(obj, varargin)
            % GET_METADATA - Extracts basic metadata from an NWB file.
            
            if ischar(obj) || isstring(obj)
                obj = DataHandling.Helpers.nwb.get_reader(obj);
            end

            main_var = DataHandling.Helpers.nwb.find_main_series(obj);
            if isempty(main_var)
                error('No main data series found in the acquisition group to get metadata from.');
            end
            
            % FIX: Use the correct property to get dimensions based on the object type
            if isprop(main_var.data, 'maxSize')
                 % This handles the DataPipe object before writing
                nwb_dims = main_var.data.maxSize;
            elseif isprop(main_var.data, 'dims')
                % This handles the DataStub object after reading from disk
                nwb_dims = main_var.data.dims;
            else
                % Fallback
                nwb_dims = size(main_var.data);
            end
            
            % Try to extract original dimensions from the description field
            orig_dims = [];
            if isprop(main_var, 'description') && ~isempty(main_var.description)
                % Look for ORIG_DIMS:[ny,nx,nz,nc,nt] pattern in description
                pattern = 'ORIG_DIMS:\[(\d+),(\d+),(\d+),(\d+),(\d+)\]';
                tokens = regexp(main_var.description, pattern, 'tokens');
                if ~isempty(tokens)
                    orig_dims = cellfun(@str2double, tokens{1});
                    fprintf('Found original dimensions in metadata: [%d,%d,%d,%d,%d]\n', orig_dims);
                end
            end
            
            % Handle different dimension orders based on data type and stored metadata
            if ~isempty(orig_dims)
                % Use the stored original dimensions
                native_dims = orig_dims;
            elseif isa(main_var, 'types.ndx_multichannel_volume.MultiChannelVolumeSeries')
                % This type often uses [ny, nx, nz, nc, t]
                native_dims = nwb_dims;
            elseif isa(main_var, 'types.core.TwoPhotonSeries') && length(nwb_dims) == 3
                % Ophys standard is often [ny, nx, t]
                native_dims = [nwb_dims(1), nwb_dims(2), 1, 1, nwb_dims(3)]; % ny, nx, nz, nc, nt
            else
                % Assume our standard [t, ny, nx, nz, nc] and convert back
                % But ensure we have enough dimensions
                if length(nwb_dims) >= 5
                    native_dims = nwb_dims([2, 3, 4, 5, 1]); % ny, nx, nz, nc, t
                elseif length(nwb_dims) == 4
                    native_dims = [nwb_dims(2), nwb_dims(3), nwb_dims(4), 1, nwb_dims(1)]; % ny, nx, nz, nc=1, t
                else
                    % Default fallback
                    native_dims = [nwb_dims, ones(1, 5-length(nwb_dims))];
                end
            end
            
            % Ensure native_dims has at least 5 elements
            if length(native_dims) < 5
                native_dims = [native_dims, ones(1, 5-length(native_dims))];
            end

            % Determine the data type string based on the object's class
            if isa(main_var, 'types.ndx_multichannel_volume.MultiChannelVolumeSeries')
                % This extension class stores the data type in the '.data.dataType' property
                if isprop(main_var.data, 'dataType')
                    dtype_str = main_var.data.dataType;
                else
                    dtype_str = 'unknown';
                end
            else
                % Standard NWB classes store it in the '.datatype' property
                if isprop(main_var, 'datatype')
                    dtype_str = main_var.datatype;
                else
                    dtype_str = 'unknown';
                end
            end

            metadata = struct( ...
                'nx', native_dims(2), ...
                'ny', native_dims(1), ...
                'nz', native_dims(3), ...
                'nc', native_dims(4), ...
                'nt', native_dims(5), ...
                'native_dims', native_dims, ...
                'dtype_str', dtype_str);
        end

        function arr = read(obj, varargin)
            % READ - Reads data from an NWB file, supporting chunked reading.
            % 
            % IMPORTANT: Due to limitations in matnwb's DataStub implementation,
            % chunked reading may fail with "END" errors. In such cases,
            % this method falls back to loading full data and subsetting.
            
            p = inputParser();
            addRequired(p, 'obj');
            addParameter(p, 'cursor', []);
            addParameter(p, 'mode', 'chunk');
            parse(p, obj, varargin{:});

            cursor = p.Results.cursor;

            main_var = DataHandling.Helpers.nwb.find_main_series(p.Results.obj);
            if isempty(main_var)
                error('No main data series found to read from.');
            end

            % If mode is 'full' or cursor is empty, load everything.
            if strcmp(p.Results.mode, 'full') || isempty(cursor) || all(structfun(@isempty, cursor))
                arr = main_var.data.load();
                
                % FIX: Correctly reverse the reshaping and permutation from the write function.
                % The data is stored in the NWB file as a 4D array: [total_frames, nx, ny, nz].
                % We need to reshape it back to the 5D app format: [ny, nx, nz, nc, nt].
                if isa(main_var, 'types.core.ImageSeries')
                    % Get the original dimensions from metadata to reconstruct properly
                    metadata = DataHandling.Helpers.nwb.get_metadata(p.Results.obj);
                    
                    % The data is stored as [total_frames, nx, ny, nz] where total_frames = nc * nt
                    % We need to reshape it back to [ny, nx, nz, nc, nt]
                    total_frames = size(arr, 1);
                    nx_stored = size(arr, 2);
                    ny_stored = size(arr, 3);
                    nz_stored = size(arr, 4);
                    
                    fprintf('Read data size: [%d, %d, %d, %d]\n', total_frames, nx_stored, ny_stored, nz_stored);
                    fprintf('Target metadata: nc=%d, nt=%d, nx=%d, ny=%d, nz=%d\n', ...
                        metadata.nc, metadata.nt, metadata.nx, metadata.ny, metadata.nz);
                    
                    % Reshape from [total_frames, nx, ny, nz] to [nc, nt, nx, ny, nz]
                    if total_frames == (metadata.nc * metadata.nt) && metadata.nc > 0 && metadata.nt > 0
                        reshaped_arr = reshape(arr, [metadata.nc, metadata.nt, nx_stored, ny_stored, nz_stored]);
                        % Permute to get the final application order: [ny, nx, nz, nc, nt]
                        arr = permute(reshaped_arr, [4, 3, 5, 1, 2]);
                        fprintf('Successfully reconstructed to app format: %s\n', mat2str(size(arr)));
                    else
                        fprintf('Warning: Cannot reshape - total_frames mismatch. Using fallback.\n');
                        % Fallback: assume single timepoint or single channel
                        if ndims(arr) == 4
                            arr = permute(arr, [3, 2, 4, 1]); % [ny, nx, nz, t]
                            arr = reshape(arr, [size(arr, 1), size(arr, 2), size(arr, 3), 1, size(arr, 4)]); % Add singleton nc dimension
                        end
                    end
                end

                return;
            end
            
            % --- CHUNKED READ WITH FALLBACK STRATEGY ---
            % Due to DataStub END indexing issues, we implement a fallback approach
            
            fprintf('Attempting chunked read...\n');
            
            try
                % Method 1: Try direct chunked loading (may fail with END error)
                arr = DataHandling.Helpers.nwb.attempt_direct_chunk_read(main_var, cursor);
                fprintf('Direct chunked read successful.\n');
                return;
                
            catch direct_error
                % Check if it's the known END error
                if contains(direct_error.message, 'END')
                    fprintf('Direct chunked read failed due to DataStub END issue.\n');
                    fprintf('Falling back to full read + subset method...\n');
                    
                    % Method 2: Fallback - load full data and subset
                    try
                        full_arr = main_var.data.load();
                        
                        % Apply appropriate permutation if needed
                        if ~isa(main_var, 'types.ndx_multichannel_volume.MultiChannelVolumeSeries')
                            % Get the original dimensions from metadata to reconstruct properly
                            metadata = DataHandling.Helpers.nwb.get_metadata(p.Results.obj);

                            % The data is stored as [total_frames, nx, ny, nz] where total_frames = nc * nt
                            % We need to reshape it back to [ny, nx, nz, nc, nt]
                            total_frames = size(full_arr, 1);
                            
                            % Reshape from [total_frames, nx, ny, nz] to [nc, nt, nx, ny, nz]
                            if total_frames == (metadata.nc * metadata.nt) && metadata.nc > 0 && metadata.nt > 0
                                reshaped_arr = reshape(full_arr, [metadata.nc, metadata.nt, size(full_arr, 2), size(full_arr, 3), size(full_arr, 4)]);
                                % Permute to get the final application order: [ny, nx, nz, nc, nt]
                                full_arr = permute(reshaped_arr, [4, 3, 5, 1, 2]);
                            else
                                % Fallback: assume single timepoint or single channel
                                if ndims(full_arr) == 4
                                    full_arr = permute(full_arr, [3, 2, 4, 1]); % [ny, nx, nz, t]
                                    full_arr = reshape(full_arr, [size(full_arr, 1), size(full_arr, 2), size(full_arr, 3), 1, size(full_arr, 4)]); % Add singleton nc dimension
                                end
                            end
                        end
                        
                        % Extract the requested chunk from full data
                        arr = DataHandling.Helpers.nwb.subset_full_data(full_arr, cursor);
                        fprintf('Fallback chunked read successful.\n');
                        return;
                        
                    catch fallback_error
                        % If fallback also fails, re-throw original error with context
                        error('nwb.read:ChunkedReadFailed', ...
                            'Both direct chunked read and fallback method failed.\nDirect error: %s\nFallback error: %s', ...
                            direct_error.message, fallback_error.message);
                    end
                else
                    % If it's not an END error, re-throw the original error
                    rethrow(direct_error);
                end
            end
        end
        
        function arr = attempt_direct_chunk_read(main_var, cursor)
            % ATTEMPT_DIRECT_CHUNK_READ - Try to read a chunk directly from DataStub
            % This method often fails with "END" errors due to matnwb limitations
            
            % Build indexing arrays for direct DataStub access
            % Note: DataStub uses 1-based indexing like MATLAB
            
            % Try to get data dimensions from the DataStub
            if isprop(main_var.data, 'dims')
                data_dims = main_var.data.dims;
            else
                % If we can't get dims, this method will likely fail anyway
                error('Cannot determine data dimensions for direct chunk read');
            end
            
            % Build the indexing cell array
            indices = cell(1, length(data_dims));
            
            % Map cursor to indices based on expected dimension order
            % Assuming stored as [frames, x, y, z] in NWB
            if length(data_dims) >= 4
                indices{1} = ':'; % All frames for now
                indices{2} = cursor.x1:min(cursor.x2, data_dims(2));
                indices{3} = cursor.y1:min(cursor.y2, data_dims(3));
                indices{4} = cursor.z1:min(cursor.z2, data_dims(4));
            elseif length(data_dims) == 3
                indices{1} = ':'; % All frames
                indices{2} = cursor.x1:min(cursor.x2, data_dims(2));
                indices{3} = cursor.y1:min(cursor.y2, data_dims(3));
            else
                error('Unsupported data dimensions for direct chunk read: %d', length(data_dims));
            end
            
            % Attempt the direct read (this often fails with END errors)
            arr = main_var.data.load(indices{:});
        end
        
        function arr = subset_full_data(full_data, cursor)
            % SUBSET_FULL_DATA - Extract a chunk from already-loaded full data
            
            % Get data size
            data_size = size(full_data);
            
            % Build indexing arrays, ensuring we don't exceed bounds
            y_idx = cursor.y1:min(cursor.y2, data_size(1));
            x_idx = cursor.x1:min(cursor.x2, data_size(2));
            
            if length(data_size) >= 3
                z_idx = cursor.z1:min(cursor.z2, data_size(3));
            else
                z_idx = 1;
            end
            
            if length(data_size) >= 4
                c_idx = cursor.c1:min(cursor.c2, data_size(4));
            else
                c_idx = 1;
            end
            
            if length(data_size) >= 5 && isfield(cursor, 't1') && isfield(cursor, 't2')
                t_idx = cursor.t1:min(cursor.t2, data_size(5));
            else
                t_idx = ':';  % Use all time points if available
            end
            
            % Extract the subset
            if length(data_size) == 4
                arr = full_data(y_idx, x_idx, z_idx, c_idx);
            elseif length(data_size) == 5
                if strcmp(t_idx, ':')
                    arr = full_data(y_idx, x_idx, z_idx, c_idx, :);
                else
                    arr = full_data(y_idx, x_idx, z_idx, c_idx, t_idx);
                end
            else
                error('Unsupported data dimensions for subsetting: %d', length(data_size));
            end
        end
        
        function series_obj = find_main_series(nwb_obj)
            % FIND_MAIN_SERIES - A helper to locate the primary data series in an NWB file.
            series_obj = [];
            if isempty(nwb_obj.acquisition)
                return;
            end
            
            acq_keys = keys(nwb_obj.acquisition);
            
            % Search in order of specificity.
            search_order = {
                'types.ndx_multichannel_volume.MultiChannelVolumeSeries', ...
                'types.core.TwoPhotonSeries', ...
                'types.core.ImageSeries'
            };
            
            for i = 1:length(search_order)
                current_type = search_order{i};
                for j = 1:length(acq_keys)
                    item = nwb_obj.acquisition.get(acq_keys{j});
                    if isa(item, current_type)
                        series_obj = item;
                        return;
                    end
                end
            end
        end
    end
end