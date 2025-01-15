function buttonPushedFunction(app)
    % buttonPushedFunction - Handles the logic for the button push
    %
    % Inputs:
    %   app - The App Designer app object (to access OpticalUITable and properties like F1, F2, F3)
    
    % Append new data to the OpticalUITable
    newRow = [app.F1, app.F2, app.F3];
    app.OpticalUITable.Data(end+1, :) = newRow; % Add new row to the table
end
