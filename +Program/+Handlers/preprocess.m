classdef preprocess
    
    properties
    end
    
    methods (Static, Access = public)        
        function load()
        end

        function save_prompt(action)
            app = Program.GUIHandling.app;
            window = Program.GUIHandling.window_fig;

            check = uiconfirm(window, "Do you want to save this operation to the file?", "NeuroPAL_ID", "Options", ["Yes", "No, stick with preview"]);
            if strcmp(check, "Yes")
                app.proc_apply_processing(action);
                if isfield(app.flags, action)
                    app.flags = rmfield(app.flags, action);
                end

            else
                app.flags.(action) = 1;
            end
        end

        function apply(specific_action)
            app = Program.GUIHandling.app;
            window = Program.GUIHandling.window_fig;

            d = uiprogressdlg(window, ...
                "Message", "Updating file...", ...
                "Indeterminate", "off");

            if ~exist('specific_action', 'var')
                switch app.VolumeDropDown.Value
                    case 'Colormap'
                        Methods.ChunkyMethods.apply_colormap(app, fieldnames(app.flags), d); 
                        fEvent.file = app.proc_image.Properties.Source;
                        app.OpenFile(fEvent);  

                    case 'Video'
                        Methods.ChunkyMethods.apply_video(app, fieldnames(app.flags), d);

                end
    
                app.flags = struct();

            else
                switch app.VolumeDropDown.Value
                    case 'Colormap'
                        Methods.ChunkyMethods.apply_colormap(app, {specific_action}, d);
                        fEvent.file = app.proc_image.Properties.Source;
                        app.OpenFile(fEvent);  

                    case 'Video'
                        Methods.ChunkyMethods.apply_video(app, {specific_action}, d);
                end

            end
            
            close(d)
            uiconfirm(window, ...
                "Successfully updated file.", ...
                "NeuroPAL_ID", ...
                "Options", ["OK"]);
        end

        function render()
            app = Program.GUIHandling.app;
            frame = struct('xy', {[]}, 'yz', {[]}, 'xz', {[]});
            rgb = [str2num(app.ProcRDropDown.Value), str2num(app.ProcGDropDown.Value), str2num(app.ProcBDropDown.Value)];

            % Grab current volume.
            raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
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
            actions = fieldnames(app.flags);
            for a=1:length(actions)
                action = actions{a};
                if app.flags.(action) == 1
                    raw.array = Methods.ChunkyMethods.apply_vol(app, action, raw.array);
                end
            end

            Program.GUIHandling.set_gui_limits(app, dims=raw.dims);
            Program.GUIHandling.histogram_handler(app, 'draw', raw.array);
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

        function bool = trimming_frames(actions)
            app = Program.GUIHandling.app;
            bool = ismember('ds', actions) && (app.StartFrameEditField.Value ~= 1 || app.EndFrameEditField.Value~= app.video_info.nt);
        end
    end
end

