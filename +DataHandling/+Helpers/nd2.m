classdef nd2

    properties
    end

    properties (Access = public, Constant)
        channel_keys = {'ChannelName', 'ChannelOrder', 'ChannelCount', 'ChannelColor'};
        name_substr = 'Global Name #'; 
    end
    
    methods (Static)
        function [obj, metadata] = open(file)
            f = bfGetReader(file);

            metadata = struct( ...
                'path', {file}, ...
                'order', {f.getDimensionOrder}, ...
                'nx', {f.getSizeX}, ...
                'ny', {f.getSizeY}, ...
                'nz', {f.getSizeZ}, ...
                'nc', {f.getSizeC}, ...
                'nt', {f.getSizeT}, ...
                'has_dic', {1}, ...
                'has_gfp', {1}, ...
                'bit_depth', {f.getMetadataStore.getPixelsSignificantBits(0).getValue()}, ...
                'rgbw', {[1 2 3 4]}, ...
                'scale', {[0 0 0]});

            if DataHandling.Lazy.file.is_lazy
                obj = f;
            else
                obj = bfOpen(file);
                obj = obj{1};
            end

        end

        function obj = get_plane(varargin)
            metadata = DataHandling.Lazy.file.metadata;

            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', 1:metadata.nt);
            parse(p, app, varargin{:});

            file = DataHandling.Lazy.file.current_file;
            obj = file.getPlane(p.Results.x, p.Results.y, p.Results.z, p.Results.c, p.Results.t);
        end
    end
end

