classdef channel < dynamicprops

    properties
        parent = [];                    % Reference to this channel's associated volume object.
        fluorophore = '';               % Name of this channel's associated fluorophore. Program.Handlers.channels.fluorophore_map is a dictionary whose every key is a color (e.g. 'red', 'blue', 'white', 'gfp') and whose corresponding value is a cell array of possible fluorophores that produce this color.
        index = -1;                     % Index of this channel in its parent volume. -1 if uninitialized.
        color = '';

        is_rgb = -1;                    % Boolean indicating whether this channel is one of red, green, or blue.
        is_known = -1;                  % Boolean indicating whether this channel is associated with a fluorophore that is named somewhere in Program.Handlers.channels.fluorophore_map.
        is_rendered = -1;               % Boolean indicating whether this channel's checkbox (referenced in gui{'checkbox'}) is currently checked.

        lh_out = [];                    % This is an array of size (1, 2) whose first value is calculated by dividing the lower value of the gui{'sliders'} component by the limit of the gui{'histogram'} component, and whose second value is calculated by doing the same with the higher value of the gui{'sliders'} component.
        lh_In = [];                     % Empty array.
        gamma = -1;                     % Float that is equal to the value of the gui{'gamma_field'} component.

        excitation = dictionary( ...    % Dictionary describing excitation values of this channel.
            'lambda', {-1}, ...
            'high', {-1}, ...
            'low', {-1});

        emission = dictionary( ...      % Dictionary describing emission values of this channel.
            'lambda', {-1}, ...
            'high', {-1}, ...
            'low', {-1});

        gui = dictionary( ...           % Dictionary referencing the gui components associated with this channel. Program.app returns the handle of the app these components are attached to. Component handles follow the patterns "proc_cN_X" where N is channel.index and X is the component type.
            'reference', {[]}, ...        % app.proc_cX_reference
            'checkbox', {[]}, ...         % app.proc_cX_checkbox
            'dropdown', {[]}, ...         % app.proc_cX_dropdown
            'edit_field', {[]}, ...       % app.proc_cX_editfield
            'histogram', {[]}, ...        % app.proc_cX_histogram
            'sliders', {[]}, ...          % app.proc_cX_sliders
            'gamma_field', {[]});         % app.proc_cX_gamma

        styling = dictionary( ...               % Dictionary describing styling guides for all plotting related to this channel.
            'background-color', {'#fff'}, ...   % Program.Handlers.channels.config{'channel_colors'} is a cell array containing, in order, the background color for red, green, blue, white, dic, and gfp.
            'label-color', {'#000'});           % Program.Handlers.channels.config{'label_colors'} is a cell array containing, in order, the background color for red, green, blue, white, dic, and gfp.
    end

    methods
        function obj = channel(fluorophore)
            obj.fluorophore = fluorophore;
            obj.identify();
        end

        function identify(obj)
            fluorophore_map = Program.Handlers.channels.fluorophore_map;
            known_fluorophores = keys(fluorophore_map);
            obj.color = '???';
            obj.is_rgb = 0;

            for c=1:length(known_fluorophores)
                this_color = known_fluorophores{c};

                these_fluorophores = fluorophore_map{this_color};
                obj.is_known = any(ismember(lower(obj.fluorophore), these_fluorophores));
                if obj.is_known
                    obj.color = this_color;
                    obj.is_rgb = ismember(obj.color, {'red', 'green', 'blue'});
                    return
                end
            end
        end

        function obj = assign_gui(obj)
            obj.gui = Program.GUI.channel_editor.get_components(obj.index);
        end

        function delete_channel(obj)
            Program.states.now('Deleting %s channel (%s)', obj.color, obj.fluorophore);
            Program.GUI.channel_editor.fluorophores('delete', 'name',  obj.fluorophore);
            Program.GUI.channel_editor.colors('delete', 'name',  obj.color);
            Program.GUI.channel_editor.channels('delete', 'idx', obj.index);
            obj.parent.channels(obj.index) = [];
            delete(obj);
        end

        function set(obj, keyword, value)
            if isprop(obj, keyword)
                [is_valid, is_dict] = obj.validate(keyword, value);
                if ~is_valid
                    error("Property %s cannot be set to value %.f of class %s for channel %s.", ...
                        keyword, value, class(value), obj.fluorophore);
                end

                if is_dict && contains(keyword, '/')
                    keyword = keyword.split('/');
                    target_dict = obj.(keyword(1));
                    target_dict{keyword(2)} = value;
                    obj.(keyword(1)) = target_dict;
                else
                    obj.(keyword) = value;
                end

            else
                error('Channel object %s has no property %s to which value %s can be assigned.', obj.fluorophore, keyword, value);
            end
        end

        function [is_valid, is_dict] = validate(~, keyword, value)
            is_dict = 0;
            is_valid = 1;

            switch keyword
                case 'name'
                    is_valid = isstring(value) || ischar(value);
                case 'index'
                    is_valid = isinteger(uint8(value));
                case 'gamma'
                    is_valid = isnumeric(value);
                otherwise
                    if startsWith(keyword, 'lh_')
                        is_valid = 1;
                    elseif startsWith(keyword, 'gui')
                        is_dict = 1;
                        is_valid = isa(value, 'dictionary') || all(ishandle(value) & isgraphics(value));
                    elseif startsWith(keyword, 'styling')
                        is_dict = 1;
                        is_valid = isa(value, 'dictionary') || startsWith(value, '#');
                    elseif startsWith(keyword, 'emission') || startsWith(keyword, 'excitation')
                        is_dict = 1;
                        is_valid = isa(value, 'dictionary') || isinteger(uint8(value));
                    elseif startsWith(keyword, 'is')
                        is_valid = isa(value, 'logical') || ismember(value, [0, 1]);
                    end
            end
        end

        function bool = is_pseudocolor(obj)
            bool = ~obj.is_rgb;
        end

        function frozen_instance = freeze(obj)
            frozen_instance = Program.channel(obj.fluorophore);
            props = ?Program.channel;
            for n=1:length(props.PropertyList)
                p = props.PropertyList(n);
                p_label = p.Name;
                p_default = p.DefaultValue; 

                can_be_frozen = ~ismember(p_label, {'gui', 'parent'});
                if can_be_frozen
                    live_value = obj.(p_label);

                    if ~isequal(p_default, live_value)
                        frozen_instance.set(p_label, live_value);
                    end                    
                end
            end
        end
    end
end