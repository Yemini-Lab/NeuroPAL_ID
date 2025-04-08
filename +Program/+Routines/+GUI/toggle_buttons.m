function toggle_buttons()
    % Set up placeholder buttons

    app = Program.GUIHandling.app;
    window = Program.GUIHandling.window_fig;
    button_locations = window.Position;
    
    if any(button_locations <= 0)
        button_locations = window.Position;
    end

    button_locations(1:2) = [1 1];
    
    app.ProcessingButton.Parent = app.ProcessingGridLayout.Parent;
    app.ProcessingButton.Position = button_locations;
    set(app.ProcessingButton, 'Visible', 'on');

    app.IdButton.Parent = app.IdGridLayout.Parent;
    app.IdButton.Position = button_locations;
    set(app.IdButton, 'Visible', 'on');

    app.TrackingButton.Parent = app.VideoGridLayout.Parent;
    app.TrackingButton.Position = button_locations;
    set(app.TrackingButton, 'Visible', 'on');
end

