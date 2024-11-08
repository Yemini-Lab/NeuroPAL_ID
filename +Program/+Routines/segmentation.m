function [outputArg1,outputArg2] = segmentation()
    app = Program.GUIHandling.app();
    window_fig = Program.GUIHandling.window_fig();

    if ~Program.Helpers.load_time_warning
        return
    end

    if Program.Helpers.segmentation.nz < size(app.image_data, 3)
        z_check = uiconfirm(window_fig, ...
            'Not all slices are selected. Proceed?', ...
            'Warning!', ...
            'Options', {'Yes','Yes, with all slices selected.','No'}, ...
            'DefaultOption','No');

        if strcmp(z_check, 'Yes, with all slices selected.')
            image(app.ImageAxes, squeeze(max(app.image_view,[],3)));
            app.z_siz = size(app.image_data,3);
            app.zSlicesListBox.Value = 1:size(app.image_data,3);

            for i = 1:size(app.auto_neurons, 1)
                images.roi.Point(app.ImageAxes,'Position',[app.auto_neurons(i,2) app.auto_neurons(i,1)], 'Color',[0 1 0], 'MarkerSize',3, 'LineWidth',1, 'Label',sprintf('Neuron #%.0f',i), 'LabelVisible','hover');
            end
        end
    end

    Program.Helpers.segmentation.build_dir()

end

