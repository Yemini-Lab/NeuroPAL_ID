classdef npal
    % NPAL Class for handling, reading, and writing metadata and images
    %   from mat files that utilize NeuroPAL_ID's standardized format.

    properties (Access = public, Constant)
    end
    
    methods (Static)
        function bool = is_npal_file(path)
            %IS_NPAL_FILE Returns a boolean describing whether a given file
            %   matches what we would expect from a NeuroPAL_ID file.
            %
            %   Inputs:
            %   - path: String/char representing the filepath of the file.
            %
            %   Outputs:
            %   - bool: Boolean that is true if the file follows the
            %       NeuroPAL_ID format and false if it does not.

            % Get file name and file extension.
            [~, fname, fmt] = fileparts(path);

            % Check whether this is a mat file.
            is_mat_file = strcmp(fmt, '.mat');

            if is_mat_file
                % If it is, generate a reader object.
                reader = matfile(path);

            else
                % If it isn't, set bool to false and return.
                bool = 0;
                return
            end

            % Check whether file name includes "-NPAL". Not implemented in
            % master branch.
            %is_npal_name = endsWith(fname, '-NPAL');

            % Define the properties we would expect to be present in a
            % NeuroPAL_ID file.
            expected_fields = {'prefs', 'info', 'data'};

            % Check whether the file features these properties.
            has_expected_fields = cellfun(@(x)(isprop(reader, x)), ...
                expected_fields);
            
            % If all expected fields are present, set bool to true.
            % Otherwise, set it to false.
            bool = all(has_expected_fields);
        end

        function path = create_file(path, varargin)
            %CREATE_FILE Initializes a file in the NeuroPAL_ID format
            %   and saves it. This is useful for cases in which we need a
            %   file to be present but don't want to write the entire image
            %   array all at once.
            %
            %   Inputs:
            %   - path: String/char representing the path of the file to be
            %       created.
            %   - varargin: Cell array of sequential key-value pairs which
            %       represent variable input arguments. See parser below 
            %       for further details.

            % Initiate inputParser object, which facilitates key-value
            % parsing of varargin.
            p = inputParser();

            % Initialize expected optional parameters & define their
            % default values should no parameter have been passed.
            addParameter(p, 'like', []);                    % img_vid_volume object to be used as a template.

            addParameter(p, 'dims', []);                    % Expected dimensions of the image array.
            addParameter(p, 'dtype', []);                   % Expected datatype of the image array.
            addParameter(p, 'scale', []);                   % Voxel resolution of the image array.

            addParameter(p, 'rgbw', 1:4);                    % Expected datatype of the image array.
            addParameter(p, 'dic', 0);                     % Expected datatype of the image array.
            addParameter(p, 'gfp', 0);                     % Expected datatype of the image array.
            addParameter(p, 'gammas', repmat(0.8, [1 4]));                  % Expected datatype of the image array.

            %addParameter(p, 'version', 'legacy');           % String/char representing target version of the file. Not implemented on master branch.

            % Parse varargin with the parameters specified above.
            parse(p, varargin{:});

            path = strrep(path, '.npal', '.mat');

            % Initialize struct that will ultimately be saved to mat file.
            fstruct = struct();
            
            if ~isempty(p.Results.like)
                % If a template volume was passed, extract template from 
                % parser so we don't need to index.
                template = p.Results.like;

                % Get dims from template's dims property.
                dims = template.dims;

                % Get dtype from template's dtype_str property.
                dtype = template.dtype_str;

                % Get RGBW indices from template's rgbw property.
                rgbw = template.get('rgbw');

                % Get DIC index from template dic property.
                dic = template.get('dic');

                % Get GFP index from template's gfp property.
                gfp = template.get('gfp');

                % Get gammas from template's gamma property.
                gammas = template.get('gammas');

                % Get voxel resolution from template's device property.
                voxel_resolution = template.device.voxel_resolution;

                % Construct worm struct from template's subject property.
                worm = struct( ...
                    'age', {template.subject.age}, ...
                    'sex', {template.subject.sex}, ...
                    'body', {template.subject.body}, ...
                    'strain', {template.subject.strain}, ...
                    'notes', {template.subject.notes});
                
            else
                % Get dtype from parser.
                dtype = p.Results.dtype;

                % Get dims from parser.
                dims = p.Results.dims;

                % Get voxel resolution from parser.
                voxel_resolution = p.Results.scale;

                rgbw = p.Results.rgbw;
                dic = p.Results.dic;
                gfp = p.Results.gfp;
                gammas = p.Results.gammas;

                worm = struct();
                worm.body = 'Head';
                worm.age = 'Adult';
                worm.sex = 'XX';
                worm.strain = '';
                worm.notes = '';
            end 

            % Initialize a cell array describing the properties we
            % absolutely require for file creation.
            required_properties = { ...
                'rgbw', 'dic', 'gfp', 'gammas', ...
                'voxel_resolution', 'worm'};

            % Check whether each of these properties are present.
            have_required_properties = [cellfun(@(x)(exist(x, 'var')), ...
                required_properties)];

            if any(~have_required_properties)
                % If we have values for all required properties...

                % Initialize info struct.
                fstruct.info = struct( ...
                    'file', {path}, ...
                    'DIC', {dic}, ...
                    'GFP', {gfp}, ...
                    'RGBW', {rgbw}, ...
                    'gamma', {gammas}, ...
                    'scale', {voxel_resolution});
    
                % Initialize prefs struct.
                fstruct.prefs = struct( ...
                    'DIC', {dic}, ...
                    'GFP', {gfp}, ...
                    'RGBW', {rgbw}, ...
                    'rotate', {[]}, ...
                    'z_center', {ceil(dims(3) / 2)}, ...
                    'is_Z_LR', 1, ...
                    'is_Z_flip', 1);
                fstruct.prefs.rotate.horizontal = false;
                fstruct.prefs.rotate.vertical = false;

                % Initialize worm field.
                fstruct.worm = worm;

                % Initialize data field with zero array.
                fstruct.data = zeros(dims, dtype);
                fstruct.version = 2.0;

                % Save the struct to file. Note that use a -v7.3 flag in
                % our save command to ensure that the resulting mat file is
                % compatible with Matlab's matfile() function, which
                % generates reader object that support lazy loading.
                save(path, '-struct', 'fstruct', '-v7.3');

            else
                % If we are missing values for any required properties,
                % raise an error.
                error("Failed to create NPAL file due to missing " + ...
                    "properties: %s", ...
                    required_properties{~have_required_properties})
            end
        end

        function set_metadata(reader, varargin)
            % Initiate inputParser object, which facilitates key-value
            % parsing of varargin.
            p = inputParser();

            % Initialize expected optional parameters & define their
            % default values should no parameter have been passed.          
            addParameter(p, 'voxel_resolution', []);                        
            addParameter(p, 'rgbw', []);                        
            addParameter(p, 'dic', []);                        
            addParameter(p, 'gfp', []);                        

            % Parse varargin with the parameters specified above.
            parse(p, varargin{:});
            metadata_to_write = rmfield(p.Results, p.UsingDefaults);
            metadata_passed = fieldnames(metadata_to_write);

            reader.Writeable = true;
            for m=1:length(metadata_passed)
                property_to_write = metadata_passed{m};
                value_to_write = metadata_to_write.(property_to_write);
                
                switch property_to_write
                    case {'rgbw', 'dic', 'gfp'}
                        info = reader.info;
                        prefs = reader.prefs;

                        info.(property_to_write) = value_to_write;
                        prefs.(property_to_write) = value_to_write;

                    case 'voxel_resolution'
                        info = reader.info;
                        info.scale = value_to_write;
                        reader.info = info;
                end
            end

            reader.Writeable = false;
        end

        function write_to_file(array, path, varargin)
            % Initiate inputParser object, which facilitates key-value
            % parsing of varargin.
            p = inputParser();

            % Initialize expected optional parameters & define their
            % default values should no parameter have been passed.
            addParameter(p, 'lazy_flag', 1);                     % Boolean indicating whether to write chunk-wise.
            addParameter(p, 'z_range', []);                      % 1x2 numerical array representing the chunk of data along the z dimension to which the array is to be written.
            addParameter(p, 't_range', []);                      % 1x2 numerical array representing the chunk of data along the t dimension to which the array is to be written.

            % Parse varargin with the parameters specified above.
            parse(p, varargin{:});

            % Check if file to be written to is in npal format.
            if DataHandling.Helpers.npal.is_npal_file(path)
                % If it is, generate a writeable reader object.
                reader = matfile(path, 'Writeable', 'true');
            else
                % If not, raise error.
                error("Non-NPAL file passed to NPAL write_to_file" + ...
                    "function: %s", path);
            end

            % Check whether lazy flag was passed.
            if ~p.Results.lazy_flag
                % If lazy flag was not passed, write to entire array.
                reader.data = array;

            else
                % If lazy flag was passed, get target chunk.

                % Set cursor to parsed inputs, filtered for z & t range.
                cursor = rmfield(p.Results, 'lazy_flag');

                % If no z_range was passed or z_range is scalar...
                if isempty(cursor.z_range) || ~isscalar(cursor.z_range)
                    % Write from 1 to length of array's third dimension.
                    cursor.z_range = [1 size(array, 3)];
                end

                % Check whether the passed array contains a fifth
                % dimension, which would mean that it represents a video.
                is_video = ndims(array) > 4;

                % If array represents a video and we lack a valid
                % t_range...
                if is_video && ...
                        (isempty(cursor.t_range) || ~isscalar(cursor.t_range))
                    % Write from 1 to length of array's fifth dimension.
                    cursor.t_range = [1 size(array, 5)];
                end

                % Write to selected data chunk, only indexing along time
                % dimensions if this is a video.
                if is_video
                    reader.data(:, :, ...
                        cursor.z_range(1):cursor.z_range(2), ...
                        :, cursor.t_range(1):cursor.t_range(2));
                else
                    reader.data(:, :, ...
                        cursor.z_range(1):cursor.z_range(2), :);
                end
            end
        end

        function obj = get_reader(path)            
            obj = matfile(path);
        end

        function metadata = get_metadata(obj)
            obj_class = class(obj);

            switch obj_class
                case 'matlab.io.MatFile'
                    if isfield(obj, 'version') && obj.version >= 2.2
                        metadata = obj.metadata;
                    else
                        native_dims = size(obj, 'data');
                        metadata = struct( ...
                            'nx', {native_dims(1)}, ...
                            'ny', {native_dims(2)}, ...
                            'nz', {native_dims(3)}, ...
                            'nc', {native_dims(4)}, ...
                            'native_dims', {native_dims}, ...
                            'dtype_str', {class(obj.data)});

                        if length(native_dims) > 4
                            metadata.nt = native_dims(5);
                        else
                            metadata.nt = 1;
                        end

                        if ismember('channels', fieldnames(obj))
                            metadata.rgb = [];
                            metadata.channels = obj.channels;
                            for c=1:length(metadata.channels)
                                metadata.channels{c}.assign_gui();
                                if metadata.channels{c}.is_rgb
                                    metadata.rgb = [metadata.rgb c];
                                end
                            end
                        end
                    end

                case 'Program.volume'
                    metadata = DataHandling.Helpers.npal.get_metadata(obj.read_obj);
                
                otherwise
                    if ismember(obj_class, {'string', 'char'})
                        obj = DataHandling.Helpers.npal.get_reader(obj);
                        metadata = DataHandling.Helpers.npal.get_metadata(obj);
    
                    else
                        error('Invalid object of class %s passed to npal get_metadata function.', obj_class);
                    end
            end
        end

        function arr = read(obj, varargin)
            if nargin > 1 && ...
                    ~isstruct(varargin{1}) && ...
                    ~isa(varargin{1}, 'Program.GUI.cursor')
                p = inputParser();
                addRequired(p, 'obj');
                addParameter(p, 'cursor', []);
                addParameter(p, 'mode', 'chunk');

                addParameter(p, 'x',    []);
                addParameter(p, 'y',    []);
                addParameter(p, 'z',    []);
                addParameter(p, 'c',    []);
                addParameter(p, 't',    []);

                parse(p, obj, varargin{:});
                
                cursor = p.Results.cursor;
                if isempty(cursor)
                    cursor = Program.GUI.cursor.generate(rmfield(p.Results, {'obj', 'cursor', 'mode'}));
                elseif ~isstruct(cursor) && ~isa(cursor, 'Program.GUI.cursor')
                    cursor = Program.GUI.cursor.generate(cursor);
                end
            end            

            obj = p.Results.obj;

            switch class(obj)
                case 'Program.volume'
                    dims = obj.dims;
                    obj = obj.read_obj;
                case 'matlab.io.MatFile'
                    dims = obj.metadata.dims;
            end
            
            if obj.version >= 3.0
                if strcmp(p.Results.mode, 'chunk') || ~all(structfun(@isempty, cursor))
                    if length(size(obj.volume)) < 5
                        arr = obj.volume( ...
                            cursor.x1:cursor.x2, ...
                            cursor.y1:cursor.y2, ...
                            cursor.z1:cursor.z2, ...
                            cursor.c1:cursor.c2);
                    else
                        arr = obj.volume( ...
                            cursor.x1:cursor.x2, ...
                            cursor.y1:cursor.y2, ...
                            cursor.z1:cursor.z2, ...
                            cursor.c1:cursor.c2, ...
                            cursor.t1:cursor.t2);
                    end
                else
                    arr = obj.volume;
                end

            else
                if strcmp(p.Results.mode, 'chunk') || ~all(structfun(@isempty, cursor))
                    if length(size(obj.data)) < 5
                        arr = obj.data( ...
                            cursor.x1:cursor.x2, ...
                            cursor.y1:cursor.y2, ...
                            cursor.z1:cursor.z2, ...
                            cursor.c1:cursor.c2);
                    else
                        arr = obj.data( ...
                            cursor.x1:cursor.x2, ...
                            cursor.y1:cursor.y2, ...
                            cursor.z1:cursor.z2, ...
                            cursor.c1:cursor.c2, ...
                            cursor.t1:cursor.t2);
                    end
                else
                    arr = obj.data;
                end
            end
        end

        function write(file, arr, varargin)
            p = inputParser();
            addRequired(p, 'file');
            addRequired(p, 'arr');

            addParameter(p, 'cursor', []);
            addParameter(p, 'mode', 'chunk');

            addParameter(p, 'x',    []);
            addParameter(p, 'y',    []);
            addParameter(p, 'z',    []);
            addParameter(p, 'c',    []);
            addParameter(p, 't',    []);

            parse(p, file, arr, varargin{:});

            cursor = p.Results.cursor;
            if isempty(cursor)
                cursor = Program.GUI.cursor.generate(rmfield(p.Results, {'file', 'arr', 'cursor', 'mode'}));
            elseif ~isa(cursor, 'Program.GUI.cursor')
                cursor = Program.GUI.cursor.generate(size(arr), cursor);
            else
                cursor = p.Results.cursor;
            end

            lazy_file = matfile(p.Results.file);
            full_load = all(structfun(@isempty, cursor));
            if lazy_file.version >= 2.2
                if full_load
                    lazy_file.volume;
                else
                    lazy_file.volume( ...
                        cursor.y1:cursor.y2, ...
                        cursor.x1:cursor.x2, ...
                        cursor.z1:cursor.z2, ...
                        cursor.c1:cursor.c2, ...
                        cursor.t1:cursor.t2);
                end
            else
                if full_load
                    lazy_file.data;
                else
                    lazy_file.data( ...
                        cursor.y1:cursor.y2, ...
                        cursor.x1:cursor.x2, ...
                        cursor.z1:cursor.z2, ...
                        cursor.c1:cursor.c2, ...
                        cursor.t1:cursor.t2);
                end
            end
        end
    end
end

