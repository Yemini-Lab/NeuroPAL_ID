function c = first_unchecked_channel()
    c = [];
    app = Program.app;
    
    for n=4:Program.Handlers.channels.config{'max_channels'}
        handle = sprintf(Program.Handlers.channels.handles{'pp_cb'}, n);
        if ~app.(handle).Value
            c = n;
            return
        end
    end
end

