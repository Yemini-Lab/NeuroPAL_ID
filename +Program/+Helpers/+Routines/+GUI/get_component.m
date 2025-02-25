function component = get_component(component_type, query)
    app = Program.app;

    handlers = {'channels', 'histograms'};
    for h=1:length(handlers)
        handler = Program.Handlers.(handlers{h});
        if any(ismember(component_type, keys(handler.handles)))
            component_string = sprintf(handler.handles{component_type}, query);
            if isprop(app, component_string)
                component = app.(component_string);
                return
            end
        end
    end

    component = [];
end

