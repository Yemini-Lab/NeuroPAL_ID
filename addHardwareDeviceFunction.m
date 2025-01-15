function addHardwareDeviceFunction(app)
    % addHardwareDeviceFunction - Handles the logic for adding a hardware device
    %
    % Inputs:
    %   app - The App Designer app object (to access UI components like NameEditField, ManufacturerEditField, and HardwareDescriptionTextArea)
    
    % Create a device structure with user input
    device = struct(...
        'name', char(app.NameEditField.Value), ...
        'manu', char(app.ManufacturerEditField.Value), ...
        'desc', char(app.HardwareDescriptionTextArea.Value));
    
    % Call the device handler with the 'add' action
    Program.GUIHandling.device_handler(app, 'add', device);
end
