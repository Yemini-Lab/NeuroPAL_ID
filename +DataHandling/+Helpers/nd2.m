classdef nd2

    properties (Access = private)
        nd2_file;
        is_lazy;
    end

    properties (Access = public, Constant)
        channel_keys = {'ChannelName', 'ChannelOrder', 'ChannelCount', 'ChannelColor'};
        name_substr = 'Global Name #'; 
    end
    
    methods
        function [obj, metadata] = open(file)
            f = bfGetReader(file);

            metadata = dictionary( ...
                'path', file, ...
                'order', f.getDimensionOrder, ...
                'nx', f.getSizeX, ...
                'ny', f.getSizeY, ...
                'nz', f.getSizeZ, ...
                'nc', f.getSizeC, ...
                'nt', f.getSizeT);

            if DataHandling.file.is_lazy
                obj = f;
            else
                obj = bfOpen(file);
                obj = obj{1};
            end

        end

        function obj = get_plane(varargin)
            metadata = DataHandling.file.metadata;

            p = inputParser;
            addOptional(p, 'x', 1:metadata.nx);
            addOptional(p, 'y', 1:metadata.ny);
            addOptional(p, 'z', 1:metadata.nz);
            addOptional(p, 'c', 1:metadata.nc);
            addOptional(p, 't', 1:metadata.nt);
            parse(p, app, varargin{:});

            obj = DataHandling.file.current_file.getPlane(p.Results.x, p.Results.y, p.Results.z, p.Results.c, p.Results.t);
        end
    end
end

