classdef active_volume
    %ACTIVE_VOLUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function obj = all()
            volume_type = Program.Preprocess.active_volume.type;
            volume_array = Program.Preprocess.active_volume.array;
            volume_dims = Program.Preprocess.active_volume.dims;

            arr_dims = size(volume_array);
            if volume_dims(1:length(arr_dims)) ~= arr_dims
                volume_dims = arr_dims;
            end

            obj = struct( ...
                'type', {volume_type}, ...
                'dims', {volume_dims}, ...
                'array', {volume_array});
        end

        function volume_array = array()
            if Program.GUIHandling.is_lazy
                z = DataHandling.Lazy.file.metadata.nz;
                c = DataHandling.channels.indices.lazy_load;
                t = DataHandling.Lazy.file.metadata.nt;
            else
                z = DataHandling.Lazy.file.metadata.nz;
                c = DataHandling.channels.indices.in_file;
                t = DataHandling.Lazy.file.metadata.nt;
            end

            switch Program.GUIHandling.volume_type
                case 'Colormap'
                    volume_array = DataHandling.Lazy.file.get_plane( ...
                        'z', z, ...
                        'c', c, ...
                        't', t);
                case 'Video'
                    volume_array = app.retrieve_frame;
            end

            volume_array = volume_array(:, :, :, DataHandling.channels.indices.render_permutation, :);

            if Program.GUIHandling.is_mip
                return
            end

            volume_array = volume_array(:, :, :, Program.GUIHandling.active_channels, :);
            if ~isempty(DataHandling.channels.indices.unrendered_RGB)
                channel_size = size(volume_array); channel_size(4) = 1;
                blank_channel = zeros(channel_size, 'like', volume_array);

                for n=DataHandling.channels.indices.unrendered_RGB:-1:1
                    c = DataHandling.channels.indices.unrendered_RGB(n);
                    volume_array = cat(dim, volume_array(:, :, :, 1:c-1), blank_channel, volume_array(:, :, :, c:end));
                end
            end
        end
        
        function volume_type = type()
            volume_type = lower(Program.GUIHandling.volume_type);
        end

        function volume_dims = dims()
            volume_dims = [ ...
                DataHandling.Lazy.file.metadata.nx ...
                DataHandling.Lazy.file.metadata.ny ...
                DataHandling.Lazy.file.metadata.nz ...
                DataHandling.Lazy.file.metadata.nc ...
                DataHandling.Lazy.file.metadata.nt];
        end
    end
end

