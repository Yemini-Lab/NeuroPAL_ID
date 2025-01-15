function removeOpticalChannelFunction(app)
    % removeOpticalChannelFunction - Handles removing a selected optical channel
    %
    % Inputs:
    %   app - The App Designer app object (to access the OpticalUITable and handle removal)

    % Ensure a selection exists in the OpticalUITable
    if isempty(app.OpticalUITable.Selection)
        uialert(app.UIFigure, 'No optical channel selected. Please select a channel to remove.', 'Error');
        return;
    end

    % Call the channel handler for the 'remove' action with the selected channel
    Program.GUIHandling.channel_handler(app, 'remove', app.OpticalUITable.Selection);
end
