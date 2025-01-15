function cancelButtonFunction(app)
    % cancelButtonFunction - Handles the logic for the Cancel button
    %
    % Inputs:
    %   app - The App Designer app object (to access parent_app and other properties)
    
    % Initialize the NWB data structure
    nwb_data = struct();
    nwb_data.proceed = 0;
    
    % Call the process_nwb_data method of the parent app
    app.parent_app.process_nwb_data(nwb_data);
    
    % Close/delete the current app
    delete(app);
end
