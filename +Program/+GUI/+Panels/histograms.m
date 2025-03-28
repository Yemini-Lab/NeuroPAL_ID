classdef histograms < handle
    %HISTOGRAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        panels = {};
        grid = [];
        is_initialized = 0;
    end
    
    methods (Access = public)
        function obj = histograms()
            persistent panel_instance

            if isempty(panel_instance) || ~isgraphics(panel_instance.grid)
                app = Program.app;
                obj.grid = app.ProcHistogramGrid;
                obj.is_initialized = 1;
                panel_instance = obj;
            end

            obj = panel_instance;
        end
    end

    methods (Static, Access = public)
        function n = n_panels()
            obj = Program.GUI.Panels.histograms;
            n = length(obj.panels);
        end

        function panel = get_panel(idx)
            obj = Program.GUI.Panels.histograms;
            panel = obj.panels{idx};
        end

        function populate(volume)
            nc = volume.nc;
            limits = [1 volume.dtype_max];

            obj = Program.GUI.Panels.histograms;
            obj.set_panel_count(nc);
            obj.set_limits(double(limits));
        end

        function draw(varargin)
            [app, ~, state] = Program.ctx;
            obj = Program.GUI.Panels.histograms;
            n_columns = length(obj.grid.ColumnWidth);

            p = inputParser();
            addParameter(p, 'array', []);
            addParameter(p, 'volume', state.active_volume);
            parse(p, varargin{:});

            if isempty(p.UsingDefaults)
                load_idx = 0;
                for c=1:p.Results.volume.nc
                    channel = p.Results.volume.channels{c};
                    if channel.is_rendered
                        load_idx = load_idx + 1;
                        channel_histogram = p.Results.array(:, :, :, load_idx);
                        row = max(1, ceil(channel.gui_idx/3));
                        column = mod(channel.gui_idx, n_columns);
                        if ~column
                            column = 3;
                        end

                        if app.HidezerointensitypixelsCheckBox.Value
                            channel_histogram = channel_histogram(...
                                channel_histogram > 0);
                        end

                        if max(channel_histogram, [], 'all') <= 1
                            channel_histogram = channel_histogram * ...
                                app.ProcNoiseThresholdKnob.Limits(2);
                        end

                        panel = obj.panels{channel.gui_idx};
                        panel.load(channel, ...
                            channel_histogram);
                        panel.move( ...
                            'Row', row, ...
                            'Column', column, ...
                            'Parent', obj.grid);
                        panel.enable();
                    else
                        obj.reset(channel.gui_idx);
                    end
                end

                obj.grid.RowHeight = repmat({'1x'}, 1, ...
                    ceil(load_idx/n_columns));
            end
        end

        function trigger_update(obj, prop)
            obj.channel.update(prop);
        end

        function lock(state)
            obj = Program.GUI.Panels.histograms;
            cellfun(@(x)(x.lock(state)), obj.panels);
        end

        function set_limits(new_limits)
            for p=1:Program.GUI.Panels.histograms.n_panels
                panel = Program.GUI.Panels.histograms.get_panel(p);
                panel.histogram_slider.Limits = new_limits;
                panel.histogram_slider.Value = new_limits;
                panel.histogram_axes.XLim = new_limits;
            end
        end
    end

    methods (Access = private)
        function obj = reset(obj, idx)
            obj.grid.RowHeight = {'1x'};
            if nargin < 2
                for p = 1:obj.n_panels
                    obj.reset(obj, p);
                end
            else
                obj.panels{idx}.disable();
            end
        end

        function obj = set_panel_count(obj, n)
            if obj.n_panels == n
                return
            elseif obj.n_panels < n
                missing_channels = obj.n_panels+1:n;
                obj.add_panel(length(missing_channels));
            else
                excess_channels = obj.n_panels:-1:n+1;
                obj.delete_panel(excess_channels);
            end
        end

        function obj = add_panel(obj, count)
            if isempty(obj.panels) || ~isgraphics(obj.grid)
                obj = Program.GUI.Panels.histograms;
            end

            if nargin == 2
                for n=1:count
                    obj.add_panel();
                end
            else
                obj.panels{end+1} = Program.GUI.Templates.histogram_panel();
            end
        end
    end
end

