classdef settings
    %SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)        
        function threshold = threshold(idx)
            app = Program.GUIHandling.app;

            if ~exist('idx', 'var')
                idx = 1:2;
            end
            
            threshold = app.ProcNoiseThresholdKnob.Limits(idx);
        end
    end
end

