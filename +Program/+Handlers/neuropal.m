classdef neuropal
    
    properties
    end
    
    methods
        function initialize(file, prefs)
            app = Program.app;

            if nargin < 2
                prefs = file.prefs;
            end

            app.image_file = np_file;
            app.id_file = [];
            app.image_prefs = prefs;
        end

        function load_gamma(prefs)
            app = Program.app;

            if nargin == 0
                prefs = app.image_prefs;
            end

            gamma_size = length(app.gamma_RGBW_DIC_GFP_index);
            
            if isscalar(prefs.gamma)
                app.image_gamma = ones(gamma_size, 1);
                app.image_gamma(1:3) = prefs.gamma;
                app.image_prefs.gamma = app.image_gamma;

            elseif length(prefs.gamma) < gamma_size
                app.image_gamma = ones(gamma_size, 1);
                app.image_gamma(1:length(prefs.gamma)) = prefs.gamma;
                app.image_prefs.gamma = app.image_gamma;

            else
                app.image_gamma = prefs.gamma;
                
            end

            Program.Handlers.channels.set_gamma(app.image_gamma);
        end
    end
end

