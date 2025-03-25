classdef cursor < handle
    
    properties
        x1;
        x2;

        y1;
        y2;

        z1;
        z2;

        t1;
        t2;
    end
    
    methods (Access = public)
        function obj = cursor(varargin)
            state = Program.state;
            projection = state.projection;
            
            p = inputParser();
            addParameter(p, 'interface', state.interface);
            addParameter(p, 'volume', state.active_volume);
            parse(p, varargin{:});

            gui = obj.get_gui(p.Results.interface);
            volume = p.Results.volume;

            have_x_comp = ~isempty(gui.x);
            have_y_comp = ~isempty(gui.y);
            is_projecting_z = contains(projection, 'z');
            is_projecting_xy = contains(projection, 'xy');
        
            if is_projecting_xy || is_projecting_z
                obj.x1 = 1;
                obj.x2 = volume.nx;
            elseif have_x_comp
                obj.x1 = round(gui.x.Value);
                obj.x2 = obj.x1;
            end

            if is_projecting_xy || is_projecting_z
                obj.y1 = 1;
                obj.y2 = volume.ny;
            elseif have_y_comp
                obj.y1 = round(gui.y.Value);
                obj.y2 = obj.y1;
            end
            
            if state.mip || ~is_projecting_z
                obj.z1 = 1;
                obj.z2 = gui.z.Limits(2);
            else
                obj.z1 = round(gui.z.Value);
                obj.z2 = obj.z1;
            end
            
            if Program.GUI.viewing_video
                obj.t1 = round(gui.t.Value);
                obj.t2 = obj.t1;
            else
                obj.t1 = [];
                obj.t2 = [];
            end
        end

        function gui = get_gui(obj, interface)
            gui = struct();

            if nargin < 2
                state = Program.state();
                interface = state.interface;
            end

            if nargin == 2
                app = Program.app;

                switch interface
                    case {0, "NeuroPAL ID", 'stack', 'id'}
                        gui.x = [];
                        gui.y = [];
                        gui.z = app.ZSlider;
                        gui.t = [];
        
                    case {1, "Video Tracking", 'track', 'tracking'}
                        gui.x = app.xSlider;
                        gui.y = app.ySlider;
                        gui.z = app.vert_zSlider;
                        gui.t = app.tSlider;
        
                    case {2, "Image Processing", 'proc', 'processing'}
                        gui.x = app.proc_xSlider;
                        gui.y = app.proc_ySlider;
                        gui.z = app.proc_zSlider;
                        gui.t = app.proc_tSlider;
                end
            end
        end
    end

    methods (Static, Access = public)
        function cursor = generate(dims, varargin)
            p = inputParser();
            Program.Helpers.parse_coordinates(p);
            parse(p, varargin{:});

            coords = p.Results;
            d_labels = fieldnames(coords);

            if ~isstruct(dims)
                n_dims = length(dims);
                struct_dim = struct();

                struct_dim.nx = dims(1);
                struct_dim.ny = dims(2);
                struct_dim.nz = dims(3);
                struct_dim.nc = dims(4);

                if n_dims > 4
                    struct_dim.nt = dims(5);
                end

                dims = struct_dim;
            else
                n_dims = length(fieldnames(dims));
            end

            cursor = struct();
            for n=1:length(d_labels)
                d = d_labels{n};                                        % Label for each dimension, e.g. "x", "y", "z', ...
                d1 = sprintf('%s1', d);                               % First index in a chunk read.
                d2 = sprintf('%s2', d);                               % Last index in a chunk read.
                nd = sprintf('n%s', d);                               % Label for the size of each dimension, e.g. "nx", "ny", "nz", ...

                if n <= n_dims && (isfield(dims, nd) || ~isempty(coords.(d)))    
                    if ~isempty(coords.(d))                                 % If an index was given for a particular dimension, set cursor to that index.
                        cursor.(d1) = coords.(d);
                        cursor.(d2) = cursor.(d1);
                    else                                                    % If no index was given for a particular dimension, set cursor to dimensional range.
                        cursor.(d1) = 1;
                        cursor.(d2) = dims.(nd);
                    end

                else
                    cursor.(d1) = [];
                    cursor.(d2) = [];
                end
            end
        end
    end

    methods (Access = private)
        function unfurl(obj, source)
            states = Program.state;
            d = fieldnames(source);

            for n=1:length(d)
                dc = d{n};
                if isempty(source.(dc))
                    obj.(sprintf('%s1', dc)) = 1;
                    obj.(sprintf('%s2', dc)) = states.active_volume.( ...
                        sprintf('n%s', dc));

                elseif isscalar(source.(dc))
                    obj.(sprintf('%s1', dc)) = source.(dc);
                    obj.(sprintf('%s2', dc)) = source.(dc);
                    
                else 
                    value = source.(dc);
                    obj.(sprintf('%s1', dc)) = value(1);
                    obj.(sprintf('%s2', dc)) = value(2);
                end
            end
        end
    end
end

