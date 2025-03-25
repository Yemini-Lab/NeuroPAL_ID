function bounds(varargin)
    p = inputParser();
    addParameter(p, 'volume', [])
    addParameter(p, 'nx', []);
    addParameter(p, 'ny', []);
    addParameter(p, 'nz', []);
    addParameter(p, 'nt', []);
    addParameter(p, 'is_initializing', 0)
    parse(p, varargin{:});

    if ~isempty(p.Results.volume) && isa(p.Results.volume, 'Program.volume')
        bounds = p.Results.volume;
    else
        bounds = rmfield(p.Results, 'volume');
    end

    app = Program.app;
    if ~isempty(bounds.nx) && bounds.nx > 1
        app.proc_xSlider.Limits = [1 bounds.nx];
        if p.Results.is_initializing
            app.proc_xSlider.Value = round(app.proc_xSlider.Limits(2)/2);
        end
    end

    if ~isempty(bounds.ny) && bounds.ny > 1
        app.proc_ySlider.Limits = [1 bounds.ny];
        if p.Results.is_initializing
            app.proc_ySlider.Value = round(app.proc_ySlider.Limits(2)/2);
        end
    end

    if ~isempty(bounds.nz) && bounds.nz > 1
        z_limits = [1 bounds.nz];
        app.proc_zSlider.Limits = z_limits;
        app.proc_hor_zSlider.Limits = z_limits;
        app.proc_vert_zSlider.Limits = z_limits;
    
        if p.Results.is_initializing
            app.proc_zSlider.Value = round(app.proc_zSlider.Limits(2)/2);
            app.proc_hor_zSlider.Value = app.proc_zSlider.Value;
            app.proc_vert_zSlider.Value = app.proc_zSlider.Value;
            app.proc_zEditField.Value = round(app.proc_zSlider.Value);
    
            app.ProcZSlicesEditField.Value = app.proc_zSlider.Value;
        end
    end

    if ~isempty(bounds.nt) && bounds.nt > 1
        if bounds.nt > 1
            app.proc_tSlider.Limits = [1 bounds.nt];

            if p.Results.is_initializing
                app.ProcTStartEditField.Value = 1;
                app.ProcTStopEditField.Value = bounds.nt;
    
                app.StartFrameEditField.Value = 1;
                app.EndFrameEditField.Value = bounds.nt;
    
                app.proc_tSlider.Value = 1;
                app.proc_tEditField.Value = 1;
            end
        end
    end
end

