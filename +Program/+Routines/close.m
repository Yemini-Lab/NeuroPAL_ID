function close()
    app = Program.app;

    % Program.Legacy.UnselectNeuron();
    
    if ~isempty(app.id_file) && exist(app.id_file, 'file')
        % Program.Legacy.SaveIDToFile();
    end

    if Program.states.get('has_activity')
        Program.GUI.Toggles.activity();
        Program.states.set('has_activity');
    end
end

