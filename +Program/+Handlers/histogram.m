classdef histogram
    
    properties (Constant)
        pfx_list = {'tl', 'tm', 'tr', 'bl', 'bm', 'br'};

        disp_dict = dictionary( ...
            'r', 'Red', ...
            'g', 'Green', ...
            'b', 'Blue', ...
            'w', 'White', ...
            'dic', 'DIC', ...
            'gfp', 'GFP');

        color_dict = dictionary( ...
            'r', 'r', ...
            'g', 'g', ...
            'b', 'b', ...
            'w', 'k', ...
            'dic', 'k', ...
            'gfp', 'y');
    end
    
    methods (Static, Access = public)
        function update()
            app = Program.GUIHandling.app;
            bools = Program.Handlers.channels.bools;
            volume = Program.GUIHandling.get_active_volume(app, 'request', 'array');

            for c=1:Program.Handlers.channels.max_channels
                if bools(c)
                    if c > 3
                        Program.Handlers.histogram.set_rows(2);
                    end

                    Program.Handlers.histogram.draw( ...
                        Program.Handlers.channels.idx_to_name(c), ...
                        volume.array(:, :, :, c), ...
                        c);
                end
            end
        end
        
        function reset(idx)
            if ~exist('idx', 'var')
                Program.Handlers.histogram.set_rows(1);
                for idx=1:length(Program.Handlers.histogram.pfx_list)
                    Program.Handlers.histogram.reset(idx);
                end
            end
            
            histogram = Program.Handlers.histogram.get_gui(idx);
            histogram.panel.Visible = 'off';
            cla(histogram.axes)
        end
        
        function draw(name, channel, idx)
            app = Program.GUIHandling.app;
            gui = Program.Handlers.histogram.get_gui(idx);

            if app.HidezerointensitypixelsCheckBox.Value
                channel = channel(channel>0);
            end

            if max(channel, [], 'all') <= 1
                channel = channel * Program.Preprocess.settings.threshold(2);
            end
            
            gui.panel.Visible = 'on';
            gui.label.Text = sprintf("%s Channel", Program.Handlers.histogram.disp_dict(name));

            histogram(gui.axes, channel, ...
                'FaceColor', Program.Handlers.histogram.color_dict(name), ...
                'EdgeColor', Program.Handlers.histogram.color_dict(name));
            gui.axes.XLim = [app.HidezerointensitypixelsCheckBox.Value, gui.axes.XLim(2)];

            if idx > 3
                gui.panel.Parent = gui.grid;
                gui.panel.Layout.Row = 2;
                gui.panel.Layout.Column = idx-3;
            end
        end
    end

    methods (Static, Access = private)
        function handle_struct = get_gui(idx)
            app = Program.GUIHandling.app;

            h_panel = sprintf("%s_hist_panel", Program.Handlers.histogram.pfx_list{idx});
            h_label = sprintf("%s_Label", Program.Handlers.histogram.pfx_list{idx});
            h_axes = sprintf("%s_hist_ax", Program.Handlers.histogram.pfx_list{idx});
            h_grid = app.ProcHistogramGrid;

            handle_struct = struct( ...
                'panel', {app.(h_panel)}, ...
                'label', {app.(h_label)}, ...
                'axes', {app.(h_axes)}, ...
                'grid', {h_grid});
        end

        function set_rows(n)
            app = Program.GUIHandling.app;

            if n==1
                app.bl_hist_panel.Parent = app.CELL_ID;
                app.bm_hist_panel.Parent = app.CELL_ID;
                app.br_hist_panel.Parent = app.CELL_ID;
    
                app.bl_hist_panel.Visible = 'off';
                app.bm_hist_panel.Visible = 'off';
                app.br_hist_panel.Visible = 'off';
    
                app.ProcHistogramGrid.RowHeight = {'1x'};
            else
                app.ProcHistogramGrid.RowHeight = {'1x', '1x'};
            end
        end
    end
end

