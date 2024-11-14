classdef histograms
    %HISTOGRAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = histograms(inputArg1,inputArg2)
            %HISTOGRAMS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function [value, limit, pct] = get(histogram)
            component_name = sprintf("%s_hist_slider", ...
                Program.Handlers.handles.ch_pfx{histogram});

            value = app.(component_name).Value;
            limit = app.(component_name).Limits(2);
            pct = [value(1)/limit value(2)/limit];
        end
    end
end

