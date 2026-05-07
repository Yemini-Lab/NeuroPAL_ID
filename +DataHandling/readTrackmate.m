function [n_arr, l_arr] = readTrackmate(file)
    doc = xmlread(file);
    spots = doc.getElementsByTagName('Spot');

    n_arr = zeros(0, 4);
    l_arr = {};
    labels_by_frame = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for i = 0:(spots.getLength - 1)
        spot = spots.item(i);
        x = str2double(char(spot.getAttribute('POSITION_X')));
        y = str2double(char(spot.getAttribute('POSITION_Y')));
        z = str2double(char(spot.getAttribute('POSITION_Z')));
        frame = str2double(char(spot.getAttribute('FRAME')));
        if isnan(frame)
            frame = str2double(char(spot.getAttribute('POSITION_T')));
        end
        label = char(spot.getAttribute('name'));
        if isempty(label)
            label = sprintf('TrackMate_%.f', i + 1);
        end

        if any(isnan([x y z frame]))
            continue
        end

        frame_key = sprintf('%.f', frame);
        if isKey(labels_by_frame, frame_key)
            frame_labels = labels_by_frame(frame_key);
        else
            frame_labels = {};
        end

        if any(strcmp(frame_labels, label))
            label = sprintf('%s_%.f', label, nnz(strcmp(frame_labels, label)) + 1);
        end
        frame_labels{end+1} = label; %#ok<AGROW>
        labels_by_frame(frame_key) = frame_labels;

        n_arr(end+1, :) = [frame x y z]; %#ok<AGROW>
        l_arr{end+1} = label; %#ok<AGROW>
    end

    if isempty(n_arr)
        return
    end

    if min(n_arr(:, 1)) == 0
        n_arr(:, 1) = n_arr(:, 1) + 1;
    elseif min(n_arr(:, 1)) == 2
        n_arr(:, 1) = n_arr(:, 1) - 1;
    end
end
