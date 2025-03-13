classdef histogram_editor < handle
    %HISTOGRAM_EDITOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pfx = {'tl', 'tm', 'tr', 'bl', 'bm', 'br'};
        patterns = struct( ...
            'slider', {"%s_hist_slider"}, ...
            'gamma', {"%s_GammaEditField"}, ...
            'axes', {"%s_hist_ax"});
    end

    methods
        function obj = histogram_editor()
            persistent he_components

            if isempty(he_components)
                he_components = obj;
            end

            obj = he_components;
        end
    end
    
    methods (Static, Access = public)
        function gui = request_gui(query)
            stack = dbstack;
            source = stack(2).name;
            valid_source = 'channel.assign_gui';

            if strcmp(source, valid_source)
                gui = Program.GUI.histogram_editor.get_gui(query);
            else
                error("Protected property %s from class %s may " + ...
                    "only be accessed from within %s, but was" + ...
                    "accessed from within %s.", ...
                    'gui', 'histogram_editor', valid_source, source);
            end
        end
    end

    methods (Static, Access = private)
        function gui = get_gui(idx)
            if nargin == 0
                gui = {};
                for n=1:6
                    gui{end+1} = Program.GUI.histogram_editor.get_gui(n);
                end

                return
            end

            app = Program.app;
            obj = Program.GUI.histogram_editor();
            t_pfx = obj.pfx{idx};

            gui = struct();
            gui.gamma = app.(sprintf(obj.patterns.gamma, t_pfx));
            gui.histogram = app.(sprintf(obj.patterns.axes, t_pfx));
            gui.slider = app.(sprintf(obj.patterns.slider, t_pfx));
        end
    end
end

