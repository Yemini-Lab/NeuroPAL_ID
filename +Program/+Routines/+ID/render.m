function render()
    %% Draw the annotated image (image volume & neuron markers).

    app = Program.app;

    % Is there an image?
    if isempty(app.image_data)
        return;
    end

    app.logEvent('Main','Drawing image...', 1);

    state = Program.Handlers.channels.main_state(app);
    Program.Helpers.debug_event('IDRender', ...
        'channels rgb=[%d %d %d] w=%d dic=%d gfp=%d checks=%s gamma=%s image_size=%s', ...
        state.r.idx, state.g.idx, state.b.idx, ...
        state.white.idx, state.dic.idx, state.gfp.idx, ...
        mat2str([state.r.bool state.g.bool state.b.bool ...
                 state.white.bool state.dic.bool state.gfp.bool]), ...
        mat2str(app.image_gamma(:)'), ...
        mat2str(size(app.image_data)));
    package = Program.Helpers.get_display_volume(app, 'main', app.image_data);
    app.image_view = package.display_volume;
    Program.Helpers.debug_array_summary('IDRender', 'image_view', app.image_view);

    % Redraw the max projection.
    % Note: the image only shows RGB. We added the other channels
    % (W, DIC, GFP) to the RGB in order to show these as well.
    image(app.MaxProjection, squeeze(max(app.image_view,[],3)));

    % Redraw the Z-slice.
    Program.Routines.ID.get_slice(app.ZSlider, app.image_view, app.XY);
end
