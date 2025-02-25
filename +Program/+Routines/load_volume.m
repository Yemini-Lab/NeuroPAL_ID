function obj = load_volume(path)
    obj = Program.volume(path);
    Program.GUI.channel_editor.populate(obj);
    Program.render();
    switch Program.states.interface
        case "NeuroPAL ID"
            Program.render.stack(obj);
        case "Video Tracking"
            Program.render.video(obj);
        case "Image Processing"
            Progrem.render.processing(obj);
    end
    
    Program.states.set('active_volume', obj);
    loaded_volumes = Program.states.loaded_volumes;
    if ~ismember(obj, loaded_volumes)
        Program.states.set('loaded_volumes', obj);
    end
end

