function hot_neuron_reset()
    %% Update the neuron lists.
    app = Program.app;
    
    % Is the worm a male?
    is_male = contains(lower(app.worm.sex), 'xo');

    % Find the male tail node.
    tree = app.GanglionTree;
    names = {tree.Children.Text};
    male_i = find(strcmp(names,'Male Tail'));

    % Add the male tail.
    if is_male && isempty(male_i)

        % Unselect all ganglia & neurons.
        app.GanglionTree.SelectedNodes = [];

        % Remove the hermaphrodite tail.
        hermaphrodite_i = find(strcmp(names,'Tail'));
        if ~isempty(hermaphrodite_i)
            tree.Children(hermaphrodite_i).delete();
        end

        % Add the male tail.
        app.neuron_info = Neurons.Male;
        ganglia = uitreenode(tree,'Text','Male Tail');
        uitreenode(ganglia,'Text','Pre-Anal (L)');
        uitreenode(ganglia,'Text','Pre-Anal (R)');
        uitreenode(ganglia,'Text','Rays (L)');
        uitreenode(ganglia,'Text','Rays (R)');
        uitreenode(ganglia,'Text','Dorso-Rectal');
        uitreenode(ganglia,'Text','Cloacal (L)');
        uitreenode(ganglia,'Text','Cloacal (R)');
        uitreenode(ganglia,'Text','Lumbar (L)');
        uitreenode(ganglia,'Text','Lumbar (R)');

        % Remove the male tail.
    elseif ~is_male && ~isempty(male_i)

        % Unselect all ganglia & neurons.
        app.GanglionTree.SelectedNodes = [];

        % Remove the male tail.
        tree.Children(male_i).delete();

        % Add the hermaphrodite tail.
        app.neuron_info = Neurons.Hermaphrodite;
        ganglia = uitreenode(tree,'Text','Tail');
        uitreenode(ganglia,'Text','Pre-Anal');
        uitreenode(ganglia,'Text','Dorso-Rectal');
        uitreenode(ganglia,'Text','Lumbar (L)');
        uitreenode(ganglia,'Text','Lumbar (R)');
    else
        return
    end


    %% Update the user ID'd neurons.

    % Show the selected neurons.
    selectedNodes = app.GanglionTree.SelectedNodes;
    neurons = {};
    for i = 1:length(selectedNodes)
        node = selectedNodes(i);
        if isempty(node.Children) % Child node on the tree.
            neurons = union(neurons, GetChildNodeNeurons(app, node));
        else % Parent node on the tree.
            neurons = union(neurons, GetParentNodeNeurons(app, node));
        end
    end
    neurons = sort(neurons);

    % None of the neurons have IDs.
    if isempty(app.image_neurons) || isempty(app.image_neurons.neurons)
        app.UserNeuronIDsListBoxLabel.Text = 'User Neuron IDs';
        app.IDdLabel.Text = '     ID''d     ';
        app.UserNeuronIDsListBox.Items = {};
        app.UserNeuronIDsListBox.ItemsData = [];
        app.UnIDdLabel.Text = sprintf('Un-ID''d = %d', length(neurons));
        app.UnIDdNeuronsListBox.Items = neurons;

        % Which neurons have IDs?
    else
        % Show the neuron counts.
        user_id_neurons = app.image_neurons.user_id_neurons();
        app.UserNeuronIDsListBoxLabel.Text = sprintf('User Neuron IDs = %d/%d', ...
            length(user_id_neurons), app.image_neurons.num_neurons());

        % Remove emphasized neurons. They're not really ID'd.
        is_emphasized = vertcat(user_id_neurons.is_emphasized);
        user_id_neurons = user_id_neurons(~is_emphasized);

        % Separate the neurons into those with & without user IDs.
        user_id_names = vertcat({user_id_neurons.annotation});
        [id_neurons, ~, user_id_i] = intersect(neurons, user_id_names);
        unid_neurons =  setdiff(neurons, id_neurons);

        % Keep a copy of the neuron names.
        id_neuron_names = id_neurons;

        % Add ON/OFF & confidences to the neuron names.
        for i = 1:length(user_id_i)

            % Is the neuron ON/OFF?
            switch user_id_neurons(user_id_i(i)).is_annotation_on
                case false
                    id_neurons{i} = [id_neurons{i} '-OFF'];
                case true
                    id_neurons{i} = [id_neurons{i} '-ON'];
            end

            % Is the user uncertain about the ID?
            if user_id_neurons(user_id_i(i)).annotation_confidence <= 0.5
                id_neurons{i} = [id_neurons{i} ' ?'];
            end
        end

        % Add the neuron birth times.
        if Program.GUIPreferences.instance().is_show_birth_times

            % Initialize the neuron info.
            neuron_data = app.hermaphrodite_neurons;
            if contains(lower(app.worm.sex), 'xo')
                neuron_data = app.male_neurons;
            end

            % Add birth times to the ID'd neurons.
            [~, id_i, ~] = intersect(neuron_data.names, id_neuron_names);
            if ~isempty(id_i)
                id_stages = neuron_data.birth_stages(id_i);
                id_neurons = cellfun(@(x,y) ...
                    sprintf('%s (%s)', x, y), ...
                    id_neurons, id_stages, ...
                    'UniformOutput', false);
            end

            % Add birth times to the ID'd neurons.
            [~, unid_i, ~] = intersect(neuron_data.names, unid_neurons);
            if ~isempty(unid_i)
                unid_stages = neuron_data.birth_stages(unid_i);
                unid_neurons = cellfun(@(x,y) ...
                    sprintf('%s (%s)', x, y), ...
                    unid_neurons, unid_stages, ...
                    'UniformOutput', false);
            end
        end

        % Update the GUI.
        black = [0,0,0];
        gray = [0.95,0.95,0.95];
        app.IDdLabel.BackgroundColor = gray;
        app.IDdLabel.FontColor = black;
        app.UnIDdLabel.BackgroundColor = gray;
        app.UnIDdLabel.FontColor = black;
        app.IDdLabel.Text = sprintf('ID''d = %d', length(id_neurons));
        app.IDdNeuronsListBox.Items = id_neurons;
        app.UnIDdLabel.Text = sprintf('Un-ID''d = %d', length(unid_neurons));
        app.UnIDdNeuronsListBox.Items = unid_neurons;
    end
end

