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

        function path = search(file, module)
            % to be merged from loader branch
        end

        function [obj, metadata] = open(file)
            if DataHandling.Lazy.file.is_video
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

            if DataHandling.Lazy.file.is_lazy
                obj = f;
            else
                obj = target_module.deref(f).data.load();
            end

        end

        function obj = get_plane(varargin)
            target_module = DataHandling.Helpers.nwb.volume_path;
            metadata = DataHandling.Lazy.file.metadata;
            t = Program.GUIHandling.current_frame;
        
            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', t);
            parse(p, varargin{:});
        
            file = target_module.deref(DataHandling.Lazy.file.current_file).data;
            if DataHandling.Lazy.file.is_video
                obj = file(p.Results.y, p.Results.x, p.Results.z, p.Results.c, p.Results.t);
            else
                obj = file(p.Results.y, p.Results.x, p.Results.z, p.Results.c);
            end
        end
    end
end

