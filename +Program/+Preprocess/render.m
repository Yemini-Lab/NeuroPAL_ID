function frame = render()
            app = Program.GUIHandling.app;
            frame = struct('xy', {[]}, 'yz', {[]}, 'xz', {[]});
            rgb = [str2num(app.ProcRDropDown.Value), str2num(app.ProcGDropDown.Value), str2num(app.ProcBDropDown.Value)];

            % Grab current volume.
            raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
            channels = Program.GUIHandling.get_channel_data;
            raw.array = raw.array(:, :, :, channels);

            if raw.dims(4) < 3
                raw.array = cat(4, raw.array, zeros([raw.dims(1:3) 1]));
            end
            
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
                c_gamma = sprintf("%s_GammaEditField", Program.GUIHandling.pos_prefixes{c});
                c_hist = sprintf("%s_hist_slider", Program.GUIHandling.pos_prefixes{c});
                slider_vals = app.(c_hist).Value; hist_limit = app.(c_hist).Limits(2);
                
                raw.array(:, :, :, c, :) = imadjustn(raw.array(:, :, :, c, :), [slider_vals(1)/hist_limit slider_vals(2)/hist_limit], [], app.(c_gamma).Value);
                
                if ~ismember(c, rgb)
                    raw.array(:, :, :, rgb) = raw.array(:, :, :, rgb) + repmat(raw.array(:, :, :, c, :), [1, 1, 1, 3]);
                    raw.array(:, :, :, c, :) = [];
                end
            end

            % Apply processing operations.
            raw.array = Program.Preprocess.apply_actions(raw.array);

            Program.GUIHandling.set_gui_limits(app, dims=raw.dims);
            Program.Handlers.histogram.update();
            Program.GUIHandling.shorten_knob_labels(app);

            if app.ProcShowMIPCheckBox.Value
                frame.xy = squeeze(max(raw.array,[],3));
            else
                frame.xy = squeeze(raw.array);
            end

            if app.ProcPreviewZslowCheckBox.Value
                frame.xz = squeeze(raw.array(:,y,:,:,:));
                frame.yz = squeeze(raw.array(x,:,:,:,:));
            end
        end