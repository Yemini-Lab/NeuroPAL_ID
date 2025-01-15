function removeDeviceFunction(app)
    % removeDeviceFunction - Handles the logic for removing a selected device
    %
    % Inputs:
    %   app - The App Designer app object (to access DeviceUITable and trigger remove functionality)
    
    % Check if a selection exists in the table
    if isempty(app.DeviceUITable.Selection)
        error('No device selected. Please select a device to remove.');
    end

    % Call the device handler for the 'remove' action
    Program.GUIHandling.device_handler(app, 'remove', app.DeviceUITable.Selection);
end
