classdef segmentation_gui
    %SEGMENTATION_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function initialize(app)
            addon_dir = Program.GUIHandling.get_dir("addon");

            addons = dir(addon_dir);
            addon_names = {addons.name};
            addon_folders = {addons.folder};
            
            valid = find(~ismember(addon_names, {'.', '..'}));
            app.seg_algorithm_dropdown.Items = addon_names(valid);
            app.seg_algorithm_dropdown.ItemsData = fullfile(addon_folders(valid), addon_names(valid));

            app.seg_side_panel.Parent = app.NeuronRankPanel.Parent;
            app.seg_side_panel.Layout.Row = app.NeuronRankPanel.Layout.Row:app.NeuronListBoxPanel.Layout.Row;

            app.NeuronRankPanel.Visible = 'off';
            app.NeuronListBoxPanel.Visible = 'off';
            app.seg_side_panel.Visible = 'on';
        end

        function close(app)
            app.NeuronRankPanel.Visible = 'on';
            app.NeuronListBoxPanel.Visible = 'on';
            app.seg_side_panel.Visible = 'off';
        end

        function clear_algorithm(app)
        end

        function handles = load_algorithm(app, dd)
            Program.segmentation_gui.clear_algorithm(app);
            alg_idx = ismember(dd.Items, dd.Value);
            alg_file = fullfile(dd.ItemsData{alg_idx}, 'gui.json');
            
            open_file = fopen(alg_file);
            raw_json = fread(open_file, inf);

            alg_config = jsondecode(raw_json);
            handles = struct( ...
                'actions', {{}}, ...
                'parameters', {{}}, ...
                'credit', {{}});
            
            if strcmp(alg_config.type, "segmentation")
                if isfield(alg_config, "parameters")
                    parameters = fieldnames(alg_config.parameters);
                    for p=1:length(parameters)
                        var = parameters{p};

                        switch alg_config.parameters.(var).type
                            case "float"
                                handles.parameters.(var) = Program.GUIHandling.create_component(app.seg_parameter_grid, "NumField", [2 bl]);
                                handles.parameters.(var).Label = alg_config.parameters.(var).title;

                                if isfield(alg_config.parameters.(var), 'tooltip')
                                    handles.parameters.(var).Tooltip = alg_config.parameters.(var).tooltip;
                                end
                        end
                    end
                end

                if isfield(alg_config, "credit")
                    credit_components = fieldnames(alg_config.credit);
                    app.seg_credit_grid.RowHeight = {'fit'*length(credit_components)};

                    if ismember(credit_components, "links")
                        button_links = fieldnames(alg_config.credit.links);
                        link_count = length(button_links);
                        app.seg_credit_grid.ColumnWidth{end+1} = {'fit'*link_count};
                        
                        for bl = 1:link_count
                            link_label = button_links{bl};
                            handles.credit.(link_label) = Program.GUIHandling.create_component(app.seg_credit_grid, "Button", [2 bl]);
                            handles.credit.(link_label).Text = button_links{bl};
                            handles.credit.(link_label).ButtonPushedFcn = @(src, event) web(alg_config.credit.links.(button_links{bl}));
                        end
                    end

                    n_rows = length(app.seg_credit_grid.RowHeight);
                    n_cols = length(app.seg_credit_grid.ColumnWidth);

                    if ismember(credit_components, "description")
                        description_columns = 1:n_cols;
                        handles.credit.description = Program.GUIHandling.create_component(app.seg_credit_grid, "Label", [1 description_columns]);
                        handles.credit.description.Text = alg_config.credit.description;
                    end

                    if ismember(credit_components, "citation")
                        handles.credit.citation_label = Program.GUIHandling.create_component(app.seg_credit_grid, "Label", [n_rows 1]);
                        handles.credit.citation_label.Text = "Cite as such:";
                        handles.credit.citation = Program.GUIHandling.create_component(app.seg_credit_grid, "TextArea", [n_rows 1:n_cols]);
                        handles.credit.citation.Value = alg_config.credit.citation;
                    end

                    if n_cols > 1
                        app.seg_credit_grid.ColumnWidth = {'0.1x', app.seg_credit_grid.ColumnWidht, '0.1x'};
                    end
                end

                algorithm_actions = fieldnames(alg_config.actions);
                n_actions = length(algorithm_actions);
                app.seg_actions_grid.ColumnWidth = {'fit'*n_actions};
                for a=1:n_actions
                    action = algorithm_actions{a};
                    handles.actions.(action) = struct('instructions', {{}}, 'gui', {{}});
                    handles.actions.(action).instructions = struct( ...
                        'script', {alg_config.actions.(action).script}, ...
                        'isBinary', {alg_config.actions.(action).isBinary}, ...
                        'arguments', {alg_config.actions.(action).arguments});

                    handles.actions.(action).gui = Program.GUIHandling.create_component(app.seg_parameter_grid, "Button", [1 a]);
                    handles.actions.(action).gui.Text = action;
    
                    if alg_config.actions.(action).isComputationallyIntense
                        handles.actions.(action).gui.BackgroundColor = [1 0 0];
                        handles.actions.(action).gui.FontWeight = 'bold';
                        handles.actions.(action).gui.FontColor = [1 1 1];
                    end

                    handles.actions.(action).gui.ButtonPushedFcn = @(src, event) Program.segmentation_gui.run_cmd(handles.actions.(action).instructions.script, fieldnames(alg_config.actions.(action).instructions.arguments));
                end
            end
        end

        function channels(app, action)
            channel_names = Program.GUIHandling.channel_names;

            switch action
                case 'list'
                    package = struct( ...
                        'gui', {{}}, ...
                        'idx', {[1 2 3 4 5]});

                    for c = 1:length(channel_names)
                        package.gui{end+1} = app.(sprintf("%sCheckBox", channel_names{c}));
                    end

                    channel_names = {'r', 'g', 'b', 'w', 'dic', 'gfp', ...
                        'red', 'green', 'blue', 'white', 'DIC', 'GFP'};


                case 'get'            
                    for i = 1:numel(channel_list)
                        if channel_list(i).CheckBox.Value == 1
                            chan_array = [chan_array channel_list(i).Index];
                        end
                    end

                case 'edit'
            end
        end

        function noise_value = measure_noise(app, axes)
            uiwait(msgbox('Click and drag your cursor on the image to select a region and calculate its average intensity.','Instructions'))
                        
            roi = drawfreehand(axes,'Color','black','StripeColor','m');
            mask = createMask(roi,app.image_view);
            
            channel_list = struct('CheckBox',{app.RedCheckBox, app.GreenCheckBox, app.BlueCheckBox, app.WhiteCheckBox, app.GFPCheckBox},'Index',{1,2,3,4,5});
            chan_array = [];
            slice_avg = [];
            
            for i = 1:numel(channel_list)
                if channel_list(i).CheckBox.Value == 1
                    chan_array = [chan_array channel_list(i).Index];
                end
            end
            
            % Get the pixel values of the selected channels within the ROI for the slice matching the value of app.Slider.Value
            subdata = app.image_data(:,:,round(app.Slider.Value),chan_array);
            subdata = mean(subdata, 4);
            slice_avg = [slice_avg mean(subdata(mask))*100];
            
            % Get the average intensity of pixels within the ROI for the selected slice
            noise_value = mean(slice_avg);
            delete(roi)
        end
        
        function black_out(app, axes, noise_value)
            uiwait(msgbox('Click and drag your cursor on the image to select the region to ignore during segmentation.','Instructions'))
            
            roi = drawfreehand(axes,'Color','black','StripeColor','m');
            mask = cast(~createMask(roi, app.image_view), class(app.image_view));
            replacement_value = app.AveragenoncellintensityEditField.Value;
            
            border_size = 5;
            border_mask = ones(size(mask));
            border_mask(border_size+1:end-border_size, border_size+1:end-border_size) = 0;
            
            border_pixel_std = zeros(1, 3);
            for i = 1:3
                channel_data = app.image_view(:,:,i);
                border_pixel_std(i) = std(channel_data(logical(border_mask)));
            end
            
            for n = 1:size(app.image_data,3)
                color_indices = [1, 2, 3];
                for idx = color_indices
                    noise = normrnd(0, border_pixel_std(idx), size(app.image_data(:,:,n,idx)));
            
                    noise = noise * 0.5;
            
                    gaussian_filter = fspecial('gaussian', [5 5], 0.7);
                    noise = imfilter(noise, gaussian_filter, 'replicate');
            
                    app.image_data(:,:,n,idx) = app.image_data(:,:,n,idx).*mask + (1-mask).*(noise_value*0.7 + noise);
                end
            end
        end
    end
end

