classdef ProgramTests

    %% Public variables.
    properties (Constant, Access = public)
        npal_id;
        npal_gui;
        debug_panel;
    end

    methods (Static)
        function startRoutine(app, gui, debug_panel)
            Program.ProgramTests.npal_id = app;
            Program.ProgramTests.npal_gui = gui;
            Program.ProgramTests.debug_panel = debug_panel;

            % Basic Functionality
            ProgramTests.test_image();
            ProgramTests.test_video();

            % GUI Functionality
            ProgramTests.test_gui();

            % Robust Data Handling
            ProgramTests.test_types();
            ProgramTests.test_imports();

            % Advanced Functionality
            ProgramTests.test_artifacts();
            ProgramTests.test_colors();
            ProgramTests.test_system();

            % Interdependent Functionality
            ProgramTests.test_autoseg();
            ProgramTests.test_autoid();
            ProgramTests.test_zephir();
            ProgramTests.test_output();
        end
    end
end