classdef cursor < handle
    
    properties
        x1;
        x2;

        y1;
        y2;

        z1;
        z2;

        c1;
        c2;

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

            channels_to_load = find(cellfun( ...
                @(x)(x.is_rendered), volume.channels));
            obj.c1 = min(channels_to_load);
            obj.c2 = max(channels_to_load);
            
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
            addParameter(p, 'x', []);
            addParameter(p, 'y', []);
            addParameter(p, 'z', []);
            addParameter(p, 'c', []);
            addParameter(p, 't', []);
            parse(p, varargin{:});

            coords = rmfield(p.Results, p.UsingDefaults);
            cursor = struct();

            for pm=1:length(p.Parameters)
                parameter = p.Parameters{pm};
                d1 = sprintf('%s1', parameter);                              
                d2 = sprintf('%s2', parameter);                               
                nd = sprintf('n%s', parameter);   

                if isfield(coords, parameter)              
                    if isscalar(coords.(parameter))
                        cursor.(d1) = coords.(parameter);
                        cursor.(d2) = coords.(parameter);
                    else
                        cursor.(d1) = min(coords.(parameter));
                        cursor.(d2) = max(coords.(parameter));
                    end

                else
                    volume = Program.state().active_volume;
                    if ~strcmpi(parameter, 't') || volume.is_video
                        cursor.(d1) = 1;
                        cursor.(d2) = Program.state().active_volume.(nd);
                    end
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

