function reference = get_reference(c)
    reference_component = Program.Routines.GUI.get_component('pp_ref', c);
    if isa(reference_component, 'matlab.ui.control.StateButton')
        name = reference_component.Text;
    else
        name = reference_component.Value;
    end

    color_dict = dictionary( ...
            'red', {'#ff0000'}, ...
            'green', {'#00d100'}, ...
            'blue', {'#0000ff'}, ...
            'white', {'#fff'}, ...
            'gfp', {'#ffff00'}, ...
            'dic', {'#6b6b6b'});

    reference = struct( ...
        'name', {name}, ...
        'color', {color_dict{lower(name)}});
end
