function histograms(varargin)
    p = inputParser();
    addParameter(p, 'volume', [])
    addParameter(p, 'array', []);
    addParameter(p, 'channels', []);
    parse(p, varargin{:});
    
    app = Program.app;
    pfx = {'tl', 'tm', 'tr', 'bl', 'bm', 'br'};

    if ~isempty(p.Results.volume) ...
            && isa(p.Results.volume, 'Program.volume')
        vol = p.Results.volume;

        for c = 1:vol.nc
            channel = vol.channels{c};
            if channel.is_rendered
                h_pfx = pfx{1};

                h_panel = app.(sprintf("%s_hist_panel", h_pfx));
                h_axes = app.(sprintf("%s_hist_ax", h_pfx));
                h_label = app.(sprintf("%s_Label", h_pfx));

                h_panel.Visible = 'on';
                h_label.Text = sprintf("%s Channel", channel.fluorophore);

                histogram(h_axes, chan_hist, ...
                    'FaceColor', channel.color, ...
                    'EdgeColor', channel.color)

                h_axes.XLim = [ ...
                    app.HidezerointensitypixelsCheckBox.Value, ...
                    h_axes.XLim(2)];

                if startWith(h_pfx, 'b')
                    n_max = Program.Handlers.channels.config{'max_channels'};
                    if c >= 4
                        h_panel.Parent = app.ProcHistogramGrid;
                        h_panel.Layout.Row = 2;

                        if c <= n_max
                            h_panel.Layout.Column = c - 3;
                        end
                    end
                end


                pfx = pfx(2:end);
                if isempty(pfx)
                    return
                end
            end
        end
    end
end