function stimulusFileSelectFunction(app)
    % stimulusFileSelectFunction - Handles the selection of a stimulus file
    %
    % Inputs:
    %   app - The App Designer app object (to access UI components like StimulusFileSelect)
    
    % Open a file selection dialog for .txt and .nwb files
    [name, path, ~] = uigetfile('*.txt;*.nwb', 'Select stimulus file');
    
    % If the user cancels the file selection, return early
    if isequal(name, 0) || isequal(path, 0)
        return;
    end

    % Construct the full file path
    stim_file = fullfile(path, name);

    % Update the parent app's LoadStimuliButton.Tag property
    app.parent_app.LoadStimuliButton.Tag = stim_file;

    % Add the selected file to the StimulusFileSelect dropdown list
    app.StimulusFileSelect.Items{end+1} = stim_file;
    app.StimulusFileSelect.ItemsData{end+1} = stim_file;
end
