function package = global_grab(window, var)
    % Fulfills requests for local variables across AppDesigner apps.

    global_figures = findall(groot, 'Type','figure');
    scope = Program.GUI.get_parent_app(global_figures(strcmp({global_figures.Name}, window)));

    if ~isempty(scope)
        package = scope.(var);
    else
        package = [];
    end
end