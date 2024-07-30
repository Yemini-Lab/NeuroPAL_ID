classdef ChunkyMethods
    % Processing functions that support lazy read/write.

    %% Public variables.
    properties (Constant, Access = public)
        npal_id;
        npal_gui;

        spectral_cache;             % Saves previous unmixing parameters.
    end

    methods (Static)
        function globalize(app, gui)
            Methods.ChunkyMethods.npal_id = app;
            Methods.ChunkyMethods.npal_gui = gui;
        end

        function spectral_unmix(ctx)
            % Remove spectral crosstalk of images based on a linear spectral crosstalk remover.
            
            % Grab parent app & lock image processing tab.
            app = Methods.ChunkyMethods.npal_id.ProcColormapButton.Value;
            channel = ctx.Source.Tag;
            app.proc_lock('lock');

            % Check if we've saved unmixing parameters. If not, initialize.
            if ~exist('Methods.ChunkyMethods.spectral_cache', 'var')
                Methods.ChunkyMethods.spectral_cache = struct('ch_db', [], 'ch_px', {}, 'ch_val', {}, 'bg_px', [], 'bg_val', [], 'blurred_img', []);
            end


            % Grab channel indices.
            ch_idx = [app.RDropDown.Value, app.GDropDown.Value, app.BDropDown.Value, app.WDropDown.Value];
            
            % Grab channel gammas.
            gammas = [app.tl_GammaEditField.Value, app.tm_GammaEditField.Value, app.tr_GammaEditField.Value, app.bl_GammaEditField.Value, app.bm_GammaEditField.Value, app.br_GammaEditField.Value];

            check = uiconfirm(app.UIFigure,sprintf('Click on the pixel on this slice that best represents %s.', channel),'Confirmation','Options',{'OK', 'Select different slice'},'DefaultOption','OK');

            switch check
                case 'OK'
                    color_roi = drawpoint(app.proc_xyAxes);
                    pos = round(color_roi.Position);
                    delete(color_roi);

                    pixels = [pos(1), pos(2), round(app.proc_zSlider.Value)];

                    r = impixel(app.image_data(:,:,app.proc_zSlider.Value, ch_idx(1)), pos(1), pos(2));
                    g = impixel(app.image_data(:,:,app.proc_zSlider.Value, ch_idx(2)), pos(1), pos(2));
                    b = impixel(app.image_data(:,:,app.proc_zSlider.Value, ch_idx(3)), pos(1), pos(2));

                    switch channel
                        case 'r'
                            t_idx = ch_idx(1);
                            app.red_r.Value = r(1);
                            app.red_g.Value = g(1);
                            app.red_b.Value = b(1);
                        case 'g'
                            t_idx = ch_idx(2);
                            app.green_r.Value = r(1);
                            app.green_g.Value = g(1);
                            app.green_b.Value = b(1);
                        case 'b'
                            t_idx = ch_idx(3);
                            app.blue_r.Value = r(1);
                            app.blue_g.Value = g(1);
                            app.blue_b.Value = b(1);
                        case {'w', 'gfp', 'dic', 'gut'}
                            % TBD
                    end

                    if ~ismember(channel, Methods.ChunkyMethods.spectral_cache.ch_db)
                        Methods.ChunkyMethods.spectral_cache.ch_db = [Methods.ChunkyMethods.spectral_cache.ch_db, t_idx];
                    end

                    Methods.ChunkyMethods.spectral_cache.ch_px{t_idx} = pixels;

                case 'Select different slice'
                    app.proc_lock('unlock');
                    return
            end

            % If necessary, grab background.
            if ~isempty(Methods.ChunkyMethods.spectral_cache.bg_px)
                bg_pixels = Methods.ChunkyMethods.spectral_cache.bg_px;
            else
                uiconfirm(app.UIFigure,'Click on the pixel on this slice that best represents background.','Confirmation','Options',{'OK'},'DefaultOption','OK');
                color_roi = drawpoint(app.proc_xyAxes);
                pos = round(color_roi.Position);
                delete(color_roi);

                bg_pixels = [pos(1), pos(2), round(app.proc_zSlider.Value)];
                Methods.ChunkyMethods.spectral_cache.bg_px = bg_pixels;
            end

            loc_pixel = [pixels; bg_pixels];

            if ~isempty(Methods.ChunkyMethods.spectral_cache.blurred_img)
                sigma_gauss = 0.0001;
            else
                Methods.ChunkyMethods.spectral_cache.blurred_img = 1;
            end

            if app.ProcColormapButton.Value
                vol = app.proc_image.data(:);
            elseif app.ProcVideoButton.Value
                vol = app.retrieve_frame(app.proc_tSlider.Value);
            end

            rgb = ch_idx(1:3);
            vol = double(Methods.Preprocess.zscore_frame(vol));
            vol(vol<0) = 0;

            og_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            
            % Stack relevant channels and normalize.
            filtered_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            for i = 1:length(rgb)
                filtered_vol(i,:,:,:) = imgaussfilt3(vol(:,:,:,rgb(i))./max(vol(:,:,:,rgb(i)),[],'all').*65535, sigma_gauss);
                og_vol(i,:,:,:) = vol(:,:,:,rgb(i));
            end

            % Construct background array (based on last row of loc_pixels).
            Methods.ChunkyMethods.spectral_cache.bg_val = double(mean(filtered_vol(:,loc_pixel(end,2)-size_selection:loc_pixel(end,2)+size_selection,loc_pixel(end,1)-size_selection:loc_pixel(end,1)+size_selection,loc_pixel(end,3)),[2,3]));
            for ii=1:size(Methods.ChunkyMethods.spectral_cache.bg_val)
                filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - Methods.ChunkyMethods.spectral_cache.bg_val(ii); 
            end
            
            % Compute linear scaling for spectral crosstalk.
            Methods.ChunkyMethods.spectral_cache.ch_val = mean(filtered_vol(:,loc_pixel(1,2)-size_selection:loc_pixel(1,2)+size_selection,loc_pixel(1,1)-size_selection:loc_pixel(1,1)+size_selection,loc_pixel(1,3)),[2,3]);
            Methods.ChunkyMethods.spectral_cache.ch_val(channels_to_debleed) = Methods.ChunkyMethods.spectral_cache.ch_val(channels_to_debleed)/Methods.ChunkyMethods.spectral_cache.ch_val(~channels_to_debleed);
            Methods.ChunkyMethods.spectral_cache.ch_val(~channels_to_debleed) = Methods.ChunkyMethods.spectral_cache.ch_val(~channels_to_debleed)/Methods.ChunkyMethods.spectral_cache.ch_val(~channels_to_debleed);

            app.flags.debleed = 1;
            app.drawProcImage();
        end

        function output = debleed(vol, mode)
            % Check whether to use cache values or cache coords.
            if ~exist('mode', 'var')
                if ~isempty(Methods.ChunkyMethods.spectral_cache.ch_val)
                    mode = 'val';
                else
                    mode = 'coord';
                end
            end

            % Back up full volume.
            output = vol;

            % Grab processing tab values.
            app = Methods.ChunkyMethods.npal_id.ProcColormapButton.Value;
            ch_idx = [app.RDropDown.Value, app.GDropDown.Value, app.BDropDown.Value, app.WDropDown.Value];
            rgb = ch_idx(1:3);

            % Normalize volume.
            vol = double(Methods.Preprocess.zscore_frame(vol));
            vol(vol<0) = 0;
            
            % Stack relevant channels and normalize.
            filtered_vol = zeros(length(rgb), size(vol,1),size(vol,2),size(vol,3));
            for i = 1:length(rgb)
                filtered_vol(i,:,:,:) = imgaussfilt3(vol(:,:,:,rgb(i))./max(vol(:,:,:,rgb(i)),[],'all').*65535, sigma_gauss);
            end

            switch mode
                case 'val'
                    % Remove background noise.
                    for ii=1:size(Methods.ChunkyMethods.spectral_cache.bg_val)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - Methods.ChunkyMethods.spectral_cache.bg_val(ii); 
                    end

                    % Debleed.
                    for ii = 1:length(Methods.ChunkyMethods.spectral_cache.ch_db)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - Methods.ChunkyMethods.spectral_cache.ch_db(ii)*Methods.ChunkyMethods.spectral_cache.ch_val(ii)* filtered_vol(~Methods.ChunkyMethods.spectral_cache.ch_db,:,:,:);
                    end
                case 'coord'

                    % Construct background array
                    bg = double(mean(filtered_vol(:,Methods.ChunkyMethods.spectral_cache.bg_px(2)-size_selection:Methods.ChunkyMethods.spectral_cache.bg_px(2)+size_selection,Methods.ChunkyMethods.spectral_cache.bg_px(1)-size_selection:Methods.ChunkyMethods.spectral_cache.bg_px(1)+size_selection,Methods.ChunkyMethods.spectral_cache.bg_px(3)),[2,3]));
                    for ii=1:size(bg)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - bg(ii); 
                    end

                    loc_pixel = [Methods.ChunkyMethods.spectral_cache.ch_px{1};Methods.ChunkyMethods.spectral_cache.ch_px{2};Methods.ChunkyMethods.spectral_cache.ch_px{3}];

                    % Compute linear scaling for spectral crosstalk.
                    scale_crosstalk = mean(filtered_vol(:,loc_pixel(1,2)-size_selection:loc_pixel(1,2)+size_selection,loc_pixel(1,1)-size_selection:loc_pixel(1,1)+size_selection,loc_pixel(1,3)),[2,3]);
                    scale_crosstalk(Methods.ChunkyMethods.spectral_cache.ch_db) = scale_crosstalk(Methods.ChunkyMethods.spectral_cache.ch_db)/scale_crosstalk(~Methods.ChunkyMethods.spectral_cache.ch_db);
                    scale_crosstalk(~Methods.ChunkyMethods.spectral_cache.ch_db) = scale_crosstalk(~Methods.ChunkyMethods.spectral_cache.ch_db)/scale_crosstalk(~Methods.ChunkyMethods.spectral_cache.ch_db);
                    
                    % Debleed.
                    for ii = 1:length(Methods.ChunkyMethods.spectral_cache.ch_db)
                        filtered_vol(ii,:,:,:) = filtered_vol(ii,:,:,:) - Methods.ChunkyMethods.spectral_cache.ch_db(ii)*scale_crosstalk(ii)* filtered_vol(~Methods.ChunkyMethods.spectral_cache.ch_db,:,:,:);
                    end
            end

            % Normalize corrected image again.
            for i = 1:length(ch_idx)
                filtered_vol(i,:,:,:) = uint16(filtered_vol(i,:,:,:)./max(filtered_vol(i,:,:,:),[],'all').*65535);
            end

            % Permute image to get same format as input.
            filtered_vol = permute(filtered_vol, [4,2,3,1]);
            filtered_vol = permute(filtered_vol,[2,3,1,4]);
            filtered_vol = Methods.Preprocess.zscore_frame(filtered_vol);

            % Replace OG RGB channels and return resulting array.
            output(:,:,:,rgb(1)) = filtered_vol(:,:,:,1);
            output(:,:,:,rgb(2)) = filtered_vol(:,:,:,2);
            output(:,:,:,rgb(3)) = filtered_vol(:,:,:,3);
        end
    end
end