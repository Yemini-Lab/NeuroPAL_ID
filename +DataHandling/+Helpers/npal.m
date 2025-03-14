classdef npal

    properties (Access = public, Constant)
    end
    
    methods (Static)
        %% Rework
        function bool = is_npal_file(path)
            [~, fname, fmt] = fileparts(path);
            bool = strcmp(fmt, '.mat') && endsWith(fname, '-NPAL');
        end

        function create(path, varargin)
            p = inputParser();
            addRequired(p, 'path');
            addParameter(p, 'version', 'legacy');
            addParameter(p, 'like', []);
            parse(p, path, varargin{:});
            path = strrep(path, '.npal', '-NPAL.mat');

            if ~isempty(p.Results.like)
                fstruct = struct();
                template = p.Results.like;

                if ~strcmp(p.Results.version, 'legacy')
                    fstruct.version = p.Results.version;
                    fstruct.metadata = template.info;
                    fstruct.device = template.device;
                    fstruct.channels = template.channels;
                else
                    fstruct.version = 2.0;
   
                    fstruct.channels = {};
                    for c=1:length(template.channels)
                        fstruct.channels{end+1} = template.channels{c}.freeze();
                    end
                    rgbw = template.get('rgbw');
                    dic = template.get('dic');
                    gfp = template.get('gfp');
                    gammas = template.get('gammas');
    
                    fstruct.info = struct( ...
                        'file', {path}, ...
                        'scale', {template.device.voxel_resolution}, ...
                        'DIC', {dic}, ...
                        'GFP', {gfp}, ...
                        'RGBW', {rgbw}, ...
                        'gamma', {gammas});
    
                    fstruct.prefs = struct( ...
                        'DIC', {dic}, ...
                        'GFP', {gfp}, ...
                        'RGBW', {rgbw}, ...
                        'rotate', {}, ...
                        'z_center', {}, ...
                        'is_Z_LR', 1, ...
                        'is_Z_flip', 1);
    
                    fstruct.worm = struct( ...
                        'age', {template.subject.age}, ...
                        'sex', {template.subject.sex}, ...
                        'body', {template.subject.body}, ...
                        'strain', {template.subject.strain}, ...
                        'notes', {template.subject.notes});
                end

                fstruct.data = zeros(template.dims, template.dtype_str);
                save(path, '-struct', 'fstruct', '-v7.3');
            end
        end

        function obj = get_reader(path)
            if ~endsWith(path, 'NPAL.mat')
                error('Non-%s file passed to npal get_reader function: \n%s', Program.config.npal.fmt, path)
            end
            
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
            if ~isa(varargin{1}, 'cursor')
                p = inputParser();
                addRequired(p, 'obj');
                addParameter(p, 't',    []);  % default means "all"
                addParameter(p, 'z',    []);
                addParameter(p, 'c',    []);
                addParameter(p, 'x',    []);
                addParameter(p, 'y',    []);
                addParameter(p, 'mode', 'chunk'); % default read mode
                parse(p, obj, varargin{:});
                cursor = rmfield(p.Results, {'mode', 'obj'});
                Program.GUI.cursor.generate(p.Results);
            end

            switch class(obj)
                case 'Program.volume'
                    dims = obj.dims;
                    obj = obj.read_obj;
                case 'matlab.io.MatFile'
                    dims = obj.metadata.dims;
            end
            
            if strcmp(p.Results.mode, 'chunk') || ~all(structfun(@isempty, cursor))
                parameters = fieldnames(cursor);
    
                for p=1:length(parameters)
                    parameter = parameters{p};
                    if isempty(cursor.(parameter)) && isfield(dims, parameter)
                        cursor.(parameter) = 1:dims.(parameter);
                    end
                end

                fn = fieldnames(cursor);
                idx_cell = cellfun(@(f) cursor.(f), fn, 'UniformOutput', false);
                idx_cell = idx_cell(1:length(native_dims));
                indices = idx_cell(flip(order));
                arr = obj.volume(indices{:});
            else
                arr = obj.volume;
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

