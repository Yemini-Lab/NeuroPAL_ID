% Add SaveButtonPushed Function Below
function saveButtonFunction(app)
    % saveButtonFunction - Handles Save Button logic
    %
    % Inputs:
    %   app - The App Designer app object (to access properties like app.CustomFileName)

    % Progress dialog
    d = uiprogressdlg(app.SaveasNWBFileUIFigure, 'Title', 'Saving NWB file...', 'Indeterminate', 'off');
    GUI_prefs = Program.GUIPreferences.instance();

    % Determine save path
    if ~isempty(app.CustomFileName.Value)
        if ~endsWith(app.CustomFileName.Value, '.nwb')
            path = fullfile(GUI_prefs.image_dir, [app.CustomFileName.Value, '.nwb']);
        else
            path = fullfile(GUI_prefs.image_dir, app.CustomFileName.Value);
        end
    else
        [~, og_name, ~] = fileparts(app.image_file);
        path = fullfile(GUI_prefs.image_dir, [og_name, '.nwb']);
    end 

   


    % Call the writeNWB function
    code = DataHandling.writeNWB.write_order(app, path, d);
    close(d);

    % Handle the result
    switch code
        case 0
            check = uiconfirm(app.SaveasNWBFileUIFigure, sprintf('Saved file to %s', path), 'Success!', 'Options', ['Close']);

            % Additional actions
            if app.OpenDANDIaftersavingCheckBox.Value
                web('https://www.dandiarchive.org/');
            end

            if strcmp(check, 'Close')
                delete(app);
            end

        otherwise
            % Handle other cases (if any)
            disp('Error occurred while saving.');
    end
end