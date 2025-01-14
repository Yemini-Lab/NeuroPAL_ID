classdef active_volume    
    properties
    end
    
    methods (Static)
        function obj = all()            
            volume_type = Program.Handlers.active_volume.type;
            volume_array = Program.Handlers.active_volume.array;
            volume_dims = Program.Handlers.active_volume.dims;
            volume_channels = Program.Handlers.channels.read_gui;

            arr_dims = size(volume_array);
            if volume_dims(1:length(arr_dims)) ~= arr_dims
                volume_dims = arr_dims;
            end

            obj = struct( ...
                'type', {volume_type}, ...
                'dims', {volume_dims}, ...
                'array', {volume_array}, ...
                'channels', {volume_channels});
        end
        
        function volume_type = type()
            % Return string describing current volume type (video/colormap)

            if Program.states.instance().is_video
                volume_type = 'video';
            else
                volume_type = 'colormap';
            end
        end

        function volume_dims = dims()
            % Return (x, y, z, c, t) array describing volume dimensions.

            volume_dims = [ ...
                DataHandling.file.metadata.nx ...
                DataHandling.file.metadata.ny ...
                DataHandling.file.metadata.nz ...
                DataHandling.file.metadata.nc ...
                DataHandling.file.metadata.nt];
        end

        function volume_array = array()
            % Return array representing currently indexed array.

            if Program.states.instance().is_lazy
                z = DataHandling.file.metadata.nz;
                c = DataHandling.channels.indices.lazy_load;
                t = DataHandling.file.metadata.nt;
            else
                z = DataHandling.file.metadata.nz;
                c = DataHandling.channels.indices.in_file;
                t = DataHandling.file.metadata.nt;
            end

            switch Program.GUIHandling.volume_type
                case 'Colormap'
                    volume_array = DataHandling.file.get_plane( ...
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
    end
end

