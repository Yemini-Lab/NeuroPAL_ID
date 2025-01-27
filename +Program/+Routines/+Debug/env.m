classdef env
    %ENV Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        toolboxes = struct( ...
            'Statistics and Machine Learning Toolbox', {0}, ...
            'NeurodataWithoutBorders/matnwb', {0}, ...
            'Signal Processing Toolbox', {0}, ...
            'Image Processing Toolbox', {0}, ...
            'MATLAB Compiler', {0}, ...
            'MATLAB Coder', {0});

        pylibs = struct( ...
            'zephir', {0}, ...
            'docopt', {0}, ...
            'tensorflow', {0});
    end
    
    methods (Static, Access = public)
        function tb_struct = check_toolboxes()
            tb_struct = Program.Routines.Debug.env.toolboxes;
            all_tb = fieldnames(tb_struct);
            env = ver.Name;

            for tb=1:length(all_tb)
                toolbox = all_tb{tb};
                tb_struct.(toolbox) = ~ismember(toolbox, env);
            end
        end

        function py_struct = check_python()
            py_struct = Program.Routines.Debug.env.toolboxes;
            all_py = fieldnames(py_struct);

            for tb=1:length(all_py)
                library = all_py{tb};

                try
                    py.importlib.import_module(library)
                    is_present = 1;
                catch
                    is_present = 0;
                end

                py_struct.(library) = is_present;
            end
        end

    end
end

