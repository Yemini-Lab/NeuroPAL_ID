classdef histograms
    
    properties (Constant)
        handles = dictionary( ...
            'panels', {"%s_hist_panel"}, ...
            'labels', {"%s_Label"}, ...
            'axes', {"%s_hist_ax"});

        prefixes = {'tl', 'tm', 'tr', 'bl', 'bm', 'br'};
    end
    
    methods (Static)
        function reset(pfx)
            if nargin == 0
                prefixes = Program.Handlers.histograms.prefixes;

                for n=1:length(prefixes)
                    Program.Handlers.histograms.reset(prefixes{n});
                end

                return
            end

            component = Program.Routines.GUI.get_component('panels', pfx);
            component.Visible = 'off';
            cla(Program.Routines.GUI.get_component('axes', pfx))
        end
        
        function draw()
            app = Program.app;
            raw = Program.Handlers.histograms.get_source_array(app);
            state = Program.Handlers.channels.processing_state(app);
            rows = state.rows([state.rows.source_idx] > 0);

            Program.Handlers.histograms.reset();
            Program.GUIHandling.apply_processing_responsive_layout(app);

            for n = 1:numel(rows)
                row = rows(n);
                chan_hist = Program.Helpers.to_user_uint8(raw.array(:, :, :, row.source_idx));
                [h_panel, h_label, h_axes] = Program.Handlers.histograms.get_gui(row.row);
                h_panel.Visible = 'on';
                h_label.Text = sprintf("%s Channel", row.role_name);

                if app.HidezerointensitypixelsCheckBox.Value
                    chan_hist = chan_hist(chan_hist > 0);
                end

                cla(h_axes);
                if isempty(chan_hist)
                    Program.Handlers.histograms.set_histogram_xlim(app, h_axes);
                else
                    Program.Handlers.histograms.draw_histogram_series(h_axes, chan_hist, row.color);
                    Program.Handlers.histograms.set_histogram_xlim(app, h_axes);
                end
            end

            Program.GUIHandling.update_processing_histogram_interactivity(app);
        end
    end

    methods(Static, Access=private)
        function raw = get_source_array(app)
            state = Program.Handlers.channels.processing_state(app);
            max_idx = state.max_source_idx;
            if max_idx < 1
                raw = struct('array', zeros(0, 0, 0, 0));
                return
            end

            if strcmp(app.VolumeDropDown.Value, 'Colormap') && ...
                    app.ProcShowMIPCheckBox.Value && ...
                    isappdata(app.CELL_ID, 'proc_raw_cache')
                cache = getappdata(app.CELL_ID, 'proc_raw_cache');
                signature = Program.Helpers.processing_raw_signature(app);
                if isstruct(cache) && isfield(cache, 'signature') && strcmp(cache.signature, signature)
                    raw = cache.raw;
                    return
                end
            end

            switch string(app.VolumeDropDown.Value)
                case "Colormap"
                    context = Program.Helpers.processing_colormap_context(app);
                    prefs = context.prefs;
                    max_idx = min(max_idx, context.dims(4));
                    if max_idx < 1
                        raw = struct('array', zeros(0, 0, 0, 0));
                        return
                    end
                    if app.ProcShowMIPCheckBox.Value
                        array = Program.Helpers.read_processing_colormap(app, ...
                            'channels', 1:max_idx, ...
                            'z', app.proc_zSlider.Value, ...
                            'mip', true);
                    else
                        nz_data = context.dims(3);
                        z_gui = Program.Helpers.gui_z_to_data_index(app.proc_zSlider.Value, nz_data, false);
                        z_idx = Program.Helpers.gui_z_to_data_index( ...
                            z_gui, nz_data, ...
                            isfield(prefs, 'is_Z_flip') && prefs.is_Z_flip);
                        array = Program.Helpers.read_processing_colormap(app, ...
                            'channels', 1:max_idx, ...
                            'z', z_idx, ...
                            'mip', false);
                    end

                case "Video"
                    views = app.retrieveVideoRenderViews( ...
                        app.proc_tSlider.Value, ...
                        app.proc_zSlider.Value, ...
                        min(max(round(app.proc_ySlider.Value), 1), app.video_info.ny), ...
                        min(max(round(app.proc_xSlider.Value), 1), app.video_info.nx), ...
                        app.ProcShowMIPCheckBox.Value);
                    frame = views.xy;
                    max_idx = min(max_idx, size(frame, 3));
                    if app.ProcShowMIPCheckBox.Value
                        array = reshape(frame(:, :, 1:max_idx), ...
                            size(frame,1), size(frame,2), 1, max_idx);
                    else
                        array = reshape(frame(:, :, 1:max_idx), ...
                            size(frame,1), size(frame,2), 1, max_idx);
                    end

                otherwise
                    raw = Program.GUIHandling.get_active_volume(app, 'request', 'array');
                    return
            end

            raw = struct('array', array);
        end

        function [h_panel, h_label, h_axes] = get_gui(c)
            app = Program.app;

            if c > Program.Handlers.channels.config{'max_channels'}
                c = Program.Helpers.first_unchecked_channel();
            end

            h_panel = Program.Routines.GUI.get_component('panels', Program.Handlers.histograms.prefixes{c});
            h_label = Program.Routines.GUI.get_component('labels', Program.Handlers.histograms.prefixes{c});
            h_axes = Program.Routines.GUI.get_component('axes', Program.Handlers.histograms.prefixes{c});
        end

        function set_histogram_xlim(app, h_axes)
            lower_bound = 0;
            if app.HidezerointensitypixelsCheckBox.Value
                lower_bound = 1;
            end
            h_axes.XLim = [lower_bound, 255];
        end

        function draw_histogram_series(h_axes, chan_hist, color)
            counts = histcounts(double(chan_hist(:)), -0.5:255.5);
            centers = 0:255;
            bar(h_axes, centers, counts, 1, ...
                'FaceColor', color, ...
                'EdgeColor', 'none');
        end
    end
end
