function apply(volume, action)
    Program.dlg.add_task('Processing volume...');
    [app, ~, state] = Program.ctx;

    if ~exist('volume', 'var')
        volume = state.active_volume;
    elseif ~isa(volume, 'Program.volume')
        action = volume;
        volume = state.active_volume;
    end

    if exist('action', 'var')
        actions = {action};
    else
        actions = fieldnames(app.flags);
    end

    % Calculate the dimensions of the array we'll need to initialize.
    Program.dlg.step('Preallocating space...');
    prospective_dimensions = volume.dims;
    for a=1:length(actions)
        prospective_dimensions = Methods.ChunkyMethods.calc_pp_size( ...
            app, actions{a}, zeros(prospective_dimensions));
    end

    % Check whether this is a neuropal file.
    Program.dlg.step('Validating file...');
    npal_helper = DataHandling.Helpers.npal;
    if ~npal_helper.is_npal_file(volume.path)
        npal_name = sprintf('%s-NPAL', volume.name);
        target_path = strrep(volume.path, volume.name, npal_name);
        target_path = strrep(target_path, volume.fmt, 'mat');

        % Check whether a neuropal file exists for this file. If not,
        % create one.
        if ~isfile(target_path)
            npal_helper.create(target_path, 'like', volume, ...
                'array_size', prospective_dimensions);
        end

        target_file = matfile(target_path, "Writable", true);
    else
        target_file = matfile(volume.path, "Writable", true);
    end

    Program.dlg.step('Calculating chunk size...');
    maximum_array_size = Program.Routines.Debug.get_max_array_size;
    total_volume_size = prod(volume.dims);
    must_chunk = total_volume_size > maximum_array_size;

    if ~must_chunk
        Program.dlg.add_task("Volume size fits into memory...");

        Program.dlg.step('Reading all at once...');
        if volume.is_video
            data = volume.read( ...
                'x', 1:volume.nx, ...
                'y', 1:volume.ny, ...
                'z', 1:volume.nz, ...
                'c', 1:volume.nc);
        else
            data = volume.read( ...
                'x', 1:volume.nx, ...
                'y', 1:volume.ny, ...
                'z', 1:volume.nz, ...
                'c', 1:volume.nc, ...
                't', 1:volume.nt);
        end


        for a=1:length(actions)
            Program.dlg.step(sprintf('Applying %s...', actions{a}));
            processed_data = Methods.ChunkyMethods.apply_vol( ...
                app, actions{a}, data);
        end

        Program.dlg.step('Writing all at once...');
        target_file.data = processed_data;        
        Program.dlg.resolve();
    else
        use_framewise_chunks = volume.is_video && (volume.nt > volume.nz);
        if use_framewise_chunks
            Program.dlg.add_task("Volume size exceeds memory, " + ...
                " chunking frame-wise...");
            chunk_max = volume.nt;
            chunk_label = 'Frames';
        else    
            Program.dlg.add_task("Volume size exceeds memory, " + ...
                " chunking slice-wise...");
            chunk_max = volume.nz;
            chunk_label = 'Slices';
        end

        bytes_per_slice = total_volume_size / chunk_max;
        chunk_size = max(1, floor(maximum_array_size / bytes_per_slice));
    
        chunk_start = 1;
        while chunk_start <= chunk_max
            chunk_end = min(chunk_start + chunk_size - 1, chunk_max);

            Program.dlg.set_value(chunk_end/chunk_max);
            Program.dlg.step(sprintf( ...
                '%s %.f-%.f (out of %.f)...', ...
                chunk_label, chunk_start, chunk_end, chunk_max));

            if use_framewise_chunks
                chunk = volume.read( ...
                    'x', 1:volume.nx, ...
                    'y', 1:volume.ny, ...
                    'z', 1:volume.nz, ...
                    'c', 1:volume.nc, ...
                    't', chunk_start:chunk_end);
            else
                chunk = volume.read( ...
                    'x', 1:volume.nx, ...
                    'y', 1:volume.ny, ...
                    'z', chunk_start:chunk_end, ...
                    'c', 1:volume.nc);
            end

            for a=1:length(actions)
                processed_chunk = Methods.ChunkyMethods.apply_vol( ...
                    app, actions{a}, chunk);
            end

            if use_framewise_chunks
                target_file.data(:, :, :, :, chunk_start:chunk_end) = processed_chunk;
            else
                target_file.data(:, :, chunk_start:chunk_end, :) = processed_chunk;
            end

            chunk_start = chunk_end + 1;
        end

        Program.dlg.resolve();
    end

    Program.dlg.step('Setting new volume...');
    processed_volume = Program.volume(target_file.Properties.Source);
    Program.Routines.mount_volume(processed_volume);
    Program.dlg.resolve();
end

