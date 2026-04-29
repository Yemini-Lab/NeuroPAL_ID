function save()
    app = Program.app;
    actions = Program.GUIHandling.processing_file_actions(app);

    switch app.VolumeDropDown.Value
        case 'Colormap'
            if ~isempty(actions)
                Program.Helpers.apply_processing_preview_action(app, actions);
            end

            Program.Helpers.sync_main_display_from_processing(app, false);
            Program.Helpers.write_processing_colormap_to_file(app);
            Program.Routines.Processing.render();
            Program.Routines.ID.render();

        case 'Video'
            if ~isempty(actions)
                Program.Handlers.dialogue.add_task('Updating file...');
            end
            Methods.ChunkyMethods.apply_video(app, actions);
            if ~isempty(actions)
                Program.Handlers.dialogue.resolve();
            end
    end

    app.flags = struct();
    Methods.ChunkyMethods.clear_spectral_filtered_cache(app);
    if isappdata(app.CELL_ID, 'proc_mip_cache')
        rmappdata(app.CELL_ID, 'proc_mip_cache');
    end
    if isappdata(app.CELL_ID, 'proc_view_cache')
        rmappdata(app.CELL_ID, 'proc_view_cache');
    end
    if isappdata(app.CELL_ID, 'proc_render_cache')
        rmappdata(app.CELL_ID, 'proc_render_cache');
    end
    if isappdata(app.CELL_ID, 'proc_raw_cache')
        rmappdata(app.CELL_ID, 'proc_raw_cache');
    end
    if isappdata(app.CELL_ID, 'proc_histogram_signature')
        rmappdata(app.CELL_ID, 'proc_histogram_signature');
    end
    if isappdata(app.CELL_ID, 'proc_render_view_dims')
        rmappdata(app.CELL_ID, 'proc_render_view_dims');
    end
end
