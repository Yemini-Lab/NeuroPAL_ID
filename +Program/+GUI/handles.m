classdef handles
    %HANDLES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pp = struct( ...
            'ch_ef', {'proc_c%.f_editfield'}, ...                           % Edit fields.
            'ch_dd', {'proc_c%.f_dropdown'}, ...                            % Dropdowns.
            'ch_cb', {'proc_c%.f_checkbox'}, ...                            % Checkboxes.
            'ch_ref', {'proc_c%.f_ref'}, ...                                % Reference dropdowns.
            'ch_grid', {'EditChannelsGrid'}, ...                            % Grid.
            'ch_button', {'EditChannelsButton'}, ...                        % Edit channel button.
            'ch_down', {{'1', 'down', '⮟'}}, ...                           % Buttons that move channels up in the grid.
            'ch_up', {{'-1', 'up', '⮝'}});                                 % Buttons that move channels down in the grid.
    end
    
    methods (Static, Access = public)
    end
end

