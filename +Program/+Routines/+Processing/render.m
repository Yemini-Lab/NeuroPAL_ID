function render()
    raw_volume = Program.GUIHandling.active_volume.get_array;
    
    % Determine the color channel indices.
    [r, g, b, white, dic, gfp] = Program.Handlers.channels.parse_channel_gui();
    
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
        if w.settings.gamma ~= 1
            wchannel = imadjustn(wchannel, white.settings.low_high_in, white.settings.low_high_out, white.settings.gamma);
        end
    
        % Add the white channel.
        render_volume = render_volume + repmat(wchannel, [1, 1, 1, 3]);
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
        render_volume = render_volume + repmat(dic_channel, [1, 1, 1, 3]);
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
        gfp_channel = repmat(gfp_channel, [1, 1, 1, 3]);
        gfp_channel(:, :, :, ~gfp_color) = 0;
        render_volume = render_volume + gfp_channel;
    end
    
    % Adjust the gamma.
    % Note: the image only shows RGB. We added the other channels
    % (W, DIC, GFP) to the RGB in order to show these as well.
    render_volume = uint16(double(intmax('uint16')) * ...
        double(render_volume)/double(max(render_volume(:))));
    render_volume = double(render_volume)/double(max(render_volume(:)));

    % Apply processing operations.
    actions = fieldnames(app.flags);
    for a=1:length(actions)
        action = actions{a};
        if app.flags.(action) == 1
            render_volume = Methods.ChunkyMethods.apply_vol(app, action, render_volume);
        end
    end

    Program.GUIHandling.set_gui_limits(app, dims=size(raw_volume));
    Program.GUIHandling.histogram_handler(app, 'draw', render_volume);
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

