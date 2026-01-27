function render()
    app = Program.app;

    Program.Handlers.dialogue.step('Loading target chunk...');
    raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
    [raw_volume, raw_dims] = Program.Validation.pad_rgb(raw.array);
    
    % Determine the color channel indices.
    Program.Handlers.dialogue.step('Parsing channel data...');
    [r, g, b, white, dic, gfp, other] = Program.Handlers.channels.parse_channel_gui();
    [x, y, z, t] = Program.Routines.Processing.parse_gui(); 
    
    % Determine the channel=color assignments for displaying.
    color_indices = [r.idx, g.idx, b.idx];
    
    % Draw the 3 color channels.
    render_volume = raw_volume(:, :, :, color_indices);

    % Remove unchecked color channels.
    if ~r.bool % Red
        render_volume(:, :, :, 1) = 0;
    else
        Program.Handlers.dialogue.step('Computing red channel...');
        if r.settings.gamma < 0.01; r.settings.gamma = 1; end
        render_volume(:, :, :, 1) = imadjustn(render_volume(:, :, :, 1), r.settings.low_high_in, r.settings.low_high_out, r.settings.gamma);
    end

    if ~g.bool % Green
        render_volume(:, :, :, 2) = 0;
    else
        Program.Handlers.dialogue.step('Computing green channel...');
        if g.settings.gamma < 0.01; g.settings.gamma = 1; end
        render_volume(:, :, :, 2) = imadjustn(render_volume(:, :, :, 2), g.settings.low_high_in, g.settings.low_high_out, g.settings.gamma);
    end

    if ~b.bool % Blue
        render_volume(:, :, :, 3) = 0;
    else
        Program.Handlers.dialogue.step('Computing blue channel...');
        if b.settings.gamma < 0.01; b.settings.gamma = 1; end
        render_volume(:, :, :, 3) = imadjustn(render_volume(:, :, :, 3), b.settings.low_high_in, b.settings.low_high_out, b.settings.gamma);
    end

    % Add in the white channel.
    if white.bool % White
        Program.Handlers.dialogue.step('Computing white channel...');

        % Compute the white channel.
        wchannel = raw_volume(:, : , :, white.idx);
    
        % Adjust the gamma.
        if white.settings.gamma ~= 1
            if white.settings.gamma < 0.01; white.settings.gamma = 1; end
            wchannel = imadjustn(wchannel, white.settings.low_high_in, white.settings.low_high_out, white.settings.gamma);
        end
    
        % Add the white channel.
        render_volume = render_volume + repmat(squeeze(wchannel), [1, 1, 1, 3]);
    end
    
    % Add in the DIC channel.
    if dic.bool % DIC
        Program.Handlers.dialogue.step('Computing DIC channel...');

        % Compute the DIC channel.
        dic_channel = raw_volume(:, :, :, dic.idx);
    
        % Adjust the gamma.
        if dic.settings.gamma ~= 1
            if dic.settings.gamma < 0.01; dic.settings.gamma = 1; end
            dic_channel = imadjustn(dic_channel, dic.settings.low_high_in, dic.settings.low_high_out, dic.settings.gamma);
        end
    
        % Add the DIC channel.
        render_volume = render_volume + repmat(squeeze(dic_channel), [1, 1, 1, 3]);
    end
    
    % Add in the GFP channel.
    if gfp.bool % GFP
        Program.Handlers.dialogue.step('Computing GFP channel...');
    
        % Compute the GFP channel.
        gfp_color = Program.GUIPreferences.instance().GFP_color;
        gfp_channel = raw_volume(:, :, :, gfp.idx);
    
        % Adjust the gamma.
        if gfp.settings.gamma ~= 1
            if gfp.settings.gamma < 0.01; gfp.settings.gamma = 1; end
            gfp_channel = imadjustn(gfp_channel, gfp.settings.low_high_in, gfp.settings.low_high_out, gfp.settings.gamma);
        end
    
        % Add the GFP channel.
        gfp_channel = repmat(squeeze(gfp_channel), [1, 1, 1, 3]);
        gfp_channel(:, :, :, ~gfp_color) = 0;
        render_volume = render_volume + gfp_channel;
    end

    for c=1:length(other)
        if other{c}.bool
            Program.Handlers.dialogue.step('Processing unknown channel...');

            other_channel = raw_volume(:, :, :, other{c}.idx);
            other_channel = repmat(squeeze(other_channel), [1, 1, 1, 3]);
            for rgb=1:3
                other_channel(:, :, :, rgb) = other_channel(:, :, :, rgb) * other{c}.color(rgb);
            end
            render_volume = render_volume + other_channel;
        end
    end

    render_volume(render_volume < app.ProcNoiseThresholdField.Value) = 0;
    
    % Adjust the gamma.
    % Note: the image only shows RGB. We added the other channels
    % (W, DIC, GFP) to the RGB in order to show these as well.
    volume_max = double(max(render_volume, [], 'all'));
    render_volume = uint16(double(intmax('uint16')) * double(render_volume)/volume_max);
    render_volume = double(render_volume)/double(max(render_volume(:)));

    % Apply processing operations.
    actions = fieldnames(app.flags);
    for a=1:length(actions)
        action = actions{a};
        if app.flags.(action) == 1
            msg = sprintf("Applying %s...", action);
            Program.Handlers.dialogue.step(msg)
            Program.Handlers.loading.start(msg);
            render_volume = Methods.ChunkyMethods.apply_vol(app, action, render_volume);
        end
    end

    Program.GUIHandling.set_gui_limits(app, dims=raw_dims);
    Program.Handlers.dialogue.step('Drawing histograms...');
    Program.Handlers.histograms.draw();
    Program.GUIHandling.shorten_knob_labels(app);

    Program.Handlers.dialogue.step('Rendering volume data...');
    if app.ProcShowMIPCheckBox.Value
        frame = squeeze(max(render_volume, [], 3));
    else
        z_idx = min(max(round(z), 1), size(render_volume, 3));
        frame = squeeze(render_volume(:, :, z_idx, :));
    end

    % Ensure frame is displayable.
    if ndims(frame) == 2
        image(frame, 'Parent', app.proc_xyAxes);
    elseif ndims(frame) == 3
        if size(frame, 3) >= 3
            if size(frame, 3) > 3
                frame = frame(:, :, 1:3);
            end
            image(frame, 'Parent', app.proc_xyAxes);
        else
            msg = sprintf('Processing render: unexpected frame size %s', mat2str(size(frame)));
            fprintf('%s\n', msg);
            try
                app.logEvent('Processing', msg, 0);
            catch
            end
            error('Processing render: invalid frame size %s', mat2str(size(frame)));
        end
    else
        msg = sprintf('Processing render: unexpected frame size %s', mat2str(size(frame)));
        fprintf('%s\n', msg);
        try
            app.logEvent('Processing', msg, 0);
        catch
        end
        error('Processing render: invalid frame size %s', mat2str(size(frame)));
    end

    if app.ProcPreviewZslowCheckBox.Value
        image(flipud(rot90(squeeze(render_volume(x, :, :, :, :)))), 'Parent', app.proc_xzAxes);
        image(squeeze(render_volume(:, y, :, :, :)), 'Parent', app.proc_yzAxes);
    end
end
