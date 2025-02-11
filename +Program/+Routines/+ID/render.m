function render()
    %% Draw the annotated image (image volume & neuron markers).

    app = Program.app;

    % Is there an image?
    if isempty(app.image_data)
        return;
    end

    app.logEvent('Main','Drawing image...', 1);

    % Determine the color channel indices.
    red = str2double(app.RDropDown.Value);
    green = str2double(app.GDropDown.Value);
    blue = str2double(app.BDropDown.Value);
    white = str2double(app.WDropDown.Value);
    dic = str2double(app.DICDropDown.Value);
    gfp = str2double(app.GFPDropDown.Value);

    % Determine the channel=color assignments for displaying.
    color_indices = [red, green, blue];

    % Draw the 3 color channels.
    app.image_view = app.image_data(:,:,:,color_indices);

    % Remove unchecked color channels.
    if ~app.RCheckBox.Value % Red
        app.image_view(:,:,:,1) = 0;
    end
    if ~app.GCheckBox.Value % Green
        app.image_view(:,:,:,2) = 0;
    end
    if ~app.BCheckBox.Value % Blue
        app.image_view(:,:,:,3) = 0;
    end

    % Add in the white channel.
    if app.WCheckBox.Value % White

        % Compute the white channel.
        wchannel = app.image_data(:,:,:,white);

        % Adjust the gamma.
        W_i = app.gamma_RGBW_DIC_GFP_index(4); % white channel gamma index
        if length(app.image_gamma) >= W_i && app.image_gamma(W_i) ~= 1
            wchannel = imadjustn(wchannel,[],[], app.image_gamma(W_i));
        end

        % Add the white channel.
        app.image_view = app.image_view + repmat(wchannel, [1,1,1,3]);
    end

    % Add in the DIC channel.
    if app.DICCheckBox.Value % DIC

        % Compute the DIC channel.
        dic_channel = app.image_data(:,:,:,dic);

        % Adjust the gamma.
        DIC_i = app.gamma_RGBW_DIC_GFP_index(5); % DIC channel gamma index
        if length(app.image_gamma) >= DIC_i && app.image_gamma(DIC_i) ~= 1
            dic_channel = imadjustn(dic_channel,[],[], app.image_gamma(DIC_i));
        end

        % Add the DIC channel.
        app.image_view = app.image_view + repmat(dic_channel, [1,1,1,3]);
    end

    % Add in the GFP channel.
    if app.GFPCheckBox.Value % GFP

        % Compute the GFP channel.
        gfp_color = Program.GUIPreferences.instance().GFP_color;
        gfp_channel = app.image_data(:,:,:,gfp);

        % Adjust the gamma.
        GFP_i = app.gamma_RGBW_DIC_GFP_index(6); % GFP channel gamma index
        if length(app.image_gamma) >= GFP_i && app.image_gamma(GFP_i) ~= 1
            gfp_channel = imadjustn(gfp_channel,[],[], app.image_gamma(GFP_i));
        end

        % Add the GFP channel.
        gfp_channel = repmat(gfp_channel, [1,1,1,3]);
        gfp_channel(:,:,:,~gfp_color) = 0;
        app.image_view = app.image_view + gfp_channel;
    end

    % Adjust the gamma.
    % Note: the image only shows RGB. We added the other channels
    % (W, DIC, GFP) to the RGB in order to show these as well.
    app.image_view = uint16(double(intmax('uint16')) * ...
        double(app.image_view)/double(max(app.image_view(:))));
    for c = 1:size(app.image_view, 4)
        if app.image_gamma(c) ~= 1
            app.image_view(:,:,:,c) = ...
                imadjustn(squeeze(app.image_view(:,:,:,c)),[],[], ...
                app.image_gamma(c));
        end
    end
    app.image_view = double(app.image_view)/double(max(app.image_view(:)));

    % Redraw the max projection.
    % Note: the image only shows RGB. We added the other channels
    % (W, DIC, GFP) to the RGB in order to show these as well.
    image(app.MaxProjection, squeeze(max(app.image_view,[],3)));

    % Redraw the Z-slice.
    Program.Routines.ID.get_slice(app.ZSlider, app.image_view, app.XY);
end

