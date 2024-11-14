classdef preprocess
    
    properties
    end
    
    methods
        
        function load(path)
            app = Program.GUIHandling.app();
            Program.Handlers.dialogues.create('progress', 'Message', 'Initializing Processing Tab...');
        
            if Program.states.instance().is_video
                metadata = Program.Handlers.preprocess.load_video(path);
            else
                metadata = Program.Handlers.preprocess.load_colorstack(path);
            end

            Program.GUIHandling.set_thresholds(app, max_val);
            Program.Handlers.channels.set_idx(metadata.channels.order)
            Program.Handlers.channels.set_gammas(metadata.gammas);
            daspect(app.proc_xyAxes, [1 1 1]);
            
            if nc < 4
                app.ProcHistogramGrid.RowHeight = {'1x'};
            end
            
            Program.GUI.set_limits( ...
                'nx', metadata.nx, ...
                'ny', metadata.ny, ...
                'nz', metadata.nz, ...
                'nt', metadata.nt)

            app.ProcXYFactorEditField.Enable = 'on';
            app.ProcZSlicesEditField.Enable = 'on';
            
            set(app.proc_xEditField, 'Enable', 'off');
            set(app.proc_yEditField, 'Enable', 'off');

            Program.Handlers.preprocess.render();
            app.drawProcImage();
            
            app.ImageProcessingTab.Tag = 'rendered';
            set(app.ProcessingButton, 'Visible', 'off');
            set(app.ProcessingGridLayout, 'Visible', 'on');
            
            app.TabGroup.SelectedTab = app.ImageProcessingTab;
            close(d)
            
            check = uiconfirm(app.CELL_ID, "We recommend starting by cropping your image to ensure that there is no superfluous space taking up memory. Do you want to do so now?", "NeuroPAL_ID", "Options", ["Yes", "No, skip cropping."]);
            switch check
                case "Yes"
                    app.ProcCropImageButtonPushed([]);
                    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
                case "No, skip cropping."
                    app.drawProcImage();
                    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
            end
            
            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
        end

        function metadata = load_colorstack(path)
            Program.GUIHandling.enable_volume('Colormap');
    
            DataHandling.Lazy.file.is_lazy(1);
    
            if ~strcmp(ext, '.mat')
                DataHandling.Lazy.file.read(path);
                [filepath, ~] = DataHandling.Lazy.file.create_cache();
            elseif isfile(strrep(path, ext, '.mat'))
                DataHandling.Lazy.file.reload(path);
            end
    
            app.proc_image = matfile(filepath);
            prefs = app.proc_image.prefs;
    
            if ~isempty(prefs.RGBW)
                chan_order = string(prefs.RGBW);
            else
                chan_order = ['1',  '2', '3', '4', '5', '6'];
            end
            
            if size(prefs.gamma) < 3 
                gammas = [1 1 1 1 1 1];
            else
                gammas = prefs.gamma;
            end
        
            vol_size = size(app.proc_image, 'data');
        
            nx = vol_size(2);
            ny = vol_size(1);
            nz = vol_size(3);
            nc = vol_size(4);
        
            % Using intmax is faster as it avoids
            % loading the entire variable, but it also
            % distorts the histograms.
            % max_val = double(intmax(class(app.proc_image.data(1, 1, 1, 1))));
            max_val = double(max(app.proc_image.data, [], 'all'));
        
            app.VolumeDropDown.Value = 'Colormap';
            app.data_flags.('NeuroPAL_Volume') = 1;
        end

        function metadata = load_video(path)
            Program.GUIHandling.enable_volume('Video');
            app.video_path = path;
    
            if strcmp(ext, '.h5')
                app.load_h5(path);
            elseif strcmp(ext, '.nwb')
                app.load_nwb(path);
            elseif strcmp(ext, '.nd2')
                app.load_nd2(path);
            end
            
            nx = app.video_info.nx;
            ny = app.video_info.ny;
            nz = app.video_info.nz;
            nc = app.video_info.nc;
    
            chan_order = [];
            gammas = [];
    
            test_frame = app.retrieve_frame(3);
            max_val = double(intmax(class(test_frame)));
    
            d.Message = "Configuring processing GUI...";
            app.ProcTStartEditField.Value = 1;
            app.ProcTStopEditField.Value = app.video_info.nt;
            app.proc_tSlider.Limits = [1 app.video_info.nt];
            app.proc_tSlider.Value = 1;
    
            app.ProcAxGrid.RowHeight{end+1} = 'fit';
            app.PlaceholderProcTimeline.Parent = app.ProcAxGrid;
            app.PlaceholderProcTimeline.Layout.Row = max(size(app.ProcAxGrid.RowHeight));
            app.PlaceholderProcTimeline.Layout.Column = [1 max(size(app.ProcAxGrid.ColumnWidth))];
            
            app.VolumeDropDown.Value = 'Video';
            app.data_flags.('Video_Volume') = 1;
    
            set(app.PlaceholderProcTimeline, 'Visible', 'on');
        end

        function render()
            Program.GUI.toggle_loading(app.proc_xyAxes);            
            Program.Handlers.histograms.reset();
            rgb = Program.Handlers.channels.rgb;

            % Grab current volume.
            raw = Program.Handlers.active_volume.all;
            [raw.array, raw.dims] = Program.Validation.pad_rgb(raw.array);
            
            if strcmp(raw.state, 'colormap')
                t_array = raw.array;
                raw.array = uint16(double(intmax('uint16')) * double(raw.array)/double(max(raw.array(:))));
                raw.array = double(raw.array)/double(max(raw.array(:)));
                threshold_value = (app.ProcNoiseThresholdKnob.Value/double(max(t_array, [], 'all')))*double(max(raw.array, [], 'all'));
            else
                threshold_value = app.ProcNoiseThresholdKnob.Value;
            end

            % Threshold.
            raw.array(raw.array < threshold_value) = 0;
            
            % For each channel...
            for c=1:raw.dims(4)
                % ...Adjust the gamma & histogram.
                c_gamma = Program.Handlers.channels.gamma(c);
                [~, ~, h_pct] = Program.Handlers.histogram.get(c);
                
                channel = raw.array(:, :, :, c, :);
                raw.array(:, :, :, c, :) = imadjustn(channel, h_pct, [], c_gamma);
                
                if ~ismember(c, rgb)
                    raw.array(:, :, :, rgb) = raw.array(:, :, :, rgb) + repmat(raw.array(:, :, :, c, :), [1, 1, 1, 3]);
                    raw.array(:, :, :, c, :) = [];
                end
            end

            raw.array = Program.Handlers.preprocess.apply(raw.array);

            Program.GUI.set_limits( ...
                'nx', raw.dims(1), ...
                'ny', raw.dims(2), ...
                'nz', raw.dims(3), ...
                'nt', raw.dims(4));

            Program.Handlers.histograms.update();
            Program.GUIHandling.shorten_knob_labels(app);

            if Program.states.instance().is_mip
                image(squeeze(max(raw.array,[],3)), ...
                    'Parent', app.proc_xyAxes);
            else
                image(squeeze(raw.array), ...
                    'Parent', app.proc_xyAxes);
            end

            if Program.states.instance().is_zpreview
                image(flipud(rot90(squeeze(raw.array(x,:,:,:,:)))), ...
                    'Parent', app.proc_xzAxes);

                image(squeeze(raw.array(:,y,:,:,:)), ...
                    'Parent', app.proc_yzAxes);

                Program.Handlers.preprocess.render_cursor(x, y, z, nz);
            end

            Program.GUI.toggle_loading(app.proc_xyAxes);
        end

        function apply(arr)
            app = Program.GUI.app;
            actions = fieldnames(app.flags);

            for a=1:length(actions)
                action = actions{a};
                if app.flags.(action) == 1
                    arr = Methods.ChunkyMethods.apply_vol(app, action, arr);
                end
            end
        end

        function render_cursor(x, y, z, nz)
            app = Program.GUI.app;
            color = Program.GUI.cursor_color;
            width = Program.GUI.cursor_width;

            app.proc_xy_yline = yline(app.proc_xyAxes, x, ...
                '--', 'color', color, 'LineWidth', width);
            
            app.proc_yz_yline = yline(app.proc_yzAxes, x, ...
                '--', 'color', color, 'LineWidth', width);

            app.proc_xz_yline = yline(app.proc_xzAxes, app.proc_xzAxes.YLim(2)*(z/nz), ...
                '--', 'color', color, 'LineWidth', width);

            app.proc_xy_xline = xline(app.proc_xyAxes, y, ...
                '--', 'color', color, 'LineWidth', width);

            app.proc_yz_xline = xline(app.proc_yzAxes, app.proc_yzAxes.XLim(2)*(z/nz), ...
                '--', 'color', color, 'LineWidth', width);
            
            app.proc_xz_xline = xline(app.proc_xzAxes, y, ...
                '--', 'color', color, 'LineWidth', width);
        end
    end
end

