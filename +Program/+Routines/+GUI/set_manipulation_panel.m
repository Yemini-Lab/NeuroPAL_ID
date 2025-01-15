function set_manipulation_panel(state)
    app = Program.app;
    panel_gui = struct( ...
        'default', {{'ProcCropImageButton', 'RotateButton', 'DownsampleButton'}}, ...
        'rotate', {{'flip_lr', 'flip_ud', 'proc_rot_knob', 'proc_rot_spinner', 'proc_rot_panel'}}, ...
        'downsample', {{'proc_ds_panel'}});
    
    switch state
        case 'rotate'
            new_panel_height = 200;

            for h=1:length(panel_gui.rotate)
                app.(panel_gui.rotate{h}).Visible = 'on';
            end

            for h=1:length(panel_gui.default)
                app.(panel_gui.default{h}).Enable = 'off';
            end

        case 'downsample'
            new_panel_height = 147;
            app.proc_ds_panel.Visible = "on";

            for h=1:length(panel_gui.default)
                app.(panel_gui.default{h}).Enable = 'off';
            end
            
        case 'closed'
            new_panel_height = 72;
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

    temp_height = app.ProcSideGrid.RowHeight;
    temp_height{3} = new_panel_height;
    app.ProcSideGrid.RowHeight = temp_height;
end

