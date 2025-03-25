function bool = viewing_video()
    state = Program.state;
    source = dbstack();
    source = source(2).name;

    using_video_func = contains(source, 'video');
    using_video_file = state.active_volume.is_video;
    if ~isempty(state.interface)
        using_video_tab = any(ismember(state.interface, ...
            {'1', 'Video Tracking', 'track', 'tracking'}));
    else
        using_video_tab = 0;
    end

    bool = using_video_file || using_video_tab || using_video_func;
end

