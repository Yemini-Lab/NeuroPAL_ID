function set_manipulation_panel(state)
    app = Program.app;
    panel_gui = struct( ...
        'default', {{'ProcCropImageButton', 'RotateButton', 'DownsampleButton'}}, ...
        'rotate', {{'flip_lr', 'flip_ud', 'proc_rot_knob', 'proc_rot_spinner', 'proc_rot_panel'}}, ...
        'downsample', {{'proc_ds_panel'}});
    
    switch state
        case 'rotate'
            new_panel_height = 200;
            Program.GUIHandling.clear_rotation_preview_cache(app);
            Program.GUIHandling.cache_rotation_preview_base(app);
            Program.GUIHandling.reset_rotation_controls(app);

            for h=1:length(panel_gui.rotate)
                app.(panel_gui.rotate{h}).Visible = 'on';
            end

            for h=1:length(panel_gui.default)
                app.(panel_gui.default{h}).Enable = 'off';
            end

        case 'downsample'
            if strcmp(app.VolumeDropDown.Value, 'Colormap')
                new_panel_height = 147;
            else
                new_panel_height = 192;
            end

            app.proc_ds_panel.Visible = "on";
            Program.GUIHandling.install_processing_downsample_callbacks(app);

            for h=1:length(panel_gui.default)
                app.(panel_gui.default{h}).Enable = 'off';
            end
            
        case 'closed'
            new_panel_height = 72;
            Program.GUIHandling.clear_rotation_preview_cache(app);
            Program.GUIHandling.reset_rotation_controls(app);
            app.RotateButton.Enable = 'on';
            app.DownsampleButton.Enable = 'on';
            app.proc_ds_panel.Visible = 'off';

            for h=1:length(panel_gui.rotate)
                app.(panel_gui.rotate{h}).Visible = 'off';
            end

            for h=1:length(panel_gui.default)
                app.(panel_gui.default{h}).Enable = 'on';
            end

        otherwise
    end

    row_index = app.ImageManipulationPanel.Layout.Row;
    temp_height = app.ProcSideGrid.RowHeight;
    temp_height{row_index} = new_panel_height;
    app.ProcSideGrid.RowHeight = temp_height;
end
