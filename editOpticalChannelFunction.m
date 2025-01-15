function editOpticalChannelFunction(app, channel)
    % editOpticalChannelFunction - Handles editing an optical channel
    %
    % Inputs:
    %   app     - The App Designer app object
    %   channel - The optical channel to be edited (passed from the selection in the UI)
    
    % Validate that the channel is provided
    if isempty(channel)
        error('No channel selected. Please select a channel to edit.');
    end

    % Call the channel handler for the 'edit' action
    Program.GUIHandling.channel_handler(app, 'edit', channel);
end
