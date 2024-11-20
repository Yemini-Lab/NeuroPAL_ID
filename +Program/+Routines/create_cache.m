function [f_path, f_obj] = create_cache()
    metadata = DataHandling.file.metadata();
    
    window_fig = Program.GUIHandling.window_fig();
    d = uiprogressdlg(window_fig, "Message", "Reading metadata...", "Indeterminate", "off");
    
    f_obj = struct( ...
        'version', Program.ProgramInfo.version, ...
        'Writable', true);
    
    %{
    dic = Program.channel_handler.has_dic;
    gfp = Program.channel_handler.has_gfp;
    rgbw = Program.channel_handler.get('rgbw');
    gammas = Program.channel_handler.get('gammas');
    %}
    
    dic = metadata.has_dic;
    gfp = metadata.has_gfp;
    chan_order = metadata.channels.as_rendered;
    data_chans = metadata.channels.order(metadata.channels.order~=metadata.channels.null_channels);
    gammas = 1;
    
    f_obj.info = struct( ...
        'file', {metadata.path}, ...
        'scale', {metadata.scale}, ...
        'DIC', {dic}, ...
        'RGBW', {chan_order(1:4)}, ...
        'GFP', {gfp}, ...
        'chan_order', {chan_order}, ...
        'gamma', {gammas}, ...
        'is_video', {metadata.is_video});
    
    f_obj.prefs = struct( ...
        'RGBW', {chan_order(1:4)}, ...
        'DIC', {dic}, ...
        'GFP', {gfp}, ...
        'gamma', {gammas}, ...
        'lazy', {1});
    
    f_obj.worm = struct( ...
        'body', {''}, ...
        'age', {'Adult'}, ...
        'sex', {'XX'}, ...
        'strain', {''}, ...
        'notes', {''});
    
    f_obj.channels = metadata.channels;
    
    f_path = strrep(metadata.path, metadata.fmt, 'mat');
    save(f_path, "-struct", "f_obj", '-v7.3');
    
    h_write = matfile(f_path, "Writable", true);
    h_write.data = zeros(metadata.ny, metadata.nx, metadata.nz, metadata.nc, metadata.nt, Program.GUIHandling.standard_class);
    
    d.Message = "Constructing cache file...";
    if metadata.is_video
        for t=1:metadata.nt
            d.Value = t/metadata.nt;
            this_frame = DataHandling.file.get_frame(t);
            h_write.data(:, :, :, :, t) = DataHandling.Types.to_standard(this_frame(:, :, :, data_chans, :));
        end
        
    else
        for z=1:metadata.nz
            d.Value = z/metadata.nz;
            this_slice = DataHandling.file.get_slice(z);
            h_write.data(:, :, z, :) = DataHandling.Types.to_standard(this_slice(:, :, :, data_chans));
        end
    
    end
end

