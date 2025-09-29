classdef Illustration
    %ILLUSTRATION Methods to illustrate NeuroPAL images.
    
    % Illustration constants.
    properties (Constant, Access = public)
        font_name = 'Arial';
        font_weight = 'bold';
    end
    
    
   % Public methods.
    methods (Static)
        function saveIDImage(file, data, neurons, um_scale, is_Z_flip)
            %SAVEIDIMAGE save an image with neuron IDs to a PDF.
            
            % Initialize.
            import Output.*;
            
            % What is the z limit?
            max_z = size(data,3);
            max_z_str = num2str(max_z);
            range_z_str = ['(1-' max_z_str ')'];
            range_z_ID_str = ['(0-' max_z_str ')'];
            
            % Worm neurons are ~2-4um in diameter so default to 8um MIP z-slices.
            z_MIP_def = num2str(round(8 / um_scale(3)));
            
            % First, let user choose file format with dropdown
            format_list = {'PDF', 'SVG'};
            [format_idx, format_ok] = listdlg('PromptString', 'Select file format:', ...
                                              'SelectionMode', 'single', ...
                                              'ListString', format_list, ...
                                              'InitialValue', 1, ...
                                              'Name', 'File Format');
            if ~format_ok
                return;
            end
            file_format = lower(format_list{format_idx});
            
            % Prompt the user for the remaining parameters.
            start_z_str = ['Start Z-slice ' range_z_str];
            end_z_str = ['End Z-slice ' range_z_str];
            z_MIP_str = ['Z-slice thickness ' range_z_str];
            z_ID_str = ['Z-slice ID thickness ' range_z_ID_str];
            size_str = 'Image size (default = 1x)';
            font_str = 'Font size';
            circle_weak_str = 'Circle Weak Neurons (yes/no)';
            circle_all_str = 'Circle All Neurons (yes/no)';
            prompt = {start_z_str, end_z_str, z_MIP_str, z_ID_str, ...
                size_str, font_str, circle_weak_str, circle_all_str};
            title = 'Save ID Image Parameters';
            dims = [1 35];
            definput = {'1', max_z_str, z_MIP_def, '1', '2', '4', 'y', 'y'};
            answer = inputdlg(prompt, title, dims, definput);
            if isempty(answer)
                return;
            end
            
            % Format the user input.
            start_z = round(str2double(answer{1}));
            end_z = round(str2double(answer{2}));
            z_MIP = round(str2double(answer{3}));
            z_ID_offset = round(str2double(answer{4}));
            image_size = str2double(answer{5});
            font_size = round(str2double(answer{6}));
            is_circle_weak = ~isempty(answer{7}) && lower(answer{7}(1)) == 'y';
            is_circle_all = ~isempty(answer{8}) && lower(answer{8}(1)) == 'y';
            
            % Sanitize the input values.
            if start_z < 1 || start_z > max_z
                start_z = 1;
            end
            if end_z < 1 || end_z > max_z
                end_z = max_z;
            end
            if z_MIP < 1 || z_MIP > max_z
                z_MIP = 1;
            end
            if z_ID_offset < 0 || z_ID_offset > max_z
                z_ID_offset = 1;
            end
            if start_z > end_z
                tmp = start_z;
                start_z = end_z;
                end_z = tmp;
            end
            if z_MIP > (end_z - start_z + 1)
                z_MIP = end_z - start_z + 1;
            end
            if image_size <= 0
                image_size = 1;
            end
            if font_size <= 0
                font_size = 10;
            end
            
            % Is Z flipped?
            if is_Z_flip
                user_start_z = start_z;
                start_z = max_z - end_z + 1;
                end_z = max_z - user_start_z + 1;
            end
            
            % Get the the screen size.
            screen_size = get(0, 'Screensize');
            
            % Compute the scale bar.
            max_y = size(data,1);
            scale_bar_width = 1;
            scale_bar_size = 10;
            scale_bar_str = [num2str(scale_bar_size) ' \mum'];
            scale_bar_off = [10,10];
            scale_bar_len = (scale_bar_size / um_scale(1)) * image_size;
            scale_bar_x = [0, scale_bar_len] + scale_bar_off(1);
            scale_bar_y = max_y * image_size - [scale_bar_off(2),scale_bar_off(2)];
            scale_bar_str_x = sum(scale_bar_x)/2;
            scale_bar_str_y = sum(scale_bar_y)/2;
            
            % Setup circles to mark weakly-colored neurons.
            weak_color_threshold = ones(1,3) / 4.0;
            neuron_radius = (1.5 / um_scale(1)) * image_size;
            neuron_line_width = 1;
            neuron_line_style = '-';
            neuron_line_color = ones(1,3) / 2.0;
            
            % Take a minimal patch around the neuron center.
            % Note: we need to walk a thin line of being robust against
            % off-center dots, while not violating neighboring neurons.
            cube_size = [1,1,1];
                
            % Get the neuron info.
            neuron_pos = vertcat(neurons.position);
            if ~isempty(neuron_pos)
                
                % Compute the neuron brightness for overlaying text.
                neuron_brightness_thresh = 0.7;
                %image_brightness = data(:,:,:,2); % use the green channel
                %neuron_brightness = arrayfun(@(x) median( ...
                %    Methods.Utils.subcube(image_brightness, ...
                %    round(neuron_pos(x,:)), cube_size), 'all'), ...
                %    1:size(neuron_pos,1));
                image_brightness = data(:,:,:,1:3);
                neuron_color = arrayfun(@(x) squeeze(median(...
                    Methods.Utils.subcube(image_brightness, ...
                    round(neuron_pos(x,:)), cube_size),1:3)), ...
                    1:size(neuron_pos,1), 'UniformOutput', false);
                
                % Determine the neuron names, image coordinates, ID
                % confidence, ON/OFF annotations, & emphasis.
                neuron_name = arrayfun(@(x) x.annotation, neurons, 'UniformOutput' , false);
                neuron_pos(:,1:2) = neuron_pos(:,1:2) * image_size;
                neuron_conf = arrayfun(@(x) x.annotation_confidence, neurons);
                neuron_on = arrayfun(@(x) double(x.is_annotation_on), neurons);
                neuron_emphasized = arrayfun(@(x) x.is_emphasized, neurons);
            end
            
            % Determine the Z MIPs.
            Z_MIPs = start_z:z_MIP:end_z;
            if Z_MIPs(end) < end_z
                Z_MIPs = [Z_MIPs, end_z];
            end
            if is_Z_flip
                Z_MIPs = end_z - fliplr(Z_MIPs) + 1; 
            end
            
            % Save the PDFs.
            for page = 1:(length(Z_MIPs) - 1)
                
                % Determine the Z slices to show.
                Z_start = Z_MIPs(page);
                Z_end = Z_MIPs(page + 1);
                
                % Draw the image.
                fig = figure('Visible', 'off', 'NumberTitle', 'off', 'Name', file);
                fig.Position(1:2) = [0,screen_size(4)];
                fig.Position(3:4) = [size(data,2),size(data,1)] * image_size;
                z_slice = squeeze(max(data(:,:,Z_start:Z_end,:),[],3));
                if image_size ~= 1
                    z_slice = imresize(z_slice, image_size);
                end
                image_ax = image(z_slice);
                image_ax.Parent.Box = 'off';
                image_ax.Parent.YTick = [];
                image_ax.Parent.XTick = [];
                %image_ax.Parent.PlotBoxAspectRatio = [1,1,1];
                daspect([1,1,1]);
                hold on;
                
                % Find the neurons in these z-slices.
                neuron_z = [];
                if z_ID_offset > 0 && ~isempty(neuron_pos)
                    min_z_ID = Z_start - z_ID_offset + 0.5;
                    max_z_ID = Z_end + z_ID_offset - 0.5;
                    neuron_z = find(neuron_pos(:,3) >= min_z_ID & ...
                        neuron_pos(:,3) <= max_z_ID);
                end
                
                % Draw the neuron IDs.
                for j = 1:length(neuron_z)
                    k = neuron_z(j);
                    pos = neuron_pos(k,1:2);
                    name = neuron_name{k};
                    
                    % Draw circles around neurons.
                    if is_circle_weak || is_circle_all
                        
                        % Draw circles around weakly-colored neurons.
                        if all(neuron_color{k} < weak_color_threshold)
                            viscircles(fliplr(pos), neuron_radius, ...
                                'LineWidth', neuron_line_width, ...
                                'LineStyle', neuron_line_style, ...
                                'Color', neuron_line_color, ...
                                'EnhanceVisibility', false);
                            
                        % Draw circles around the remaining neurons.
                        elseif is_circle_all
                            viscircles(fliplr(pos), neuron_radius, ...
                                'LineWidth', neuron_line_width, ...
                                'LineStyle', neuron_line_style, ...
                                'Color', neuron_color{k}, ...
                                'EnhanceVisibility', false);
                        end
                    end
                    
                    % Is the neuron ON/OFF?
                    if ~isnan(neuron_on(k))
                        if neuron_on(k)
                            name = [name '-ON'];
                        else
                            name = [name '-OFF'];
                        end
                    end
                    
                    % Is the user confident about the ID?
                    if neuron_conf(k) < 1
                        name = [name '?'];
                    end
                    
                    % Is the neuron emphasized?
                    if neuron_emphasized(k)
                        name = [name '!'];
                    end
                    
                    % Are we writing on a bright green background?
                    text_color = 'w';
                    if neuron_color{k}(2) > neuron_brightness_thresh
                        text_color = 'k';
                    end
                    
                    % Draw the ID.
                    text(pos(2), pos(1), name, 'Color', text_color, ...
                        'FontName', Illustration.font_name, ...
                        'FontSize', font_size, ...
                        'FontWeight', Illustration.font_weight, ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle');
                end
                
                % Draw the scale bar.
                plot(scale_bar_x, scale_bar_y, 'w', ...
                    'LineWidth', scale_bar_width);
                text(scale_bar_str_x, scale_bar_str_y, scale_bar_str, ...
                    'Color', 'w', ...
                    'FontName', Illustration.font_name, ...
                    'FontSize', font_size, ...
                    'FontWeight', Illustration.font_weight, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom');
                
                % Compute the page number.
                page_num = page;
                if is_Z_flip
                    page_num = length(Z_MIPs) - page;
                end
                
                % Save the file.
                save_file = [file '_' num2str(page_num) '.' file_format];
                fig.Renderer = 'Painters';
                
                if strcmp(file_format, 'svg')
                    % Configure figure for tight SVG output (no padding)
                    fig.PaperPositionMode = 'auto';
                    fig.InvertHardcopy = 'off';
                    fig.Color = 'none'; % Transparent background
                    
                    % Set axes to fill the figure completely
                    ax = gca;
                    ax.Position = [0 0 1 1]; % Fill entire figure
                    ax.XLim = [0.5 size(z_slice,2)+0.5];
                    ax.YLim = [0.5 size(z_slice,1)+0.5];
                    
                    % Save as SVG with tight bounding box
                    print(fig, '-dsvg', save_file);
                else
                    % Save as PDF (default)
                    orient(fig, 'landscape');
                    print(fig, '-dpdf', '-fillpage', save_file);
                end
                
                close(fig);
            end
        end
    end
end
