function [n_arr, l_arr] = readTrackmate(file)
    xml_contents = xml2struct(file);
    xml_model = xml_contents.TrackMate.Model;
    neuron_rois = xml_model.AllSpots;

    nt = size(neuron_rois.SpotsInFrame, 2);

    n_arr = zeros([1 4]);
    l_arr = {};

    for t=1:nt
        frame_labels = {};
        try
            target = neuron_rois.SpotsInFrame{t};
            for n=1:size(target.Spot, 2)
                x = str2num(target.Spot{n}.Attributes.POSITION_X);
                y = str2num(target.Spot{n}.Attributes.POSITION_Y);
                z = str2num(target.Spot{n}.Attributes.POSITION_Z);
                frame = str2num(target.Spot{n}.Attributes.POSITION_T);
                label = target.Spot{n}.Attributes.name;

                if ismember(frame_labels, label)
                    num = count(frame_labels, label);
                    label = repmat(label, 1, num+1);
                end
    
                if ~any(isempty([x y z]))
                    n_arr = [n_arr; [frame x y z]];
                    l_arr{end+1} = label;
                end
            end
        catch
            % ...
        end
    end

    if min(n_arr(:, 1))==0
        n_arr(:, 1) = n_arr(:, 1) + 1;
    elseif min(n_arr(:, 1))==2
        n_arr(:, 1) = n_arr(:, 1) - 1;
    end
end