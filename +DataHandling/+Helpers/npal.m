classdef npal
    %NPAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function id_path = create_neurons(varargin)
            p = inputParser();
            addParameter(p, 'file', []);
            addParameter(p, 'volume', []);
            addParameter(p, 'matfile', []);
            parse(p, varargin{:});

            routine = find(cellfun(@(x)(~ismember(x, p.UsingDefaults)), p.Parameters));

            switch routine
                case 1
                    rf = matfile(p.Results.file);

                case 2
                    rf = p.Results.matfile;

                otherwise
                    return
            end

            source = rf.Properties.Source;
            [~, ~, fmt] = fileparts(source);
            id_path = replace(source, fmt, '_ID.mat');

            if isprop(rf, 'worm')
                worm = rf.worm;
            else
                worm = struct('body', {'Head'});
            end

            if isprop(rf, 'info')
                info = rf.info;
                scale = info.scale;
            else
                answer = inputdlg( ...
                    {'xy:', 'z:'}, ...
                    'Define voxel resolution', ...
                    [1, 45], {'1' '1'});
                scale = [str2num(answer{1}), str2num(answer{2})];
            end

            neurons = Neurons.Image([], worm.body, 'scale', scale);
            version = Program.ProgramInfo.version;

            mp_params = [];
            mp_params.hnsz = round(round(3./info.scale')/2)*2+1;
            if size(mp_params.hnsz,1) > 1
                mp_params.hnsz = mp_params.hnsz';
            end
            mp_params.k = 0;
            mp_params.exclusion_radius = 1.5;
            mp_params.min_eig_thresh = 0.1;

            save(id_path, 'version', 'neurons', 'mp_params', '-v7.3');
        end
    end
end

