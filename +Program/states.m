function package = states(event)
    persistent current_states
    
    if isempty(current_states)
        current_states = struct('init', {1});
        for s=1:Program.GUIHandling.state_keys
            current_states.(Program.GUIHandling.state_keys{s}) = 0;
        end
    end

    if exist('event', 'var')
        current_states.(event.Source.Tag) = ~current_states.(event.Source.Tag);
    end

    package = current_states;
end

