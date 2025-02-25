classdef cursor < handle
    
    properties
        x1 = 1;
        x2 = 0;

        y1 = 1;
        y2 = 0;

        z1 = 1;
        z2 = 0;

        c1 = 1;
        c2 = 0;

        t1 = 1;
        t2 = 0;

        mode = 'chunk';
    end
    
    methods (Access = public)
        function obj = cursor(volume)
            states = Program.states;

            if nargin == 0
               volume = states.active_volume;
            end

            if isempty(states.interface)
                obj.generate('obj', obj, 'volume', volume, ...
                    'z', round(volume.nz/2), 't', 1);
            else
                switch states.interface
                    case "NeuroPAL ID"
                        obj = stack_cardinals(volume);
        
                    case "Video Tracking"
                        obj = video_cardinals(volume);
        
                    case "Image Processing"
                        obj = processing_cardinals(volume);
                end
            end
        end
    end

    methods (Static, Access = public)
        function obj = generate(varargin)
            p = inputParser();

            addParameter(p, 'obj', []);
            addParameter(p, 'volume', []);
            addParameter(p, 'coords', []);
            addParameter(p, 'mode', 'chunk');

            addParameter(p, 'x', []);
            addParameter(p, 'y', []);
            addParameter(p, 'z', []);
            addParameter(p, 'c', []);
            addParameter(p, 't', []);

            parse(p, varargin{:});
            coords = p.Results.coords;
            volume = p.Results.volume;
            obj = p.Results.obj;
            
            if isempty(obj)
                obj = Program.GUI.cursor;
            end

            if isempty(volume)
                states = Program.states;
                volume = states.active_volume;
            end

            if isempty(coords)
                coords = rmfield(p.Results, ...
                    {'obj', 'volume', 'coords', 'mode'});
            end

            obj.unfurl(coords)
        end
    end

    methods (Access = private)
        function unfurl(obj, source)
            states = Program.states;
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

        function coords = stack_cardinals(obj)
            app = Program.app;
            coords = struct( ...
                'x1', {1}, ...
                'x2', {obj.nx}, ...
                'y1', {1}, ...
                'y2', {obj.ny}, ...
                'z1', {app.ZSlider.Value}, ...
                'z2', {app.ZSlider.Value}, ...
                't1', {[]}, ...
                't2', {[]});
        end

        function coords = video_cardinals(obj)
            app = Program.app;
            coords = struct( ...
                'x1', {1}, ...
                'x2', {obj.nx}, ...
                'y1', {1}, ...
                'y2', {obj.ny});


            if ~app.OverlayFrameMIPCheckBox.Value
                coords.z1 = app.vert_zSlider.Value; coords.z2 = coords.z1;
            else
                coords.z1 = 1; coords.z2 = obj.nz;
            end
            
            coords.t1 = app.tSlider.Value; coords.t2 = app.tSlider.Value;
        end

        function coords = processing_cardinals(obj)
            app = Program.app;
            coords = struct( ...
                'x1', {app.proc_xSlider.Value}, ...
                'x2', {app.proc_xSlider.Value}, ...
                'y1', {app.proc_ySlider.Value}, ...
                'y2', {app.proc_ySlider.Value});

            if ~app.ProcShowMIPCheckBox.Value
                coords.z1 = app.proc_zSlider.Value; coords.z2 = coords.z1;
            else
                coords.z1 = 1; coords.z2 = obj.nz;
            end

            if obj.is_video
                coords.t1 = app.proc_tSlider.Value; coords.t2 = coords.t1;
            else
                coords.t1 = []; coords.t2 = [];
            end
        end
    end
end

