function [n_arr, l_arr, t_gap] = readTrackmate(file)
    xml_contents = xml2struct(file);
    xml_model = xml_contents.TrackMate.Model;
    neuron_rois = xml_model.AllSpots;

    nt = size(neuron_rois.SpotsInFrame, 2);

    n_arr = zeros([1 4]);
    l_arr = {};
    t_gap = 0;

    for t=1:nt
        try
            target = neuron_rois.SpotsInFrame{t};
            for n=1:size(target.Spot, 2)
                x = str2num(target.Spot{n}.Attributes.POSITION_X);
                y = str2num(target.Spot{n}.Attributes.POSITION_Y);
                z = str2num(target.Spot{n}.Attributes.POSITION_Z);
                label = target.Spot{n}.Attributes.name;
                frame = str2num(target.Spot{n}.Attributes.POSITION_T);
    
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
        t_gap = 1;
        n_arr(:, 1) = n_arr(:, 1) + 1;
    elseif min(n_arr(:, 1))==2
        t_gap = -1;
        n_arr(:, 1) = n_arr(:, 1) - 1;
    end
end