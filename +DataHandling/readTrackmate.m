function info = readTrackmate(file)
    xml_contents = xml2struct(file);
    xml_model = xml_contents.TrackMate.Model;
    neuron_rois = xml_model.AllSpots;

    nt = size(neuron_rois.SpotsInFrame, 2);

    n_arr = zeros([nt 4]);
    l_arr = {};

    for t=1:nt
        target = neuron_rois.SpotsInFrame{t};
        for n=1:size(target.Spot, 2)
            x = str2num(target.Spot{n}.Attributes.POSITION_X);
            y = str2num(target.Spot{n}.Attributes.POSITION_Y);
            z = str2num(target.Spot{n}.Attributes.POSITION_Z);
            label = target.Spot{n}.Attributes.name;

            n_arr(t, :) = [t x y z];
            l_arr{end+1} = label;
            clc
        end
            clc
    end

    info = struct('coords', n_arr, 'labels', l_arr);
end