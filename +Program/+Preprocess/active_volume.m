classdef active_volume
    %ACTIVE_VOLUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function obj = active_volume(spec)
            if ~exist('spec', 'var')
                kind = Program.Preprocess.active_volume('kind');
                dimensions = Program.Preprocess.active_volume('dimensions');
                array = Program.Preprocess.active_volume('array');

                obj = struct( ...
                    'kind', {kind}, ...
                    'dimensions', {dimensions}, ...
                    'array', {array});

                return
            end

            switch spec
                case 'type'
                    obj = Program.Preprocess.active_volume.kind();
                case 'array'
                    obj = Program.Preprocess.active_volume.array();
                case 'dims'
                    obj = Program.Preprocess.active_volume.dimensions();
            end
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
        
        function volume_type = kind()
            volume_type = lower(Program.GUIHandling.volume_type);
        end

        function volume_dims = dimensions()
            volume_dims = [ ...
                DataHandling.Lazy.file.metadata.nx ...
                DataHandling.Lazy.file.metadata.ny ...
                DataHandling.Lazy.file.metadata.nz ...
                DataHandling.Lazy.file.metadata.nc ...
                DataHandling.Lazy.file.metadata.nt];
        end
    end
end

