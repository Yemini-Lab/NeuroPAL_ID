classdef components < handle
    %COMPONENTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x_handles = dictionary( ...
            'Video Tracking', {'xEditField'}, ...
            'Image Processing', {'proc_xSlider'});

        y_handles = dictionary( ...
            'Video Tracking', {'yEditField'}, ...
            'Image Processing', {'proc_ySlider'});

        z_handles = dictionary( ...
            'NeuroPAL ID', {'ZSlider'}, ...
            'Video Tracking', {'hor_zSlider'}, ...
            'Image Processing', {'proc_zSlider'});
        
        t_handles = dictionary( ...
            'Video Tracking', {'tSlider'}, ...
            'Image Processing', {'proc_tSlider'});
    end
    
    methods
        function obj = components()
            %obj.sync();
        end

        function sync(obj)
            components = Program.GUI.scan();
            for c=1:length(components)
                component = components{c};
                tag = component.Tag;
                if ~isempty(tag) && flag_shortcut(tag)
                    handle = obj.get_handle(component);
                    interface = obj.get_interface(component);
                    insert(obj.(tag), interface, handle);
                end
            end
        end
    end

    methods (Static, Access = public)
        function handle = x()
            handle = Program.GUI.components.x_handles{Program.states.interface};
        end

        function handle = y()
            handle = Program.GUI.components.y_handles{Program.states.interface};
        end
        
        function handle = z()
            handle = Program.GUI.components.z_handles{Program.states.interface};
        end

        function handle = t()
            handle = Program.GUI.components.t_handles{Program.states.interface};
        end
    end
end

