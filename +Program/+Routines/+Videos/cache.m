classdef cache
    %CACHE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        default = struct( ...
                'wl_record', {{}}, ...
                'worldlines', {{}}, ...
                'provenances', {{}}, ...
                'frames', {double([0 0 0 0 0 0 0])});
    end
    
    methods (Static, Access = public)
        function cache_file = get(new_cache)
            persistent current_cache

            if nargin == 1
                current_cache = matfile(new_cache, 'Writable', true);
                current_cache.path = new_cache;
                Program.Routines.Videos.cache.save(current_cache);
                Program.Routines.Videos.worldlines.get(current_cache.worldlines);

            else
                if isempty(current_cache)
                    current_cache = Program.Routines.Videos.cache.default();
                end
            end

            cache_file = current_cache;
        end

        function track_cache = create(cache_path)            
            track_cache = Program.Routines.Videos.cache.default();
            save(cache_path, "-struct", "track_cache", '-v7.3');
            Program.Routines.Videos.cache.get(cache_path);
        end

        function load(cache)
            if nargin == 0
                cache = Program.Routines.Videos.cache.get();
            end

            Program.Routines.Videos.wl_record.get(cache.wl_record);
            Program.Routines.Videos.worldlines.get(cache.worldlines);
            Program.Routines.Videos.provenances.get(cache.provenances);
        end

        function save(cache)
            if nargin == 0
                cache = Program.Routines.Videos.tracks.cache();
            end

            if isa(cache, "matlab.io.MatFile")
                cache = struct( ...
                    'frames', {double(cache.frames)}, ...
                    'path', {cache.path}, ...
                    'provenances', {cache.provenances}, ...
                    'wl_record', {cache.wl_record}, ...
                    'worldlines', {cache.worldlines});
            end

            save(cache.path, "-struct", "cache", '-v7.3');
        end

        function code = check_for_existing(path)
            if exist(path, "file") == 2
                check = uiconfirm(Program.window, ...
                    "Found existing neuron track cache. Load or build from scratch?", "NeuroPAL_ID", ...
                    "Options", ["Load from cache", "Build new"]);

                if strcmp(check, "Build new")
                    delete(path);
                    Program.Routines.Videos.cache.create(path);
                    code = 0;

                else
                    Program.Routines.Videos.tracks.load(path);
                    code = 1;
                end
            else
                Program.Routines.Videos.cache.create(path);
                code = 0;
            end
        end
    end
end

