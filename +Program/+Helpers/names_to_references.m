function references = names_to_references(names)
    references = {};
    for n=1:length(names)
        name = names{n};
        [color, ~] = Program.Handlers.channels.identify_color(name);
        if ~isempty(color)
            references{end+1} = 'None';
        else
            references{end+1} = color;
        end
    end
end

