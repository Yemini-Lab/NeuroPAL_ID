function set_gammas(source)
    app = Program.app;
    pfxs = {'tl', 'tm', 'tr', 'ml', 'bm', 'br'};

    if isa(source, 'volume')
        for c=1:length(pfxs)
            handle = sprintf("%s__GammaEditField", pfxs{c});
            app.(handle).Value = source.channels{c}.gamma;
        end

    elseif isempty(source)
        for c=1:length(pfxs)
            handle = sprintf("%s__GammaEditField", pfxs{c});
            app.(handle).Value = Program.config.defaults{'gamma'};
        end
        
    elseif isnumeric(source)

        if isscalar(source)
            for c=1:length(source)
                handle = sprintf("%s__GammaEditField", pfxs{c});
                app.(handle).Value = source;
            end

        else 
            for c=1:length(source)
                handle = sprintf("%s__GammaEditField", pfxs{c});
                app.(handle).Value = source(c);
            end
        end
        
    end
end

