function code = worm(worm)
    app = Program.app;
    window = Program.window;
    code = 1;
    worm_properties = {'Body', 'Age', 'Sex'};

    for wp=1:length(worm_properties)
        target_property = worm_properties{wp};
        key = lower(target_property);
        component = sprintf("%sDropDown", target_property);

        if ~any(strcmp(worm.(key), app.(component).Items))
            code = 0;
            error_message = sprintf("Unrecognized worm %s region (%s)!", target_property, worm.(key));
            uialert(window, error_message, 'File Format Failure', 'Icon', 'error');
            return

        end
    end
end

