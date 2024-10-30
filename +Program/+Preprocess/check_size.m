function [code, sys, f_size] = check_size(filepath)
    if ispc
        [~, sys] = memory;
    elseif ismac
        [status, cmdout] = system('sysctl hw.memsize | awk ''{print $2}''');
        if status == 0
            sys = struct('PhysicalMemory', {struct('Available', {cmdout})});
        else
            error("Ran into the following error while trying to calculate free memory on mac:\n%s", cmdout);
        end
    end

    f_size = dir(filepath).bytes;
    if f_size > sys.PhysicalMemory.Available
        code = 1;
        msg = "Your volume exceeds remaining free memory. We strongly recommend preprocessing your file to avoid memory issues and slow processing times.\nPreprocess now?";
    elseif f_size > Program.preprocess.max_size
        code = 2;
        msg = "Your volume exceeds the soft working limit of 100 mb. We strongly recommend preprocessing your file to avoid memory issues and slow processing times.\nPreprocess now?";
    else
        code = 0;
        return
    end

    check = uiconfirm(Program.GUIHandling.app, msg, "Warning!", "Options", ["Yes, preprocess.", "No, toggle lazy loading.", "No, cancel."]);
    switch check
        case "Yes, preprocess."
            cache_file = Program.Preprocess.create_cache_file(filepath);
            Program.Preprocess.trigger_routine(cache_file);
        case "No, toggle lazy loading."
            Program.GUIHandling.set('is_lazy', 1);
        case "No, cancel."
    end
end