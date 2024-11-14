classdef GUI
    
    properties (Constant)
        cursor_color = '#9c9c9c';
        cursor_width = 0.2;
    end
    
    methods (Static)
        function handle = app()
            persistent app_handle

            if any(isempty(app_handle)) || any(isa(app_handle, "handle")) && any(~isvalid(app_handle))
                window_handle = Program.GUI.window();
                app_handle = window_handle.RunningAppInstance;
            end

            handle = app_handle;
        end
        
        function handle = window()
            persistent window_handle

            if any(isempty(window_handle)) || any(~isgraphics(window_handle))
                window_handle = findall(groot, 'Name','NeuroPAL ID');
            end
            
            handle = window_handle;
        end

        function set_limits(varargin)
            
            p = inputParser;
            addOptional(p, 'nx', 'state');
            addOptional(p, 'ny', []);
            addOptional(p, 'nz', package);
            addOptional(p, 'nt', package);

            parse(p, varargin{:});

            nx = p.Results.nx;
            ny = p.Results.ny;
            nz = p.Results.nz;
            nt = p.Results.nt;

            app = Program.GUI.app;
            app.proc_xSlider.Limits = [1 nx];
            app.proc_ySlider.Limits = [1 ny];
            app.proc_zSlider.Limits = [1 nz];
            app.proc_hor_zSlider.Limits = [1 nz];
            app.proc_vert_zSlider.Limits = [1 nz];

            if app.proc_xSlider.Value ~= 1 || app.proc_ySlider.Value ~= 1 || app.proc_zSlider.Value ~= 1 || app.proc_tSlider.Value ~= 1   
                Program.GUI.initialize_values();
            end
        end

        function initialize_values()
            app = Program.GUI.app;

            app.proc_xSlider.Value = round(app.proc_xSlider.Limits(2)/2);
            app.proc_ySlider.Value = round(app.proc_ySlider.Limits(2)/2);

            app.proc_zSlider.Value = round(app.proc_zSlider.Limits(2)/2);
            app.proc_vert_zSlider.Value = app.proc_zSlider.Value;
            app.proc_hor_zSlider.Value = app.proc_zSlider.Value;

            app.proc_tSlider.Value = 1;

            app.proc_zEditField.Value = app.proc_zSlider.Value;
            app.proc_tEditField.Value = app.proc_tSlider.Value;
            
            app.ProcZSlicesEditField.Value = app.proc_zSlider.Value;
        end

        function indices(channel, idx)
            app = Program.GUI.app;
        end

        function gammas(gamma, idx)
            app = Program.GUI.app;

            if ~exist('idx', 'var')
                for idx = 1:Program.Handlers.channels.max_nc
                    Program.GUI.gammas(gamma(idx), idx);
                end

                return
            end

            component_name = sprintf("%s_GammaEditField", Program.Handlers.handles.ch_pfx{idx});
            app.(component_name).Value = gamma;
        end

        function toggle_loading(handle)
            if nargin > 0
                handle = Program.GUI.window;
            end

            if ~Program.states.instance().is_loading
                uiimage( ...
                    "ImageSource", fullfile('Data', 'Images', 'loading.gif'), ...
                    "ScaleMethod", 'fit', ...
                    'Position', handle.Position);
                drawnow;
            end

            Program.states.toggle('is_loading');
        end
    end
end

