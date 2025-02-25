function render()
    app = Program.app;
    raw = Program.GUIHandling.get_active_volume(app, 'request', 'all');
    [raw_volume, raw_dims] = Program.Validation.pad_rgb(raw.array);
    
    % Determine the color channel indices.
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
        render_volume(:, :, :, 1) = imadjustn(render_volume(:, :, :, 1), r.settings.low_high_in, r.settings.low_high_out, r.settings.gamma);
    end

    if ~g.bool % Green
        render_volume(:, :, :, 2) = 0;
    else
        render_volume(:, :, :, 2) = imadjustn(render_volume(:, :, :, 2), g.settings.low_high_in, g.settings.low_high_out, g.settings.gamma);
    end

    if ~b.bool % Blue
        render_volume(:, :, :, 3) = 0;
    else
        render_volume(:, :, :, 3) = imadjustn(render_volume(:, :, :, 3), b.settings.low_high_in, b.settings.low_high_out, b.settings.gamma);
    end

    % Add in the white channel.
    if white.bool % White
    
        % Compute the white channel.
        wchannel = raw_volume(:, : , :, white.idx);
    
        % Adjust the gamma.
        if white.settings.gamma ~= 1
            wchannel = imadjustn(wchannel, white.settings.low_high_in, white.settings.low_high_out, white.settings.gamma);
        end
    
        % Add the white channel.
        render_volume = render_volume + repmat(squeeze(wchannel), [1, 1, 1, 3]);
    end
    
    % Add in the DIC channel.
    if dic.bool % DIC
    
        % Compute the DIC channel.
        dic_channel = raw_volume(:, :, :, dic.idx);
    
        % Adjust the gamma.
        if dic.settings.gamma ~= 1
            dic_channel = imadjustn(dic_channel, dic.settings.low_high_in, dic.settings.low_high_out, dic.settings.gamma);
        end
    
        % Add the DIC channel.
        render_volume = render_volume + repmat(squeeze(dic_channel), [1, 1, 1, 3]);
    end
    
    % Add in the GFP channel.
    if gfp.bool % GFP
    
        % Compute the GFP channel.
        gfp_color = Program.GUIPreferences.instance().GFP_color;
        gfp_channel = raw_volume(:, :, :, gfp.idx);
    
        % Adjust the gamma.
        if gfp.settings.gamma ~= 1
            gfp_channel = imadjustn(gfp_channel, gfp.settings.low_high_in, gfp.settings.low_high_out, gfp.settings.gamma);
        end
    
        % Add the GFP channel.
        gfp_channel = repmat(squeeze(gfp_channel), [1, 1, 1, 3]);
        gfp_channel(:, :, :, ~gfp_color) = 0;
        render_volume = render_volume + gfp_channel;
    end

    for c=1:length(other)
        if other{c}.bool
            other_channel = raw_volume(:, :, :, other{c}.idx);
            other_channel = repmat(squeeze(other_channel), [1, 1, 1, 3]);
            for rgb=1:3
                other_channel(:, :, :, rgb) = other_channel(:, :, :, rgb) * other{c}.color(rgb);
            end
            render_volume = render_volume + other_channel;
        end
    end
    
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
            Program.Handlers.loading.start(sprintf("Applying %s...", action));
            render_volume = Methods.ChunkyMethods.apply_vol(app, action, render_volume);
        end
    end

    Program.GUIHandling.set_gui_limits(app, dims=raw_dims);
    Program.Handlers.histograms.draw();
    Program.GUIHandling.shorten_knob_labels(app);

    if app.ProcShowMIPCheckBox.Value
        image(squeeze(max(render_volume, [], 3)), 'Parent', app.proc_xyAxes);
    else
        image(squeeze(render_volume), 'Parent', app.proc_xyAxes);
    end

    if app.ProcPreviewZslowCheckBox.Value
        image(flipud(rot90(squeeze(render_volume(x, :, :, :, :)))), 'Parent', app.proc_xzAxes);
        image(squeeze(render_volume(:, y, :, :, :)), 'Parent', app.proc_yzAxes);
    end
end

