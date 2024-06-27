function [n_arr, l_arr] = readTrackmate(file)
    xml_contents = xml2struct(file);
    xml_model = xml_contents.TrackMate.Model;
    neuron_rois = xml_model.AllSpots;

    nt = size(neuron_rois.SpotsInFrame, 2);

    n_arr = zeros([1 4]);
    l_arr = {};

    for t=1:nt
        target = neuron_rois.SpotsInFrame{t};
        for n=1:size(target.Spot, 2)
            x = str2num(target.Spot{n}.Attributes.POSITION_X);
            y = str2num(target.Spot{n}.Attributes.POSITION_Y);
            z = str2num(target.Spot{n}.Attributes.POSITION_Z);
            label = target.Spot{n}.Attributes.name;
            frame = str2num(target.Spot{n}.Attributes.POSITION_T);

            n_arr = [n_arr; [frame x y z]];
            l_arr{end+1} = label;
        end
    end
    
    n_arr = n_arr + 1;
end