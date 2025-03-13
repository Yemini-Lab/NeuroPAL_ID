function interface = interface()
    app = Program.app;
    interface = app.TabGroup.SelectedTab.Title;

    if isempty(interface)
        source = dbstack();
        n_trace = length(source);
        interface = "NeuroPAL ID";
        for n = 1:n_trace
            call = source(n).name;
            if contains(call, 'proc')
                interface = "Image Processing";
                break

            elseif contains(call, 'vid')
                interface = "Video Tracking";
                break
            end
        end
    end
end

