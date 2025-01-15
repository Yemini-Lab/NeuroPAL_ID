classdef nwb

    properties (Access = public, Constant)
    end
    
    methods (Static)
        function path = volume_path(new_path)
            persistent instance

            if isempty(instance) || exist('new_path', 'var')
                instance = types.untyped.SoftLink(new_path);
            end

            path = instance;
        end

        function load_tracks(filepath)
        end

        function path = search(file, module)
            % to be merged from loader branch
        end

        function [obj, metadata] = open(file)
            if Program.states.instance().is_video
                DataHandling.Helpers.nwb.volume_path('/acquisition/CalciumImageSeries');
            else
                DataHandling.Helpers.nwb.volume_path('/acquisition/NeuroPALImageRaw');
            end

            f = nwbRead(file);
            target_module = DataHandling.Helpers.nwb.volume_path;

            metadata = struct( ...
                'path', {file}, ...
                'order', {target_module.deref(f).imaging_volume.deref(f).opticalchannelplus}, ...
                'nx', {target_module.deref(f).data.internal.dims(2)}, ...
                'ny', {target_module.deref(f).data.internal.dims(1)}, ...
                'nz', {target_module.deref(f).data.internal.dims(3)}, ...
                'nc', {target_module.deref(f).data.internal.dims(4)}, ...
                'has_dic', {1}, ...
                'has_gfp', {1}, ...
                'bit_depth', {str2num(target_module.deref(f).data.internal.dataType(5:end))}, ...
                'rgbw', {[target_module.deref(f).RGBW_channels.load()]'}, ...
                'scale', {[0 0 0]});

            if length(target_module.deref(f).data.internal.dims) > 4
                metadata.nt = target_module.deref(f).data.internal.dims(5);
            else
                metadata.nt = 1;
            end

            if Program.states.instance().is_lazy
                obj = f;
            else
                obj = target_module.deref(f).data.load();
            end

        end

        function np_file = to_npal(file, is_video)
            %CONVERTNWB Convert an NWB file to NeuroPAL format.
            %
            % nwb_file = the NWB file to convert
            % np_file = the NeuroPAL format file

            if nargin < 2
                app = Program.app;
                is_video = Program.Validation.agnostic_vol_check();
            end

            f = nwbRead(file);                                              % Get reader object.

            if is_video
                module = f.acquisition.get('CalciumImageSeries');
                dim_permutation = [4 3 2 1 5];
            else
                module = f.acquisition.get('NeuroPALImageRaw');
                dim_permutation = [1 1 1 1 1];
            end

            dims = module.data.internal.dims([dim_permutation]);

            nx = dims(2);                                                       % Get width.
            ny = dims(1);                                                       % Get height.
            nz = dims(3);                                                       % Get depth.
            nc = dims(5);                                                       % Get channel count.

            if is_video
                nt = dims(6);                                                    % Get frame count.
            else
                nt = 1;
            end

            bit_depth = module.data.dataType;

            data = [];                                                          % Initialize data as proportionate zero array.

            info = struct('file', {file});                                      % Initialize info struct.
            info.scale = module.imaging_volume.deref(f).grid_spacing.load();    % Set image scale
            info.scale = info.scale(:)';

            channels = DataHandling.Helpers.nwb.get_channel_names(f, module);   % Get channel names.
            channels = Program.Handlers.channels.parse_info(channels);          % Get channel indices from names.

            if isprop(module, 'RGBW_channels')
                info.RGBW = module.RGBW_channels.load();
                info.RGBW = info.RGBW(:)';
            else
                info.RGBW = channels(1:4);                                      % Set RGBW indices.
            end

            info.DIC = channels(5);                                             % Set DIC if present, else set to 0.
            info.GFP = channels(6);                                             % Set GFP is present, else set to 0.
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
            worm.body = strrep(module.imaging_volume.deref(f).reference_frame, 'Worm ', '');
            worm.age = f.general_subject.growth_stage;
            worm.sex = Program.Validation.parse_sex(f.general_subject.sex);
            worm.strain = f.general_subject.strain;
            worm.notes = f.general_subject.description;
            
            % Save the ND2 file to our MAT file format.
            np_file = strrep(file, 'nd2', 'mat');
            version = Program.information.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');

            DataHandling.Helpers.nwb.write_data(np_file, module.data, [ny nx nz nc nt]);
        end

        function obj = get_plane(varargin)
            target_module = DataHandling.Helpers.nwb.volume_path;
            metadata = DataHandling.file.metadata;
            t = Program.GUIHandling.current_frame;
        
            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', t);
            parse(p, varargin{:});
        
            file = target_module.deref(DataHandling.file.current_file).data;
            if DataHandling.file.is_video
                obj = file(p.Results.y, p.Results.x, p.Results.z, p.Results.c, p.Results.t);
            else
                obj = file(p.Results.y, p.Results.x, p.Results.z, p.Results.c);
            end
        end

        function names = get_channel_names(f, module)
            optical_channels = module.imaging_volume.deref(f).opticalchannel;
            names = keys(optical_channels);
            names = string(names);
        end

        function write_data(np_file, data_pipe, dims)
            Program.Handlers.dialogue.add_task('Writing data...');
            np_write = matfile(np_file, "Writable", true);

            nx = dims(2);                                                       % Get width.
            ny = dims(1);                                                       % Get height.
            nz = dims(3);                                                       % Get depth.
            nc = dims(5);                                                       % Get channel count.
            nt = dims(6);                            

            np_write.data = zeros( ...
                ny, nx, ...
                nz, nc, nt, ...
                Program.config.defaults{'class'});

            if nt > 1
                for t=1:nt
                    Program.Handlers.dialogue.set_value(t/nt);
                    this_frame = data_pipe(:, :, :, :, t);
                    np_write.data(:, :, :, :, t) = DataHandling.Types.to_standard(this_frame);
                end
                
            else
                for z=1:nz
                    Program.Handlers.dialogue.set_value(z/nz);
                    this_slice = data_pipe(:, :, z, :)
                    np_write.data(:, :, z, :) = DataHandling.Types.to_standard(this_slice);
                end
            end

            Program.Handlers.dialogue.resolve();
        end
    end
end

