function editDeviceFunction(app)
    % editDeviceFunction - Handles the logic for editing a selected device
    %
    % Inputs:
    %   app - The App Designer app object (to access DeviceUITable and trigger edit functionality)
    
    % Check if a selection exists in the table
    if isempty(app.DeviceUITable.Selection)
        error('No device selected. Please select a device to edit.');
    end

    % Call the device handler for the 'edit' action
    Program.GUIHandling.device_handler(app, 'edit', app.DeviceUITable.Selection);
end
