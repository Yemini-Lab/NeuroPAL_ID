function code = lineage()
    trace = {dbstack().name};
    from_stack = 0;
    from_video = 0;
    code = 0;

    for f=1:length(trace)
        func = trace{f};
        
        if ~from_stack
            from_stack = contains(func, 'OpenFile');
            if ~code
                code = 1;
            end
        end

        if ~from_video
            from_video = contains(func, 'TraceActivity');
            if ~code
                code = 2;
            end
        end
    end
end

