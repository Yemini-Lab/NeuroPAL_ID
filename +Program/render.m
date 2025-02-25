classdef render
    %RENDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end

    methods (Static, Access = public)
        function obj = render(volume)
            if nargin == 0
                volume = Program.states.active_volume;
            end

            switch Program.states.interface
                case "NeuroPAL ID"
                    obj.stack(volume);
                case "Video Tracking"
                    obj.video(volume);
                case "Image Processing"
                    obj.processing(volume);
            end
        end

        function stack(volume)
            if nargin == 0
                volume = Program.states.active_volume;
            end

            render = Program.render.calculate_channels(volume);
            [render, maximum_intensity_projection] = Program.render.draw_mip(render);

            image(app.MaxProjection, squeeze(maximum_intensity_projection));
            Program.Routines.ID.get_slice(app.ZSlider, render, app.XY);
        end
        
        function video(volume)
            if nargin == 0
                volume = Program.states.active_volume;
            end

            render = Program.render.calculate_channels(volume);
            [render, maximum_intensity_projection] = Program.render.draw_mip(render);
        end

        function processing(volume)
            if nargin == 0
                volume = Program.states.active_volume;
            end

            render = Program.render.calculate_channels(volume);
            [render, maximum_intensity_projection] = Program.render.draw_mip(render);

            actions = fieldnames(app.flags);
            for a=1:length(actions)
                action = actions{a};
                if app.flags.(action) == 1
                    Program.Handlers.loading.start(sprintf("Applying %s...", action));
                    render = Methods.ChunkyMethods.apply_vol(app, action, render);
                end
            end

            Program.GUIHandling.set_gui_limits(app, dims=volume.dims);
            Program.Handlers.histograms.draw();
            Program.GUIHandling.shorten_knob_labels(app);
        
            if Program.states.mip
                image(squeeze(maximum_intensity_projection), ...
                    'Parent', app.proc_xyAxes);
            else
                image(squeeze(render), ...
                    'Parent', app.proc_xyAxes);
            end
        
            if app.ProcPreviewZslowCheckBox.Value
                image(flipud(rot90(squeeze(render(x, :, :, :, :)))), ...
                    'Parent', app.proc_xzAxes);
                image(squeeze(render(:, y, :, :, :)), ...
                    'Parent', app.proc_yzAxes);
            end
        end
    end

    methods (Access = private)
        function array = calculate_channels(volume)
            array = volume.read(cursor);

            for c=1:volume.nc
                channel = volume.channels{c};
                if ~channel.is_rendered
                    array(:, :, :, channel.index) = 0;
                else
                    array(:, :, :, channel.index) = imadjustn(array(:, :, :, channel.index), channel.lh_in, channel.lh_out, channel.gamma);
                    if ~channel.is_rgb
                        channel_array = array(:, :, :, channel.index);
                        pseudocolor_array = Program.render.generate_pseudocolor(channel_array, channel);
                        array(:, :, :, volume.rgb) = array(:, :, :, volume.rgb) + pseudocolor_array;
                    end
                end
            end

            array = array(:, :, :, volume.rgb);
        end

        function pseudocolor_array = generate_pseudocolor(array, channel)
            pseudocolor_array = repmat(squeeze(array), [1, 1, 1, 3]);

            switch channel.color
                case 'gfp'
                    gfp_color = Program.GUIPreferences.instance().GFP_color;
                    pseudocolor_array(:, :, :, ~gfp_color) = 0;

                otherwise
                    for c = 1:3
                        rgb_modifier = 1 - channel.color(c);
                        pseudocolor_array(:, :, :, c) = pseudocolor_array(:, :, :, c) * rgb_modifier;
                    end
            end
        end

        function [render, maximum_intensity_projection] = draw_mip(render)
            maximum_intensity_projection = double(max(render, [], 'all'));
            render = uint16(double(intmax('uint16')) * double(render)/maximum_intensity_projection);
            render = double(render)/double(max(render(:)));
        end
    end
end

