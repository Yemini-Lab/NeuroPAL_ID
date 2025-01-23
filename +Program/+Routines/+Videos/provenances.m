classdef provenances
    %PROVENANCES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static, Access = public)
        function provenances = get(new_prov)
            persistent current_prov

            if nargin > 0
                current_prov = new_prov;
            elseif isempty(current_prov)
                current_prov = Program.Routines.Videos.cache.get().provenances;
            end

            provenances = current_prov;
        end

        function add(name, cache)            
            if nargin < 2
                cache = Program.Routines.Videos.cache.get();
                cache.Writable = true;
            end

            provenances = cache.provenances;
            provenances{end+1} = name;
            cache.provenances = provenances;

            if nargin < 2
                cache.Writable = false;
                Program.Routines.Videos.cache.save(cache);
            end
        end

        function provenance = find(provenance_id)            
            cache = Program.Routines.Videos.cache.get();
            provenance = cache.provenances(:, provenance_id);
            provenance = provenance{:};
        end
    end
end

