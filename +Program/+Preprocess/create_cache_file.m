function cache_file = create_cache_file(filepath)
    cache = struct( ...
        'is_lazy', {DataHandling.file.is_lazy}, ...
        'is_processed', {DataHandling.file.is_processed}, ...
        'metadata', {DataHandling.file.metadata});
    
    cache_file = fullfile(path, strrep(filepath, DataHandling.file.fmt, 'mat'));
    save(cache_file, "cache", '-struct', '-v7.0');

    md = DataHandling.Lazy.file.metadata;
    
    mf = matfile(cache_file, 'Writable', true);
    mf.data = zeros([md.ny, md.nx, md.nz, md.nc, md.nt], md.ml_bit_depth);

    if md.nt >= 2
        for t = 1:md.nt
            mf.data(:, :, :, :, t) = DataHandling.Lazy.file.get_frame(t);
        end

    else
        for z = 1:md.nz
            mf.data(:, :, z, :) = DataHandling.Lazy.file.get_slice(z);
        end
    end
end

