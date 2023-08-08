classdef trace_window_backup < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NeuroPAL_IDTraceWindowUIFigure  matlab.ui.Figure
        AdjustNeuronMarkerAlignmentPanel  matlab.ui.container.Panel
        NeuronMarkerGrid                matlab.ui.container.GridLayout
        MoveNeuronMarkersPanel          matlab.ui.container.Panel
        GridLayout16                    matlab.ui.container.GridLayout
        FlipHorizontallyButton          matlab.ui.control.Button
        Panel_15                        matlab.ui.container.Panel
        GridLayout27                    matlab.ui.container.GridLayout
        Left                            matlab.ui.control.Button
        Up                              matlab.ui.control.Button
        Right                           matlab.ui.control.Button
        Down                            matlab.ui.control.Button
        CCW                             matlab.ui.control.Button
        CW                              matlab.ui.control.Button
        Panel_13                        matlab.ui.container.Panel
        GridLayout18                    matlab.ui.container.GridLayout
        MoveLabel                       matlab.ui.control.Label
        MoveEditField_2                 matlab.ui.control.NumericEditField
        pixelsatatimeLabel              matlab.ui.control.Label
        CenterHorizontallyButton        matlab.ui.control.Button
        CenterVerticallyButton          matlab.ui.control.Button
        FlipVerticallyButton            matlab.ui.control.Button
        ResetTransformButton            matlab.ui.control.Button
        SaveResultButton                matlab.ui.control.Button
        ResetMoveButton                 matlab.ui.control.Button
        TransformNeuronMarkersPanel     matlab.ui.container.Panel
        GridLayout17                    matlab.ui.container.GridLayout
        ScaleEditField                  matlab.ui.control.NumericEditField
        ScaleEditFieldLabel             matlab.ui.control.Label
        WidthSpinner                    matlab.ui.control.Spinner
        WidthSpinnerLabel               matlab.ui.control.Label
        HeightSpinner                   matlab.ui.control.Spinner
        HeightSpinnerLabel              matlab.ui.control.Label
        MainTraceGrid                   matlab.ui.container.GridLayout
        ClicktoselectvideofileButton    matlab.ui.control.Button
        VolumeViewerPanel               matlab.ui.container.Panel
        VolumeViewerGrid                matlab.ui.container.GridLayout
        SizeWarningLabel                matlab.ui.control.Label
        VolumeViewerControls            matlab.ui.container.Panel
        GridLayout38                    matlab.ui.container.GridLayout
        Panel_21                        matlab.ui.container.Panel
        GridLayout41                    matlab.ui.container.GridLayout
        GCaMPVideoLabel                 matlab.ui.control.Label
        AlphaSlider                     matlab.ui.control.Slider
        NeuroPALImageLabel              matlab.ui.control.Label
        Panel_20                        matlab.ui.container.Panel
        GridLayout40                    matlab.ui.container.GridLayout
        DisplayNeuronsCheckBox          matlab.ui.control.CheckBox
        Npal_Axes                       matlab.ui.control.UIAxes
        TabGroup                        matlab.ui.container.TabGroup
        CentralControlTab               matlab.ui.container.Tab
        Panel_4                         matlab.ui.container.Panel
        GridLayout12                    matlab.ui.container.GridLayout
        Panel_16                        matlab.ui.container.Panel
        GridLayout30                    matlab.ui.container.GridLayout
        FilesLoadedLabel                matlab.ui.control.Label
        Tree                            matlab.ui.container.CheckBoxTree
        DataNode                        matlab.ui.container.TreeNode
        WorldlinesNode                  matlab.ui.container.TreeNode
        AnnotationsNode                 matlab.ui.container.TreeNode
        MetadatajsonNode                matlab.ui.container.TreeNode
        Panel_6                         matlab.ui.container.Panel
        GridLayout29                    matlab.ui.container.GridLayout
        UseMATLABbrowserCheckBox        matlab.ui.control.CheckBox
        TrackNeuronsButton              matlab.ui.control.Button
        ExtractActivityTracesButton     matlab.ui.control.Button
        SaveResultsButton               matlab.ui.control.Button
        AdjustAlignmentButton           matlab.ui.control.Button
        RecommendFramesButton           matlab.ui.control.Button
        Panel_8                         matlab.ui.container.Panel
        GridLayout8                     matlab.ui.container.GridLayout
        WormMotionPanel                 matlab.ui.container.Panel
        GridLayout5                     matlab.ui.container.GridLayout
        MotionSlider                    matlab.ui.control.Slider
        BookmarkedFramesPanel           matlab.ui.container.Panel
        GridLayout13                    matlab.ui.container.GridLayout
        ListBox                         matlab.ui.control.ListBox
        SetbookmarkButton               matlab.ui.control.Button
        AdvancedSettingsTab             matlab.ui.container.Tab
        GridLayout                      matlab.ui.container.GridLayout
        Panel_17                        matlab.ui.container.Panel
        GridLayout36                    matlab.ui.container.GridLayout
        AdvSetTab                       matlab.ui.container.TabGroup
        GeneralTab                      matlab.ui.container.Tab
        GridLayout31                    matlab.ui.container.GridLayout
        sort_mode                       matlab.ui.control.DropDown
        DropDown_2Label                 matlab.ui.control.Label
        sort_modeLabel                  matlab.ui.control.Label
        n_chunks                        matlab.ui.control.NumericEditField
        NumberofstepstodividetheforwardpassintoEditFieldLabel  matlab.ui.control.Label
        n_chunksLabel                   matlab.ui.control.Label
        n_epoch_d                       matlab.ui.control.NumericEditField
        EditField2_2Label               matlab.ui.control.Label
        n_epoch                         matlab.ui.control.NumericEditField
        n_epoch_dLabel                  matlab.ui.control.Label
        NumberofiterationsforimageregistrationLREditFieldLabel  matlab.ui.control.Label
        n_epochLabel                    matlab.ui.control.Label
        use_gpu                         matlab.ui.control.DropDown
        SetsdevicetoGPUandenablesCUDAuseDropDownLabel  matlab.ui.control.Label
        UseGPULabel                     matlab.ui.control.Label
        RegularizationLossCoefficientsTab  matlab.ui.container.Tab
        GridLayout35                    matlab.ui.container.GridLayout
        nn_max                          matlab.ui.control.NumericEditField
        EditFieldLabel_2                matlab.ui.control.Label
        nn_maxLabel                     matlab.ui.control.Label
        l_n_mode                        matlab.ui.control.DropDown
        MethodtouseforcalculatingNLabel  matlab.ui.control.Label
        NmodeLabel                      matlab.ui.control.Label
        l_n                             matlab.ui.control.NumericEditField
        EditField4Label                 matlab.ui.control.Label
        NLabel                          matlab.ui.control.Label
        l_t                             matlab.ui.control.NumericEditField
        EditField2Label                 matlab.ui.control.Label
        tLabel                          matlab.ui.control.Label
        l_d                             matlab.ui.control.NumericEditField
        EditField3Label                 matlab.ui.control.Label
        dLabel                          matlab.ui.control.Label
        GradientLearningRateTab         matlab.ui.container.Tab
        GridLayout32                    matlab.ui.container.GridLayout
        ZCompLabel                      matlab.ui.control.Label
        z_comp                          matlab.ui.control.NumericEditField
        Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel  matlab.ui.control.Label
        clip_grad                       matlab.ui.control.NumericEditField
        EditFieldLabel                  matlab.ui.control.Label
        clip_gradLabel                  matlab.ui.control.Label
        lr_coeff                        matlab.ui.control.NumericEditField
        EditField6Label                 matlab.ui.control.Label
        LRCoeffLabel                    matlab.ui.control.Label
        lr_floor                        matlab.ui.control.NumericEditField
        Minimumvalueforinitiallearningratedefault002EditFieldLabel  matlab.ui.control.Label
        LRFloorLabel                    matlab.ui.control.Label
        lr_ceiling                      matlab.ui.control.NumericEditField
        EditFieldLabel_3                matlab.ui.control.Label
        lr_ceilingLabel                 matlab.ui.control.Label
        ImageMotionTab                  matlab.ui.container.Tab
        GridLayout34                    matlab.ui.container.GridLayout
        dimmer_ratio                    matlab.ui.control.NumericEditField
        CoefficientfordimmingnonfoveatedregionsEditFieldLabel  matlab.ui.control.Label
        dimmer_ratioLabel               matlab.ui.control.Label
        motion_predict                  matlab.ui.control.DropDown
        DropDownLabel                   matlab.ui.control.Label
        motion_predictLabel             matlab.ui.control.Label
        grid_shape                      matlab.ui.control.NumericEditField
        SizeoftheimagedescriptorsinthexyplaneinpixelsEditFieldLabel  matlab.ui.control.Label
        grid_shapeLabel                 matlab.ui.control.Label
        fovea_sigma                     matlab.ui.control.NumericEditField
        EditFieldLabel_4                matlab.ui.control.Label
        foveasigmaLabel                 matlab.ui.control.Label
        MiscellaneousTab                matlab.ui.container.Tab
        GridLayout37                    matlab.ui.container.GridLayout
        EnableManualZephirSettingsCheckBox  matlab.ui.control.CheckBox
        HoveroverlabelsforfurtherdetailsorguidanceLabel  matlab.ui.control.Label
        CreditTab                       matlab.ui.container.Tabmat
        GridLayout14                    matlab.ui.container.GridLayout
        CitationTextArea                matlab.ui.control.TextArea
        CitationTextAreaLabel           matlab.ui.control.Label
        Image2                          matlab.ui.control.Image
        GithubRepositoryButton          matlab.ui.control.Button
        ViewPreprintButton              matlab.ui.control.Button
        LaboratoryPageButton            matlab.ui.control.Button
        Label                           matlab.ui.control.Label
        UIAxes                          matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        parent_app;
        image_data;
        image_view;
        repo_neurons;
        image_neurons;
        path;
        dir;
        vidArray;
        vreader;
        neuron_table;
        red; % Color indices.
        green;
        blue;
        white;
        gfp;
        dic;
        image_gamma;
        data_store;
        v_master;
        v_data;
        zen_chunk;
        master_path;
        timerObj;
        alignment_data;
    end
    
    methods (Access = private)
        
        function checkExistence(app, directory_path, data_file)
            % Create new Tree
            newTree = uitree(app.GridLayout30, 'checkbox');
            newTree.Layout.Row = 2;
            newTree.Layout.Column = 1;
            
            % Create an array to store the checked nodes
            checkedNodes = {};
            
            % Check for existence of data.h5
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Scanning for data...','Indeterminate','on');
            if endsWith(data_file,'h5')
                close(d)
                title = sprintf('Loading %s...', data_file);
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title',title,'Indeterminate','on');
                info = h5info(fullfile(directory_path, data_file));
                size_info = h5info(fullfile(directory_path, data_file),'/data');
                app.alignment_data = h5read(fullfile(directory_path, data_file),'/data',[1 1 1 1 1], size_info.ChunkSize);
                if ~any(strcmp({info.Datasets.Name}, 'data')) && ~any(strcmp({info.Datasets.Name}, 'times'))
                    uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'.h5 file structure is invalid. Please refer to documentation.','Error');
                    return
                end
            elseif endsWith(data_file,'nwb')
                close(d)
                title = sprintf('Detected nwb file. Building data structure from %s...', data_file);
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title',title,'Indeterminate','on');
                try
                    whole_file = nwbRead(filename);
                    gc_data = whole_file.acquisition.get('GCaMP_series');
                    gc_data = permute(gc_data,[2,3,1,4]);
                    data = gc_data.data.load();
                    app.alignment_data = data;
                    
                    % Save data_var to the "data" dataset
                    h5create('data.h5', '/data', size(data));
                    h5write('data.h5', '/data', data);

                    data_file = fullfile(directory_path, 'data.h5');
                catch
                    close(d)
                    uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'Unable to build data structure from nwb file. Please refer to documentation.','Error');
                    return
                end
            end
            close(d)
            newNode = uitreenode(newTree);
            newNode.Text = data_file;
            checkedNodes{end+1} = newNode;

            % Check for existence of metadata.json
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Scanning for metadata...','Indeterminate','on');
            if exist(fullfile(directory_path, 'metadata.json'), 'file')
                close(d)
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Loading metadata.json...','Indeterminate','on');
                newNode = uitreenode(newTree);
                newNode.Text = 'Metadata.json';
                checkedNodes{end+1} = newNode;
            else
                close(d)
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','No metadata found. Creating metadata.json...','Indeterminate','on');
                
                % Get dataset information
                dataInfo = h5info(data_file, '/data');
                dataDims = dataInfo.Dataspace.Size;
                
                % Extract the dimensions
                shape_t = dataDims(5);
                shape_c = dataDims(4);
                shape_z = dataDims(3);
                shape_y = dataDims(2);
                shape_x = dataDims(1);
                
                % Create the metadata struct
                metadata = struct('shape_t', shape_t, 'shape_c', shape_c, 'shape_z', shape_z, 'shape_y', shape_y, 'shape_x', shape_x);
                
                % Write the metadata to a JSON file
                jsonStr = jsonencode(metadata);
                jsonFile = fopen([app.master_path,'metadata.json'], 'w');
                fwrite(jsonFile, jsonStr);
                fclose(jsonFile);
            end
            close(d)
            
            % Check for existence of worldlines.h5
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Scanning for worldlines...','Indeterminate','on');
            if exist(fullfile(directory_path, 'worldlines.h5'), 'file')
                close(d)
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Loading worldlines.h5...','Indeterminate','on');
                newNode = uitreenode(newTree);
                newNode.Text = 'Worldlines.h5';
                checkedNodes{end+1} = newNode;
            else
                close(d)
                uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'No worldlines.h5 file found. This cannot be created from data. Please refer to documentation.','Error');
                return
            end
            close(d)
            
            % Check for existence of annotations.h5
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Scanning for annotations...','Indeterminate','on');
            if exist(fullfile(directory_path, 'annotations.h5'), 'file')
                close(d)
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Loading annotations.h5...','Indeterminate','on');
                newNode = uitreenode(newTree);
                newNode.Text = 'Annotations.h5';
                checkedNodes{end+1} = newNode;
            end
            close(d)
            
            % Set the checked nodes
            newTree.CheckedNodes = [checkedNodes{:}];
            
            % Assign Checked Nodes Changed Function
            newTree.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeCheckedNodesChanged, true);
            
            % Replace the existing Tree with the new one
            delete(app.Tree);
            app.Tree = newTree;
            set(app.Tree, 'Enable', 'off');
        end

        function data_packer(app, data_file)
            app.checkExistence(app.master_path, data_file);
        end

        function zeph_wrapper(app, routine)            
            switch routine
                case 'recommend_frames'
                    title = 'Analyzing frames...';
                case 'annotator'
                    title = 'Loading annotator...';
                case 'tracker'
                    title = 'Tracking neurons...';
                case 'tracer'
                    title = 'Calculating traces...';
            end

            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title',title,'Indeterminate','on');
            python_command = ['External_Dependencies\ZephIR\example\npal-wrapper.py ',app.master_path, ' ', routine]
            pyrunfile(python_command);
            close(d)
        end

        function openMinimalBrowser(app)

            %app.NeuroPAL_IDTraceWindowUIFigure.WindowState = 'maximized';
            
            screenSize = get(0, 'ScreenSize');
            axesPosition = app.UIAxes.Position;
            gridPosition = app.MainTraceGrid.Position;
            figurePosition = app.NeuroPAL_IDTraceWindowUIFigure.Position;
            x = figurePosition(1) + axesPosition(1);
            y = screenSize(4) - (figurePosition(2) + axesPosition(2) + axesPosition(4));
            width = axesPosition(3);
            height = gridPosition(4);
            position = [x, y, width, height];
            
            % Absolute path to the packaged Electron application
            [pathToThisFile, ~, ~] = fileparts(mfilename('fullpath'));
            exePath = fullfile(pathToThisFile, 'External_Dependencies', 'ZephIR', 'web-wrap', 'wrap-browser-win32-x64', 'wrap-browser.exe');
            
            args = sprintf('--x %d --y %d --width %d --height %d', position(1), position(2), position(3), position(4));
            batchFile = 'startElectronApp.bat';
            fid = fopen(batchFile, 'wt');
            fprintf(fid, 'start "" "%s" %s', exePath, args);
            fclose(fid);
            
            system(batchFile);
            delete(batchFile);

        end

        function updateBrowserPosition(app)
            screenSize = get(0, 'ScreenSize');
            axesPosition = app.UIAxes.Position;
            gridPosition = app.MainTraceGrid.Position;
            figurePosition = app.NeuroPAL_IDTraceWindowUIFigure.Position;
            x = figurePosition(1) + axesPosition(1);
            y = screenSize(4) - (figurePosition(2) + axesPosition(2) + axesPosition(4));
            width = axesPosition(3);
            height = gridPosition(4);
            position = [x, y, width, height];
            url = sprintf('http://localhost:5003/updatePosition?x=%d&y=%d&width=%d&height=%d', position(1), position(2), position(3), position(4));  
            webread(url); % Send HTTP request
        end

        function startBrowser(app)
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Loading browser...','Indeterminate','on');
            app.zeph_wrapper('annotator');

            if app.UseMATLABbrowserCheckBox.Value == 1
                web('http://localhost:5001/','-new','-notoolbar', '-noaddressbox');
            else
                try
                    app.openMinimalBrowser();
                    % Timer to update coordinates
                    app.timerObj = timer('TimerFcn', @(~,~) app.updateBrowserPosition(), 'Period', 0.1, 'ExecutionMode', 'fixedRate');
                    start(app.timerObj);
                catch
                    web('http://localhost:5001/','-new','-notoolbar', '-noaddressbox');
                end
            end
            close(d)
        end

        function closeBrowser(app)
            try
                % Delete the position update timer
                delete(app.timerObj);
                webread('http://localhost:5002/close');
            catch
                warning('Failed to close Electron window');
            end

            if app.UseMATLABbrowserCheckBox.Value == 1
                com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser')
            end
        end

        function DrawNeurons(app)
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Drawing neurons...','Indeterminate','on');

            extantNeurons = findobj(app.Npal_Axes,'Type','images.roi.Point');
            delete(extantNeurons);

            draw_axes = [];
            if app.DisplayNeuronsCheckBox.Value
                draw_axes = [draw_axes app.Npal_Axes];
            end
            if app.AdjustNeuronMarkerAlignmentPanel.Visible
                draw_axes = [draw_axes app.Npal_Axes];
            end

            if ~isempty(draw_axes)
                for n = 1:size(app.repo_neurons.neurons,2)
                    targ_neuron = app.repo_neurons.neurons(n);
                    targ_neuron.position
                    images.roi.Point(app.Npal_Axes,'Position',[targ_neuron.position(2) targ_neuron.position(1)], 'Color',[0 1 0], 'MarkerSize',3, 'LineWidth',1, 'Label',targ_neuron.annotation, 'LabelVisible','hover');
                end
            end

            close(d)
        end

        function updateVolume(app)
            gcamp_alpha = app.AlphaSlider.Value;
            npal_alpha = 100 - gcamp_alpha;
            hold(app.Npal_Axes,'off')
            
            npal_img = squeeze(max(app.image_view,[],3));
            gcamp_img = squeeze(max(app.alignment_data,[],3));

            if ~isempty(gcamp_img) && gcamp_alpha > 0 && npal_alpha > 0
                % Ensure the images are in double format for computations
                npal_img = double(npal_img);
                gcamp_img = double(gcamp_img);
                
                % Get the size of the images
                [height1, width1, ~] = size(npal_img);
                [height2, width2, ~] = size(gcamp_img);
                
                % If the sizes are not equal, resize the first image to match the second
                if height1 ~= height2 || width1 ~= width2
                    set(app.SizeWarningLabel,'Visible','on');
                    npal_img = imresize(npal_img, [height2, width2]);
                else
                    set(app.SizeWarningLabel,'Visible','off');
                end
                
                % Normalize the images to [0,1] range
                npal_img = npal_img / max(npal_img(:));
                gcamp_img = gcamp_img / max(gcamp_img(:));
                
                % Alpha blending
                result_img = npal_alpha * npal_img + gcamp_alpha * gcamp_img;
                
                % Normalize the result image to [0,1] range
                result_img = result_img / max(result_img(:));

                image(app.Npal_Axes, result_img);

                app.Npal_Axes.XLim = [1, size(result_img, 2)];
                app.Npal_Axes.YLim = [1, size(result_img, 1)];
            else
                if gcamp_alpha == 0 
                    image(app.Npal_Axes, npal_img);
                    app.Npal_Axes.XLim = [1, size(npal_img, 2)];
                    app.Npal_Axes.YLim = [1, size(npal_img, 1)];
                elseif npal_alpha == 0
                    image(app.Npal_Axes, gcamp_img);
                    app.Npal_Axes.XLim = [1, size(gcamp_img, 2)];
                    app.Npal_Axes.YLim = [1, size(gcamp_img, 1)];
                end
            end

            %{
            if npal_alpha > 0
                draw_img = squeeze(max(app.image_view,[],3))
                image(app.Npal_Axes, , 'AlphaData', npal_alpha);
                hold(app.Npal_Axes,'on')
            end

            if gcamp_alpha > 0
                image(app.Npal_Axes, squeeze(max(app.alignment_data,[],3)), 'AlphaData', gcamp_alpha);
                hold(app.Npal_Axes,'on')
            end
            %}

            if app.DisplayNeuronsCheckBox.Value
                app.DrawNeurons()
            end

        end

        function rotation_handler(app, theta)
            % Find bounding box
            min_x = Inf; max_x = -Inf;
            min_y = Inf; max_y = -Inf;
            for n = 1:size(app.repo_neurons.neurons,2)
                pos = app.repo_neurons.neurons(n).position;
                if pos(1) < min_x, min_x = pos(1); end
                if pos(1) > max_x, max_x = pos(1); end
                if pos(2) < min_y, min_y = pos(2); end
                if pos(2) > max_y, max_y = pos(2); end
            end
            
            % Compute center of bounding box
            center_x = (min_x + max_x) / 2;
            center_y = (min_y + max_y) / 2;
            
            % Translate all neurons to origin
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(1) = app.repo_neurons.neurons(n).position(1) - center_x;
                app.repo_neurons.neurons(n).position(2) = app.repo_neurons.neurons(n).position(2) - center_y;
            end
            
            % Compute rotation matrix
            theta = theta * pi / 180;
            R = [cos(theta) -sin(theta); sin(theta) cos(theta)]; % 2D rotation matrix
            
            % Apply rotation matrix to each position vector
            for n = 1:size(app.repo_neurons.neurons,2)
                position = app.repo_neurons.neurons(n).position(1:2); % extract x and y coordinates
                position = R * position'; % apply rotation matrix
                app.repo_neurons.neurons(n).position(1:2) = position'; % update x and y coordinates
            end
            
            % Translate all neurons back to their original position
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(1) = app.repo_neurons.neurons(n).position(1) + center_x;
                app.repo_neurons.neurons(n).position(2) = app.repo_neurons.neurons(n).position(2) + center_y;
            end
        end


        %% Draw the annotated image (image volume & neuron markers).
        function DrawImageData(app, slice)

            % Is there an image?
            if isempty(app.image_data)
                return;
            end

            % Determine the color channel indices.
            red = app.red;
            green = app.green;
            blue = app.blue;
            white = app.white;
            dic = app.dic;
            gfp = app.gfp;

            % Determine the channel=color assignments for displaying.
            color_indices = [red, green, blue];

            % Draw the 3 color channels.
            app.image_view = app.image_data(:,:,slice,color_indices);

            % Remove unchecked color channels.
            if ~app.RCheckbox.Value % Red
                app.image_view(:,:,slice,red) = 0;
            end
            if ~app.GCheckbox.Value % Green
                app.image_view(:,:,slice,green) = 0;
            end
            if ~app.BCheckbox.Value % Blue
                app.image_view(:,:,slice,blue) = 0;
            end

            % Add in the white channel.
            if app.WCheckbox.Value % White

                % Compute the white channel.
                wchannel = app.image_data(:,:,slice,white);

                % Adjust the gamma.
                W_i = app.gamma_RGBW_DIC_GFP_index(4); % white channel gamma index
                if length(app.image_gamma) >= W_i && app.image_gamma(W_i) ~= 1
                    wchannel = imadjustn(wchannel,[],[], app.image_gamma(W_i));
                end

                % Add the white channel.
                app.image_view = app.image_view + repmat(wchannel, [1,1,1,3]);
            end

            % Add in the GFP channel.
            if app.GFPCheckbox.Value % GFP

                % Compute the GFP channel.
                gfp_color = Program.GUIPreferences.instance().GFP_color;
                gfp_channel = app.image_data(:,:,slice,gfp);

                % Adjust the gamma.
                GFP_i = app.gamma_RGBW_DIC_GFP_index(6); % GFP channel gamma index
                if length(app.image_gamma) >= GFP_i && app.image_gamma(GFP_i) ~= 1
                    gfp_channel = imadjustn(gfp_channel,[],[], app.image_gamma(GFP_i));
                end

                % Add the GFP channel.
                gfp_channel = repmat(gfp_channel, [1,1,1,3]);
                gfp_channel(:,:,slice,~gfp_color) = 0;
                app.image_view = app.image_view + gfp_channel;
            end

            % Adjust the gamma.
            % Note: the image only shows RGB. We added the other channels
            % (W, DIC, GFP) to the RGB in order to show these as well.

            app.image_view = uint16(double(intmax('uint16')) * ...
                double(app.image_view)/double(max(app.image_view(:))));
            for c = 1:size(app.image_view, 4)
                if app.image_gamma(c) ~= 1
                    app.image_view(:,:,:,c) = ...
                        imadjustn(squeeze(app.image_view(:,:,:,c)),[],[], ...
                        app.image_gamma(c));
                end
            end
            app.image_view = double(app.image_view)/double(max(app.image_view(:)));

            % Redraw the max projection.
            % Note: the image only shows RGB. We added the other channels
            % (W, DIC, GFP) to the RGB in order to show these as well.
            image(app.Npal_Axes, squeeze(max(app.image_view,[],3)));
        end


    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, parent_app, image_data, image_view, image_neurons, path, dir, red, green, blue, white, dic, gfp, image_gamma)
            app.parent_app = parent_app;
            app.image_data = image_data;
            app.image_view = image_view;
            app.repo_neurons = image_neurons;
            app.image_neurons = image_neurons;
            app.image_gamma = image_gamma;
            app.path = path;
            app.dir = dir;

            app.red = str2double(red);
            app.green = str2double(green);
            app.blue = str2double(blue);
            app.white = str2double(white);
            app.dic = str2double(dic);
            app.gfp = str2double(gfp);

            % Resize the figure to fit most of the screen size.
            screen_size = get(groot, 'ScreenSize');
            screen_size = screen_size(3:4);
            screen_margin = floor(screen_size .* [0.07,0.05]);
            figure_size(1:2) = screen_margin / 2;
            figure_size(3) = screen_size(1) - screen_margin(1);
            figure_size(4) = screen_size(2) - 2*screen_margin(2);
            drawnow; % need to draw before resizing
            app.NeuroPAL_IDTraceWindowUIFigure.Position = figure_size;

            app.updateVolume()
        end

        % Button pushed function: ViewPreprintButton
        function ViewPreprintButtonPushed(app, event)
            web('https://www.biorxiv.org/content/10.1101/2022.07.18.500485v1')
        end

        % Button pushed function: GithubRepositoryButton
        function GithubRepositoryButtonPushed(app, event)
            web('https://github.com/venkatachalamlab/ZephIR')
        end

        % Button pushed function: LaboratoryPageButton
        function LaboratoryPageButtonPushed(app, event)
            web('https://venkatachalamlab.org/')
        end

        % Button pushed function: ClicktoselectvideofileButton
        function ClicktoselectvideofileButtonPushed(app, event)
            % Prompt user to select video file
            [file,path] = uigetfile({'*.h5;*.nwb','Supported Files (*.h5, *.nwb)'},'Select GCaMP file');
    
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Loading data...', 'Indeterminate','on');
            app.master_path = path;
            app.data_packer(file);
            app.startBrowser();
            app.UIAxes.Color = [0, 0, 0];

            set(app.AlphaSlider, 'Enable', 'On');
            set(app.SetbookmarkButton,'Enable','On');
            set(app.AdjustAlignmentButton,'Enable','On');
            set(app.TrackNeuronsButton,'Enable','On');
            set(app.ExtractActivityTracesButton,'Enable','On');
            set(app.SaveResultsButton,'Enable','On');
            set(app.RecommendFramesButton,'Enable','On');
            set(app.MotionSlider,'Enable','On');
            set(app.FilesLoadedLabel,'Enable','On');
            set(app.WormMotionPanel,'Enable','On');
            set(app.BookmarkedFramesPanel,'Enable','On');
            set(app.ListBox,'Enable','On');
            set(app.EnableManualZephirSettingsCheckBox,'Enable','On');
            set(app.ClicktoselectvideofileButton,'Visible','Off');
            close(d)
        end

        % Button pushed function: TrackNeuronsButton
        function TrackNeuronsButtonPushed(app, event)
            check = uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'Depending on your computer, this may take a while. Are you sure you want to proceed?','Warning!','Options',{'Yes','No'},'DefaultOption','Yes');

            switch check
                case 'Yes'
    
                    d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Processing arguments...','Indeterminate','on');
                    
                    % Initialize a struct to store the argument values
                    args = struct();
                    
                    % --help and --version are set to false by default
                    args.("--help") = false;
                    args.("--version") = false;
                    
                    % Set default values for some arguments
                    %{
                    args.("--dataset") = ".";
                    args.("--t_track") = "null";
                    args.("--exclusive_prov") = "null";
                    args.("--n_ref") = "null";
                    args.("--t_ignore") = "null";
                    args.("--wlid_ref") = "null";
                    args.("--t_ref") = "null";
                    args.("--n_frame") = "1";
                    args.("--include_all") = "True"; % Include_all is set to True by default
                    args.("--load_checkpoint") = "False"; % Load_checkpoint is set to False by default
                    args.("--exclude_self") = "True"; % Exclude_self is set to True by default
                    args.("--gamma") = "2"; % Gamma is set to 2 by default
                    args.("--allow_rotation") = "False"; % Allow_rotation is set to False by default
                    %}
                    
                    % Get values from the UI elements and set them in the args struct
                    args.("--n_epoch_d") = num2str(app.n_epoch_d.Value);
                    args.("--fovea_sigma") = num2str(app.fovea_sigma.Value);
                    args.("--lr_coef") = num2str(app.lr_coeff.Value);
                    args.("--lambda_d") = num2str(app.l_d.Value);
                    args.("--lr_ceiling") = num2str(app.lr_ceiling.Value);
                    args.("--nn_max") = num2str(app.nn_max.Value);
                    args.("--z_compensator") = num2str(app.z_comp.Value);
                    args.("--lambda_n") = num2str(app.l_n.Value);
                    args.("--n_epoch") = num2str(app.n_epoch.Value);
                    args.("--lr_floor") = num2str(app.lr_floor.Value);
                    args.("--channel") = "1"; % Channel is set to 1 by default
                    args.("--load_nn") = "False"; % Load_nn is set to False by default
                    args.("--n_chunks") = num2str(app.n_chunks.Value);
                    args.("--motion_predict") = app.motion_predict.Value;
                    args.("--load_args") = "True"; % Load_args is set to True by default
                    args.("--lambda_t") = num2str(app.l_t.Value);
                    args.("--lambda_n_mode") = app.l_n_mode.Value;
                    args.("--sort_mode") = app.sort_mode.Value;
                    args.("--grid_shape") = num2str(app.grid_shape.Value);
                    args.("--clip_grad") = num2str(app.clip_grad.Value);
                    args.("--cuda") = app.use_gpu.Value; % Cuda is set to True by default
                    args.("--dimmer_ratio") = num2str(app.dimmer_ratio.Value);
                    
                    % Write the args struct to the "args.json" file
                    jsonStr = jsonencode(args);
                    fid = fopen('External_Dependencies\ZephIR\example\data\args.json', 'w');
                    fprintf(fid, '%s', jsonStr);
                    fclose(fid);

                    copyfile('External_Dependencies\ZephIR\example\data\args.json',[app.master_path,'args.json']);

                    close(d)
                    
                    app.closeBrowser();

                    try
                        d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Running tracker...','Indeterminate','on');
                        
                        app.zeph_wrapper('tracker');
                        
                        close(d)
                    catch
                        uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'run_tracker failed.','Error');
                    end
        
                    app.startBrowser();

                case 'No'
                    return
            end
        end

        % Button pushed function: ExtractActivityTracesButton
        function ExtractActivityTracesButtonPushed(app, event)
            app.closeBrowser();

            try
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Running tracer...','Indeterminate','on');
                
                app.zeph_wrapper('tracer');
                
                close(d)
            catch
                uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'run_tracer failed.','Error');
            end

            app.startBrowser();
        end

        % Value changed function: EnableManualZephirSettingsCheckBox
        function EnableManualZephirSettingsCheckBoxValueChanged(app, event)
            if app.EnableManualZephirSettingsCheckBox.Value == 1
                app.closeBrowser()
                check = uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'These are complicated settings that may yield unexpected results. We do not recommend changing them unless you have read the documentation and know what you are doing. Are you sure you want to proceed?','Warning!','Options',{'Yes', 'No'},'DefaultOption','No');

                switch check
                    case 'Yes'
                        % Well, we tried to warn them.
                    case 'No'
                        app.EnableManualZephirSettingsCheckBox.Value = 0;
                        return
                end
                app.startBrowser()

                set(app.use_gpu,'Enable','On')
                set(app.n_epoch,'Enable','On')
                set(app.n_epoch_d,'Enable','On')
                set(app.n_chunks,'Enable','On')
                set(app.clip_grad,'Enable','On')
                set(app.l_t,'Enable','On')
                set(app.l_d,'Enable','On')
                set(app.l_n,'Enable','On')
                set(app.z_comp,'Enable','On')
                set(app.lr_coeff,'Enable','On')
                set(app.lr_floor,'Enable','On')
                set(app.l_n_mode,'Enable','On')
                set(app.nn_max,'Enable','On')
                set(app.lr_ceiling,'Enable','On')
                set(app.fovea_sigma,'Enable','On')
                set(app.sort_mode,'Enable','On')
                set(app.grid_shape,'Enable','On')
                set(app.motion_predict,'Enable','On')
                set(app.dimmer_ratio,'Enable','On')
            else
                set(app.n_epoch,'Enable','Off')
                set(app.n_epoch_d,'Enable','Off')
                set(app.n_chunks,'Enable','Off')
                set(app.use_gpu,'Enable','Off')
                set(app.clip_grad,'Enable','Off')
                set(app.l_t,'Enable','Off')
                set(app.l_d,'Enable','Off')
                set(app.l_n,'Enable','Off')
                set(app.z_comp,'Enable','Off')
                set(app.lr_coeff,'Enable','Off')
                set(app.lr_floor,'Enable','Off')
                set(app.l_n_mode,'Enable','Off')
                set(app.nn_max,'Enable','Off')
                set(app.lr_ceiling,'Enable','Off')
                set(app.fovea_sigma,'Enable','Off')
                set(app.sort_mode,'Enable','Off')
                set(app.grid_shape,'Enable','Off')
                set(app.motion_predict,'Enable','Off')
                set(app.dimmer_ratio,'Enable','On')
            end
        end

        % Button pushed function: SetbookmarkButton
        function SetbookmarkButtonPushed(app, event)
            bmLabel = ['Bookmark #',int2str(size(app.ListBox.Items,2)+1)];

            url = 'http://localhost:5001/current_time_point';
            response = webread(url);

            bmFrame = response.time_point;
            app.ListBox.Items = [app.ListBox.Items, bmLabel];
            if size(app.ListBox.ItemsData)>0
                app.ListBox.ItemsData = [app.ListBox.ItemsData, bmFrame];
            else
                app.ListBox.ItemsData = [bmFrame];
            end
        end

        % Clicked callback: ListBox
        function ListBoxClicked(app, event)
            target_frame = round(event.InteractionInformation.Item);
            url = 'http://localhost:5001/current_time_point';
            response = webread(url);
        end

        % Button pushed function: Up
        function UpPushed(app, event)
            switch app.SelectionButtonGroup.SelectedObject.Text
                case 'Move Neurons'
                    for n = 1:size(app.repo_neurons.neurons,2)
                        app.repo_neurons.neurons(n).position(1) = app.repo_neurons.neurons(n).position(1)-app.MoveEditField_2.Value;
                    end
                    app.DrawNeurons();
                case 'Move Video'
            end
        end

        % Button pushed function: AdjustAlignmentButton
        function AdjustAlignmentButtonPushed(app, event)
            d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Loading alignment interface...','Indeterminate','on');
            set(app.AdjustNeuronMarkerAlignmentPanel,'Visible','On');
            app.AdjustNeuronMarkerAlignmentPanel.Position = app.TabGroup.Position;
            close(d)
        end

        % Button pushed function: SaveResultButton
        function SaveResultButtonPushed(app, event)
            set(app.AdjustNeuronMarkerAlignmentPanel,'Visible','Off');
            app.UIAxes = uiaxes(app.MainTraceGrid);
            app.UIAxes.XColor = 'none';
            app.UIAxes.XTick = [];
            app.UIAxes.XTickLabel = '';
            app.UIAxes.YColor = 'none';
            app.UIAxes.YTick = [];
            app.UIAxes.ZColor = 'none';
            app.UIAxes.Color = 'none';
            app.UIAxes.Layout.Row = [1 2];
            app.UIAxes.Layout.Column = 2;
            app.startBrowser();
        end

        % Button pushed function: Right
        function RightButtonPushed(app, event)
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(2) = app.repo_neurons.neurons(n).position(2)+app.MoveEditField_2.Value;
            end
            app.updateVolume()
            app.DrawNeurons();
        end

        % Button pushed function: Left
        function LeftButtonPushed(app, event)
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(2) = app.repo_neurons.neurons(n).position(2)-app.MoveEditField_2.Value;
            end
            app.updateVolume()
            app.DrawNeurons();
        end

        % Button pushed function: Down
        function DownButtonPushed(app, event)
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(1) = app.repo_neurons.neurons(n).position(1)+app.MoveEditField_2.Value;
            end
            app.updateVolume()
            app.DrawNeurons();
        end

        % Button pushed function: FlipHorizontallyButton
        function FlipHorizontallyButtonPushed(app, event)
            % Find the center of the bounding box
            bbox = [inf, -inf, inf, -inf, inf, -inf];
            for n = 1:size(app.image_neurons.neurons, 2)
                pos = app.image_neurons.neurons(n).position;
                bbox(1) = min(bbox(1), pos(1));
                bbox(2) = max(bbox(2), pos(1));
                bbox(3) = min(bbox(3), pos(2));
                bbox(4) = max(bbox(4), pos(2));
                bbox(5) = min(bbox(5), pos(3));
                bbox(6) = max(bbox(6), pos(3));
            end
            center = [(bbox(1)+bbox(2))/2, (bbox(3)+bbox(4))/2, (bbox(5)+bbox(6))/2];
        
            % Flip all neurons horizontally around the center point
            for n = 1:size(app.image_neurons.neurons, 2)
                pos = app.image_neurons.neurons(n).position;
                new_pos = [pos(1), 2*center(2)-pos(2), pos(3)];
                app.image_neurons.neurons(n).position = new_pos;
            end
        
            app.updateVolume()
            app.DrawNeurons();
        end

        % Button pushed function: FlipVerticallyButton
        function FlipVerticallyButtonPushed(app, event)
            % Find the center of the bounding box
            bbox = [inf, -inf, inf, -inf, inf, -inf];
            for n = 1:size(app.image_neurons.neurons, 2)
                pos = app.image_neurons.neurons(n).position;
                bbox(1) = min(bbox(1), pos(1));
                bbox(2) = max(bbox(2), pos(1));
                bbox(3) = min(bbox(3), pos(2));
                bbox(4) = max(bbox(4), pos(2));
                bbox(5) = min(bbox(5), pos(3));
                bbox(6) = max(bbox(6), pos(3));
            end
            center = [(bbox(1)+bbox(2))/2, (bbox(3)+bbox(4))/2, (bbox(5)+bbox(6))/2];
        
            % Flip all neurons vertically around the center point
            for n = 1:size(app.image_neurons.neurons, 2)
                pos = app.image_neurons.neurons(n).position;
                new_pos = [2*center(1)-pos(1), pos(2), pos(3)];
                app.image_neurons.neurons(n).position = new_pos;
            end
        
            app.updateVolume()
            app.DrawNeurons();
        end

        % Button pushed function: CCW
        function CCWButtonPushed(app, event)
            app.rotation_handler(app.repo_neurons.neurons,90);         
            app.updateVolume()   
            
            %{
            %}
            
            app.DrawNeurons();
        end

        % Button pushed function: CenterHorizontallyButton
        function CenterHorizontallyButtonPushed(app, event)
            % Find the vertical extent of the neurons
            min_y = Inf; max_y = -Inf;
            for n = 1:size(app.repo_neurons.neurons,2)
                pos = app.repo_neurons.neurons(n).position;
                if pos(2) < min_y, min_y = pos(2); end
                if pos(2) > max_y, max_y = pos(2); end
            end
            
            % Compute the center of the UIAxes
            center_y = mean(app.Npal_Axes.YLim);
            
            % Compute the displacement needed to center the neurons vertically
            dy = center_y - (min_y + max_y) / 2;
            
            % Translate all neurons by the computed displacement
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(2) = app.repo_neurons.neurons(n).position(2) + dy;
            end
            
            app.updateVolume()
            app.DrawNeurons();
        end

        % Button pushed function: CenterVerticallyButton
        function CenterVerticallyButtonPushed(app, event)
            % Find the horizontal extent of the neurons
            min_x = Inf; max_x = -Inf;
            for n = 1:size(app.repo_neurons.neurons,2)
                pos = app.repo_neurons.neurons(n).position;
                if pos(1) < min_x, min_x = pos(1); end
                if pos(1) > max_x, max_x = pos(1); end
            end
            
            % Compute the center of the UIAxes
            center_x = mean(app.Npal_Axes.XLim);
            
            % Compute the displacement needed to center the neurons horizontally
            dx = center_x - (min_x + max_x) / 2;
            
            % Translate all neurons by the computed displacement
            for n = 1:size(app.repo_neurons.neurons,2)
                app.repo_neurons.neurons(n).position(1) = app.repo_neurons.neurons(n).position(1) + dx;
            end
            
            app.updateVolume()
            app.DrawNeurons();
        end

        % Close request function: NeuroPAL_IDTraceWindowUIFigure
        function NeuroPAL_IDTraceWindowUIFigureCloseRequest(app, event)
            try
                app.NeuroPAL_IDTraceWindowUIFigure.WindowState = 'normal';
                app.closeBrowser();
            catch
                'No browser detected.'
            end

            app.repo_neurons = app.image_neurons;
            delete(app)
        end

        % Value changed function: ScaleEditField
        function ScaleEditFieldValueChanged(app, event)
            % Get the scaling factor from the TransformScale slider
            scale_factor = app.ScaleEditField.Value;
        
            % Find the center of the bounding box
            bbox = [inf, -inf, inf, -inf, inf, -inf];
            for n = 1:size(app.image_neurons.neurons, 2)
                pos = app.image_neurons.neurons(n).position;
                bbox(1) = min(bbox(1), pos(1));
                bbox(2) = max(bbox(2), pos(1));
                bbox(3) = min(bbox(3), pos(2));
                bbox(4) = max(bbox(4), pos(2));
                bbox(5) = min(bbox(5), pos(3));
                bbox(6) = max(bbox(6), pos(3));
            end
            center = [(bbox(1)+bbox(2))/2, (bbox(3)+bbox(4))/2, (bbox(5)+bbox(6))/2];
        
            % Scale all neurons around the center point
            for n = 1:size(app.image_neurons.neurons, 2)
                pos = app.image_neurons.neurons(n).position;
                displacement = pos - center;
                new_displacement = displacement * scale_factor;
                app.image_neurons.neurons(n).position = center + new_displacement;
            end
        
            app.updateVolume()
            app.DrawNeurons();
        end

        % Value changed function: MotionSlider
        function MotionSliderValueChanged(app, event)
            app.MotionSlider.Value = round(app.MotionSlider.Value);

            switch app.MotionSlider.Value
                case 0
                    app.l_n.Value = 2.0;
                    app.lr_floor.Value = 0.01;
                    app.z_comp.Value = 0.5;
                    app.lr_ceiling.Value = 0.1;
                    app.lr_coeff.Value = 1.0;
                    app.sort_mode.Value = 'linear';
                case 1
                case 2
                    app.clip_grad.Value = 0.2;
                    app.l_n.Value = 0.1;
                    app.lr_floor.Value = 0.01;
                    app.lr_ceiling.Value = 0.1;
                case 3
                    app.clip_grad.Value = 1;
                    app.l_n_mode.Value = 'norm';
                    app.lr_floor.Value = 0.1;
                    app.z_comp.Value = 4.0;
                    app.fovea_sigma.Value = 10;
                    app.grid_shape.Value = 49;
                    app.lr_ceiling.Value = 0.1;
                    app.motion_predict.Value = 'True';
            end
            
        end

        % Button pushed function: RecommendFramesButton
        function RecommendFramesButtonPushed(app, event)
            app.closeBrowser();

            try
                try
                    app.zeph_wrapper('recommend_frames');
                catch
                    uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'recommend_frames experienced a code error.','Error');
                end
    
                file_path = fullfile(app.master_path, 'metadata.json');
                data = jsondecode(fileread(file_path));
                keys = fieldnames(data);
                t_ref_keys = startsWith(keys, 't_ref');
                t_ref_fn_keys = startsWith(keys, 't_ref_fn');
                all_keys = [keys(t_ref_keys); keys(t_ref_fn_keys)];
                
                max_num = 0;
                for i = 1:numel(all_keys)
                    key = all_keys{i};
                    num = str2double(regexp(key, 't_ref(\d+)', 'tokens', 'once'));
                    if ~isnan(num) && num > max_num
                        max_num = num;
                        values = data.(key);
                    end
                end
                
                t_frames = unique(values);
    
                d = uiprogressdlg(app.NeuroPAL_IDTraceWindowUIFigure,'Title','Creating bookmarks...','Indeterminate','on');
                for n=1:size(t_frames)
                    bmLabel = ['Recommended Frame #',int2str(n)];
                    bmFrame = t_frames(n);
                    app.ListBox.Items = [app.ListBox.Items, bmLabel];
                    if size(app.ListBox.ItemsData)>0
                        app.ListBox.ItemsData = [app.ListBox.ItemsData, bmFrame];
                    else
                        app.ListBox.ItemsData = [bmFrame];
                    end
                end
                close(d)
            catch
                uiconfirm(app.NeuroPAL_IDTraceWindowUIFigure,'recommend_frames failed.','Error');
            end

            app.startBrowser();
        end

        % Button pushed function: ResetMoveButton
        function ResetMoveButtonPushed(app, event)
            app.repo_neurons.neurons = app.image_neurons.neurons;
            app.DrawNeurons();
        end

        % Button pushed function: ResetTransformButton
        function ResetTransformButtonPushed(app, event)
            app.repo_neurons.neurons = app.image_neurons.neurons;
            app.DrawNeurons();
        end

        % Key press function: NeuroPAL_IDTraceWindowUIFigure
        function NeuroPAL_IDTraceWindowUIFigureKeyPress(app, event)
            % Is there an image?
            if isempty(app.image_data)
                return;
            end

            % What did the user press?
            key = event.Key;
            switch key

                case '0' % Toggle the ID atlas.
                    app.ColorAtlasCheckBox.Value = ~app.ColorAtlasCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case '1' % Toggle the red channel.
                    app.RCheckBox.Value = ~app.RCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case '2' % Toggle the green channel.
                    app.GCheckBox.Value = ~app.GCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case '3' % Toggle the blue channel.
                    app.BCheckBox.Value = ~app.BCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case '4' % Toggle the white channel.
                    app.WCheckBox.Value = ~app.WCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case '5' % Toggle the DIC channel.
                    app.DICCheckBox.Value = ~app.DICCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case '6' % Toggle the GFP channel.
                    app.GFPCheckBox.Value = ~app.GFPCheckBox.Value;
                    app.DrawImageData(round(app.AlphaSlider.Value));

                case 'leftarrow' % Go up in the z stack.
                    if app.AlphaSlider.Value > 1
                        zEvent.Value = app.AlphaSlider.Value - 1;
                        app.AlphaSliderValueChanged(zEvent);
                    end
                    %disp(key);

                case 'rightarrow' % Go down in the z stack.
                    if app.AlphaSlider.Value < app.AlphaSlider.Limits(2)
                        zEvent.Value = app.AlphaSlider.Value + 1;
                        app.AlphaSliderValueChanged(zEvent);
                    end
                    %disp(key);

                case 'uparrow' % Zoom in.
                    zoom(app.Npal_Axes, 1 + 0.2);

                case 'downarrow' % Zoom out.
                    zoom(app.Npal_Axes, 1 - 0.2);

                case {'h','H'} % Toggle half zoom.
                    % Reset x-axis limits.
                    app.Npal_Axes.XLim = [1, size(app.image_data, 2)];

                    % Upper -> lower half.
                    ylims = app.Npal_Axes.YLim;
                    if ylims(1) < size(app.image_data, 1)/2
                        app.Npal_Axes.YLim = [ceil(size(app.image_data, 1)/2), ...
                            size(app.image_data, 1)];

                        % Lower -> upper half.
                    else
                        app.Npal_Axes.YLim = [1, floor(size(app.image_data, 1)/2)];
                    end

                case {'j','J'} % Toggle third zoom.
                    % Reset x-axis limits.
                    app.Npal_Axes.XLim = [1, size(app.image_data, 2)];

                    % Upper -> middle third.
                    ylims = app.Npal_Axes.YLim;
                    if ylims(1) < size(app.image_data, 1)/3
                        app.Npal_Axes.YLim = [ceil(size(app.image_data, 1)/3), ...
                            floor(size(app.image_data, 1)*2/3)];

                        % Middle -> lower third.
                    elseif ylims(1) < size(app.image_data, 1)*2/3
                        app.Npal_Axes.YLim = [ceil(size(app.image_data, 1)*2/3), ...
                            size(app.image_data, 1)];

                        % Lower -> upper third.
                    else
                        app.Npal_Axes.YLim = [1, floor(size(app.image_data, 1)/3)];
                    end

                case {'k','K'} % Toggle quarter zoom.
                    % Reset x-axis limits.
                    app.Npal_Axes.XLim = [1, size(app.image_data, 2)];

                    % Upper -> upper-middle quarter.
                    ylims = app.Npal_Axes.YLim;
                    if ylims(1) < size(app.image_data, 1)/4
                        app.Npal_Axes.YLim = [ceil(size(app.image_data, 1)/4), ...
                            floor(size(app.image_data, 1)*2/4)];

                        % Upper-middle -> lower-middle quarter.
                    elseif ylims(1) < size(app.image_data, 1)*2/4
                        app.Npal_Axes.YLim = [ceil(size(app.image_data, 1)*2/4), ...
                            floor(size(app.image_data, 1)*3/4)];

                        % Lower-middle -> lower quarter.
                    elseif ylims(1) < size(app.image_data, 1)*3/4
                        app.Npal_Axes.YLim = [ceil(size(app.image_data, 1)*3/4), ...
                            size(app.image_data, 1)];

                        % Lower -> upper quarter.
                    else
                        app.Npal_Axes.YLim = [1, floor(size(app.image_data, 1)/4)];
                    end

                case {'p','P'} % Toggle image panning.

                    % Toggle image panning.
                    if app.is_panning
                        pan(app.Npal_Axes,'off');
                        pause(0.5);
                        RestorePointer(app);
                        app.is_panning = false;
                    else
                        pan(app.Npal_Axes,'on');
                        pause(0.5);
                        app.is_panning = true;
                    end

                case {'r','R'} % Reset the figure to center.
                    app.Npal_Axes.XLim = [1, size(app.image_data, 2)];
                    app.Npal_Axes.YLim = [1, size(app.image_data, 1)];
                    %app.XY.XLim = [1, size(app.image_data, 2)];
                    %app.XY.YLim = [1, size(app.image_data, 1)];
                    %app.XY.XAxisLocation = 'bottom';
                    %app.XY.YAxisLocation = 'left';

                    %case {'x','X'} % Switch mouse to crosshairs.
                    %zoom(app.XY,'on');
                    %pause(0.2);
                    %zoom(app.XY,'off');

                otherwise
                    % Do nothing.
            end

        end

        % Callback function
        function SaveNeuronIDsButtonPushed(app, event)
            set(app.IDCurrentFramePanel,'Enable','Off');
        end

        % Value changed function: UseMATLABbrowserCheckBox
        function UseMATLABbrowserCheckBoxValueChanged(app, event)
            if ~app.ClicktoselectvideofileButton.Visible
                app.closeBrowser()
                app.startBrowser()
            end
        end

        % Value changed function: AlphaSlider
        function AlphaSliderValueChanged(app, event)
            app.updateVolume();
        end

        % Value changed function: DisplayNeuronsCheckBox
        function DisplayNeuronsCheckBoxValueChanged(app, event)
            app.updateVolume();
        end

        % Value changed function: HeightSpinner
        function HeightSpinnerValueChanged(app, event)
            value = app.HeightSpinner.Value;
            app.repo_neurons.neurons
            pos_arr = app.repo_neurons.neurons.position
            class(pos_arr)
        end

        % Button pushed function: CW
        function CWButtonPushed(app, event)
            app.rotation_handler(app.repo_neurons.neurons,-90);     
            app.updateVolume()
            app.DrawNeurons()
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create NeuroPAL_IDTraceWindowUIFigure and hide until all components are created
            app.NeuroPAL_IDTraceWindowUIFigure = uifigure('Visible', 'off');
            app.NeuroPAL_IDTraceWindowUIFigure.Position = [100 100 1810 1077];
            app.NeuroPAL_IDTraceWindowUIFigure.Name = 'NeuroPAL_ID Trace Window';
            app.NeuroPAL_IDTraceWindowUIFigure.CloseRequestFcn = createCallbackFcn(app, @NeuroPAL_IDTraceWindowUIFigureCloseRequest, true);
            app.NeuroPAL_IDTraceWindowUIFigure.KeyPressFcn = createCallbackFcn(app, @NeuroPAL_IDTraceWindowUIFigureKeyPress, true);

            % Create MainTraceGrid
            app.MainTraceGrid = uigridlayout(app.NeuroPAL_IDTraceWindowUIFigure);
            app.MainTraceGrid.ColumnWidth = {795, '1x'};
            app.MainTraceGrid.RowHeight = {375, '17.75x'};
            app.MainTraceGrid.Padding = [0 0 0 0];

            % Create UIAxes
            app.UIAxes = uiaxes(app.MainTraceGrid);
            app.UIAxes.XColor = 'none';
            app.UIAxes.XTick = [];
            app.UIAxes.XTickLabel = '';
            app.UIAxes.YColor = 'none';
            app.UIAxes.YTick = [];
            app.UIAxes.ZColor = 'none';
            app.UIAxes.Color = 'none';
            app.UIAxes.Layout.Row = [1 2];
            app.UIAxes.Layout.Column = 2;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.MainTraceGrid);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create CentralControlTab
            app.CentralControlTab = uitab(app.TabGroup);
            app.CentralControlTab.Title = 'Central Control';

            % Create Panel_4
            app.Panel_4 = uipanel(app.CentralControlTab);
            app.Panel_4.AutoResizeChildren = 'off';
            app.Panel_4.BorderType = 'none';
            app.Panel_4.BackgroundColor = [0.902 0.902 0.902];
            app.Panel_4.Position = [3 2 787 349];

            % Create GridLayout12
            app.GridLayout12 = uigridlayout(app.Panel_4);
            app.GridLayout12.ColumnWidth = {'1.8x', '1x', 160};
            app.GridLayout12.RowHeight = {115, '1x'};
            app.GridLayout12.ColumnSpacing = 6.5;
            app.GridLayout12.RowSpacing = 12.75;
            app.GridLayout12.Padding = [6.5 12.75 6.5 12.75];

            % Create Panel_8
            app.Panel_8 = uipanel(app.GridLayout12);
            app.Panel_8.AutoResizeChildren = 'off';
            app.Panel_8.Layout.Row = [1 2];
            app.Panel_8.Layout.Column = [1 2];

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.Panel_8);
            app.GridLayout8.ColumnWidth = {100, '1x'};
            app.GridLayout8.RowHeight = {'1x', '1x', '1x'};

            % Create SetbookmarkButton
            app.SetbookmarkButton = uibutton(app.GridLayout8, 'push');
            app.SetbookmarkButton.ButtonPushedFcn = createCallbackFcn(app, @SetbookmarkButtonPushed, true);
            app.SetbookmarkButton.Enable = 'off';
            app.SetbookmarkButton.Layout.Row = 3;
            app.SetbookmarkButton.Layout.Column = 2;
            app.SetbookmarkButton.Text = 'Set bookmark';

            % Create BookmarkedFramesPanel
            app.BookmarkedFramesPanel = uipanel(app.GridLayout8);
            app.BookmarkedFramesPanel.AutoResizeChildren = 'off';
            app.BookmarkedFramesPanel.Enable = 'off';
            app.BookmarkedFramesPanel.TitlePosition = 'centertop';
            app.BookmarkedFramesPanel.Title = 'Bookmarked Frames';
            app.BookmarkedFramesPanel.Layout.Row = [1 2];
            app.BookmarkedFramesPanel.Layout.Column = 2;
            app.BookmarkedFramesPanel.FontWeight = 'bold';

            % Create GridLayout13
            app.GridLayout13 = uigridlayout(app.BookmarkedFramesPanel);
            app.GridLayout13.Padding = [0 0 0 0];

            % Create ListBox
            app.ListBox = uilistbox(app.GridLayout13);
            app.ListBox.Items = {};
            app.ListBox.Enable = 'off';
            app.ListBox.Layout.Row = [1 2];
            app.ListBox.Layout.Column = [1 2];
            app.ListBox.ClickedFcn = createCallbackFcn(app, @ListBoxClicked, true);
            app.ListBox.Value = {};

            % Create WormMotionPanel
            app.WormMotionPanel = uipanel(app.GridLayout8);
            app.WormMotionPanel.AutoResizeChildren = 'off';
            app.WormMotionPanel.Enable = 'off';
            app.WormMotionPanel.TitlePosition = 'centertop';
            app.WormMotionPanel.Title = 'Worm Motion';
            app.WormMotionPanel.Layout.Row = [1 3];
            app.WormMotionPanel.Layout.Column = 1;
            app.WormMotionPanel.FontWeight = 'bold';

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.WormMotionPanel);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {'1x'};

            % Create MotionSlider
            app.MotionSlider = uislider(app.GridLayout5);
            app.MotionSlider.Limits = [0 3];
            app.MotionSlider.MajorTicks = [0 1 2 3];
            app.MotionSlider.MajorTickLabels = {'None', 'Low', 'Mid', 'High'};
            app.MotionSlider.Orientation = 'vertical';
            app.MotionSlider.ValueChangedFcn = createCallbackFcn(app, @MotionSliderValueChanged, true);
            app.MotionSlider.MinorTicks = [];
            app.MotionSlider.Enable = 'off';
            app.MotionSlider.Layout.Row = 1;
            app.MotionSlider.Layout.Column = 1;

            % Create Panel_6
            app.Panel_6 = uipanel(app.GridLayout12);
            app.Panel_6.AutoResizeChildren = 'off';
            app.Panel_6.Layout.Row = 2;
            app.Panel_6.Layout.Column = 3;

            % Create GridLayout29
            app.GridLayout29 = uigridlayout(app.Panel_6);
            app.GridLayout29.ColumnWidth = {'1x'};
            app.GridLayout29.RowHeight = {'1x', 23, 23, 23, 23, 23};
            app.GridLayout29.RowSpacing = 8.2;
            app.GridLayout29.Padding = [9 9 9 9];

            % Create RecommendFramesButton
            app.RecommendFramesButton = uibutton(app.GridLayout29, 'push');
            app.RecommendFramesButton.ButtonPushedFcn = createCallbackFcn(app, @RecommendFramesButtonPushed, true);
            app.RecommendFramesButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.RecommendFramesButton.Enable = 'off';
            app.RecommendFramesButton.Layout.Row = 3;
            app.RecommendFramesButton.Layout.Column = 1;
            app.RecommendFramesButton.Text = 'Recommend Frames';

            % Create AdjustAlignmentButton
            app.AdjustAlignmentButton = uibutton(app.GridLayout29, 'push');
            app.AdjustAlignmentButton.ButtonPushedFcn = createCallbackFcn(app, @AdjustAlignmentButtonPushed, true);
            app.AdjustAlignmentButton.Enable = 'off';
            app.AdjustAlignmentButton.Layout.Row = 2;
            app.AdjustAlignmentButton.Layout.Column = 1;
            app.AdjustAlignmentButton.Text = 'Adjust Alignment';

            % Create SaveResultsButton
            app.SaveResultsButton = uibutton(app.GridLayout29, 'push');
            app.SaveResultsButton.Enable = 'off';
            app.SaveResultsButton.Layout.Row = 6;
            app.SaveResultsButton.Layout.Column = 1;
            app.SaveResultsButton.Text = 'Save Results';

            % Create ExtractActivityTracesButton
            app.ExtractActivityTracesButton = uibutton(app.GridLayout29, 'push');
            app.ExtractActivityTracesButton.ButtonPushedFcn = createCallbackFcn(app, @ExtractActivityTracesButtonPushed, true);
            app.ExtractActivityTracesButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ExtractActivityTracesButton.Enable = 'off';
            app.ExtractActivityTracesButton.Layout.Row = 5;
            app.ExtractActivityTracesButton.Layout.Column = 1;
            app.ExtractActivityTracesButton.Text = 'Extract Activity Traces';

            % Create TrackNeuronsButton
            app.TrackNeuronsButton = uibutton(app.GridLayout29, 'push');
            app.TrackNeuronsButton.ButtonPushedFcn = createCallbackFcn(app, @TrackNeuronsButtonPushed, true);
            app.TrackNeuronsButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TrackNeuronsButton.Enable = 'off';
            app.TrackNeuronsButton.Layout.Row = 4;
            app.TrackNeuronsButton.Layout.Column = 1;
            app.TrackNeuronsButton.Text = 'Track Neurons';

            % Create UseMATLABbrowserCheckBox
            app.UseMATLABbrowserCheckBox = uicheckbox(app.GridLayout29);
            app.UseMATLABbrowserCheckBox.ValueChangedFcn = createCallbackFcn(app, @UseMATLABbrowserCheckBoxValueChanged, true);
            app.UseMATLABbrowserCheckBox.Text = 'Use MATLAB browser';
            app.UseMATLABbrowserCheckBox.Layout.Row = 1;
            app.UseMATLABbrowserCheckBox.Layout.Column = 1;

            % Create Panel_16
            app.Panel_16 = uipanel(app.GridLayout12);
            app.Panel_16.BorderType = 'none';
            app.Panel_16.Layout.Row = 1;
            app.Panel_16.Layout.Column = 3;

            % Create GridLayout30
            app.GridLayout30 = uigridlayout(app.Panel_16);
            app.GridLayout30.ColumnWidth = {'1x'};
            app.GridLayout30.RowHeight = {20, '1x'};
            app.GridLayout30.RowSpacing = 3;
            app.GridLayout30.Padding = [0 0 0 0];

            % Create Tree
            app.Tree = uitree(app.GridLayout30, 'checkbox');
            app.Tree.Enable = 'off';
            app.Tree.Layout.Row = 2;
            app.Tree.Layout.Column = 1;

            % Create DataNode
            app.DataNode = uitreenode(app.Tree);
            app.DataNode.Text = 'Data';

            % Create WorldlinesNode
            app.WorldlinesNode = uitreenode(app.Tree);
            app.WorldlinesNode.Text = 'Worldlines';

            % Create AnnotationsNode
            app.AnnotationsNode = uitreenode(app.Tree);
            app.AnnotationsNode.Text = 'Annotations';

            % Create MetadatajsonNode
            app.MetadatajsonNode = uitreenode(app.Tree);
            app.MetadatajsonNode.Text = 'Metadata.json';

            % Create FilesLoadedLabel
            app.FilesLoadedLabel = uilabel(app.GridLayout30);
            app.FilesLoadedLabel.HorizontalAlignment = 'center';
            app.FilesLoadedLabel.FontWeight = 'bold';
            app.FilesLoadedLabel.Enable = 'off';
            app.FilesLoadedLabel.Layout.Row = 1;
            app.FilesLoadedLabel.Layout.Column = 1;
            app.FilesLoadedLabel.Text = 'Files Loaded';

            % Create AdvancedSettingsTab
            app.AdvancedSettingsTab = uitab(app.TabGroup);
            app.AdvancedSettingsTab.AutoResizeChildren = 'off';
            app.AdvancedSettingsTab.Title = 'Advanced Settings';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.AdvancedSettingsTab);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {23, '1x'};
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 10];

            % Create HoveroverlabelsforfurtherdetailsorguidanceLabel
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel = uilabel(app.GridLayout);
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel.HorizontalAlignment = 'center';
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel.FontSize = 14;
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel.FontWeight = 'bold';
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel.Layout.Row = 1;
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel.Layout.Column = 1;
            app.HoveroverlabelsforfurtherdetailsorguidanceLabel.Text = 'Hover over labels for further details or guidance.';

            % Create Panel_17
            app.Panel_17 = uipanel(app.GridLayout);
            app.Panel_17.BorderType = 'none';
            app.Panel_17.Layout.Row = 2;
            app.Panel_17.Layout.Column = 1;

            % Create GridLayout36
            app.GridLayout36 = uigridlayout(app.Panel_17);
            app.GridLayout36.ColumnWidth = {'1x'};
            app.GridLayout36.RowHeight = {23, '1x'};

            % Create EnableManualZephirSettingsCheckBox
            app.EnableManualZephirSettingsCheckBox = uicheckbox(app.GridLayout36);
            app.EnableManualZephirSettingsCheckBox.ValueChangedFcn = createCallbackFcn(app, @EnableManualZephirSettingsCheckBoxValueChanged, true);
            app.EnableManualZephirSettingsCheckBox.Enable = 'off';
            app.EnableManualZephirSettingsCheckBox.Text = ' Enable Manual Zephir Settings';
            app.EnableManualZephirSettingsCheckBox.Layout.Row = 1;
            app.EnableManualZephirSettingsCheckBox.Layout.Column = 1;

            % Create AdvSetTab
            app.AdvSetTab = uitabgroup(app.GridLayout36);
            app.AdvSetTab.Layout.Row = 2;
            app.AdvSetTab.Layout.Column = 1;

            % Create GeneralTab
            app.GeneralTab = uitab(app.AdvSetTab);
            app.GeneralTab.Title = 'General';

            % Create GridLayout31
            app.GridLayout31 = uigridlayout(app.GeneralTab);
            app.GridLayout31.ColumnWidth = {'0.15x', '1x', '0.2x'};
            app.GridLayout31.RowHeight = {23, 23, 23, 23, 23};

            % Create UseGPULabel
            app.UseGPULabel = uilabel(app.GridLayout31);
            app.UseGPULabel.FontWeight = 'bold';
            app.UseGPULabel.Layout.Row = 1;
            app.UseGPULabel.Layout.Column = 1;
            app.UseGPULabel.Text = 'Use GPU';

            % Create SetsdevicetoGPUandenablesCUDAuseDropDownLabel
            app.SetsdevicetoGPUandenablesCUDAuseDropDownLabel = uilabel(app.GridLayout31);
            app.SetsdevicetoGPUandenablesCUDAuseDropDownLabel.Layout.Row = 1;
            app.SetsdevicetoGPUandenablesCUDAuseDropDownLabel.Layout.Column = 2;
            app.SetsdevicetoGPUandenablesCUDAuseDropDownLabel.Text = 'Sets device to GPU and enables CUDA use.';

            % Create use_gpu
            app.use_gpu = uidropdown(app.GridLayout31);
            app.use_gpu.Items = {'True', 'False'};
            app.use_gpu.Editable = 'on';
            app.use_gpu.Enable = 'off';
            app.use_gpu.BackgroundColor = [1 1 1];
            app.use_gpu.Layout.Row = 1;
            app.use_gpu.Layout.Column = 3;
            app.use_gpu.Value = 'True';

            % Create n_epochLabel
            app.n_epochLabel = uilabel(app.GridLayout31);
            app.n_epochLabel.FontWeight = 'bold';
            app.n_epochLabel.Layout.Row = 2;
            app.n_epochLabel.Layout.Column = 1;
            app.n_epochLabel.Text = 'n_epoch';

            % Create NumberofiterationsforimageregistrationLREditFieldLabel
            app.NumberofiterationsforimageregistrationLREditFieldLabel = uilabel(app.GridLayout31);
            app.NumberofiterationsforimageregistrationLREditFieldLabel.Layout.Row = 2;
            app.NumberofiterationsforimageregistrationLREditFieldLabel.Layout.Column = 2;
            app.NumberofiterationsforimageregistrationLREditFieldLabel.Text = 'Number of iterations for image registration, LR.';

            % Create n_epoch_dLabel
            app.n_epoch_dLabel = uilabel(app.GridLayout31);
            app.n_epoch_dLabel.FontWeight = 'bold';
            app.n_epoch_dLabel.Layout.Row = 3;
            app.n_epoch_dLabel.Layout.Column = 1;
            app.n_epoch_dLabel.Text = 'n_epoch_d';

            % Create n_epoch
            app.n_epoch = uieditfield(app.GridLayout31, 'numeric');
            app.n_epoch.ValueDisplayFormat = '%.0f';
            app.n_epoch.HorizontalAlignment = 'center';
            app.n_epoch.Enable = 'off';
            app.n_epoch.Layout.Row = 2;
            app.n_epoch.Layout.Column = 3;
            app.n_epoch.Value = 40;

            % Create EditField2_2Label
            app.EditField2_2Label = uilabel(app.GridLayout31);
            app.EditField2_2Label.Layout.Row = 3;
            app.EditField2_2Label.Layout.Column = 2;
            app.EditField2_2Label.Text = 'Number of iterations for feature detection regularization, LD.';

            % Create n_epoch_d
            app.n_epoch_d = uieditfield(app.GridLayout31, 'numeric');
            app.n_epoch_d.ValueDisplayFormat = '%.0f';
            app.n_epoch_d.HorizontalAlignment = 'center';
            app.n_epoch_d.Enable = 'off';
            app.n_epoch_d.Layout.Row = 3;
            app.n_epoch_d.Layout.Column = 3;
            app.n_epoch_d.Value = 10;

            % Create n_chunksLabel
            app.n_chunksLabel = uilabel(app.GridLayout31);
            app.n_chunksLabel.FontWeight = 'bold';
            app.n_chunksLabel.Layout.Row = 4;
            app.n_chunksLabel.Layout.Column = 1;
            app.n_chunksLabel.Text = 'n_chunks';

            % Create NumberofstepstodividetheforwardpassintoEditFieldLabel
            app.NumberofstepstodividetheforwardpassintoEditFieldLabel = uilabel(app.GridLayout31);
            app.NumberofstepstodividetheforwardpassintoEditFieldLabel.Layout.Row = 4;
            app.NumberofstepstodividetheforwardpassintoEditFieldLabel.Layout.Column = 2;
            app.NumberofstepstodividetheforwardpassintoEditFieldLabel.Text = 'Number of steps to divide the forward pass into.';

            % Create n_chunks
            app.n_chunks = uieditfield(app.GridLayout31, 'numeric');
            app.n_chunks.ValueDisplayFormat = '%.0f';
            app.n_chunks.HorizontalAlignment = 'center';
            app.n_chunks.Enable = 'off';
            app.n_chunks.Layout.Row = 4;
            app.n_chunks.Layout.Column = 3;
            app.n_chunks.Value = 10;

            % Create sort_modeLabel
            app.sort_modeLabel = uilabel(app.GridLayout31);
            app.sort_modeLabel.FontWeight = 'bold';
            app.sort_modeLabel.Layout.Row = 5;
            app.sort_modeLabel.Layout.Column = 1;
            app.sort_modeLabel.Text = 'sort_mode';

            % Create DropDown_2Label
            app.DropDown_2Label = uilabel(app.GridLayout31);
            app.DropDown_2Label.Layout.Row = 5;
            app.DropDown_2Label.Layout.Column = 2;
            app.DropDown_2Label.Text = 'Method for sorting frames and determining parent-child branches.';

            % Create sort_mode
            app.sort_mode = uidropdown(app.GridLayout31);
            app.sort_mode.Items = {'similarity', 'linear', 'depth'};
            app.sort_mode.Enable = 'off';
            app.sort_mode.Tooltip = {'''similarity'' minimizes distance between parent and child.'; '''linear'' branches out from reference frames linearly forwards and backwards, with every parent-child one frame apart, until it reaches the first frame, last frame, or another branch. Simplest and fastest.'; '''depth'' uses shortest-path grid search, then sorts frames based on depth in the resulting parent-child tree. This can scale up to O(n4) in computation with number of frames.'};
            app.sort_mode.Layout.Row = 5;
            app.sort_mode.Layout.Column = 3;
            app.sort_mode.Value = 'similarity';

            % Create RegularizationLossCoefficientsTab
            app.RegularizationLossCoefficientsTab = uitab(app.AdvSetTab);
            app.RegularizationLossCoefficientsTab.Title = 'Regularization & Loss Coefficients';

            % Create GridLayout35
            app.GridLayout35 = uigridlayout(app.RegularizationLossCoefficientsTab);
            app.GridLayout35.ColumnWidth = {'0.1x', '1x', '0.15x'};
            app.GridLayout35.RowHeight = {23, 23, 23, 23, 23};

            % Create dLabel
            app.dLabel = uilabel(app.GridLayout35);
            app.dLabel.FontWeight = 'bold';
            app.dLabel.Tooltip = {'This regularization is turned on at the last n_epoch_d of each optimization loop with everything else turned off. Set to -1 to disable. default: -1.0'};
            app.dLabel.Layout.Row = 1;
            app.dLabel.Layout.Column = 1;
            app.dLabel.Text = 'λd';

            % Create EditField3Label
            app.EditField3Label = uilabel(app.GridLayout35);
            app.EditField3Label.WordWrap = 'on';
            app.EditField3Label.Tooltip = {'This regularization is turned on at the last n_epoch_d of each optimization loop with everything else turned off. Set to -1 to disable. default: -1.0'};
            app.EditField3Label.Layout.Row = 1;
            app.EditField3Label.Layout.Column = 2;
            app.EditField3Label.Text = 'Coefficient for feature detection loss, λD. ';

            % Create l_d
            app.l_d = uieditfield(app.GridLayout35, 'numeric');
            app.l_d.ValueDisplayFormat = '%.2f';
            app.l_d.HorizontalAlignment = 'center';
            app.l_d.Enable = 'off';
            app.l_d.Layout.Row = 1;
            app.l_d.Layout.Column = 3;
            app.l_d.Value = -1;

            % Create tLabel
            app.tLabel = uilabel(app.GridLayout35);
            app.tLabel.FontWeight = 'bold';
            app.tLabel.Tooltip = {'TIP: 0.1 generally matches order of magnitude of registration loss. Increase up to 1.0 for non-deforming datasets. Set to 0 or -1 if regularization is unnecessary (this will skip the regularization step entirely and can dramatically speed up performance). Alternatively, setting n_frame to 1 will also disable this.'};
            app.tLabel.Layout.Row = 2;
            app.tLabel.Layout.Column = 1;
            app.tLabel.Text = 'λt';

            % Create EditField2Label
            app.EditField2Label = uilabel(app.GridLayout35);
            app.EditField2Label.WordWrap = 'on';
            app.EditField2Label.Tooltip = {'TIP: 0.1 generally matches order of magnitude of registration loss. Increase up to 1.0 for non-deforming datasets. Set to 0 or -1 if regularization is unnecessary (this will skip the regularization step entirely and can dramatically speed up performance). Alternatively, setting n_frame to 1 will also disable this.'};
            app.EditField2Label.Layout.Row = 2;
            app.EditField2Label.Layout.Column = 2;
            app.EditField2Label.Text = 'Coefficient for temporal smoothing loss, λT, enforcing a 0th-order linear fit for intensity over n_frame frames.';

            % Create l_t
            app.l_t = uieditfield(app.GridLayout35, 'numeric');
            app.l_t.ValueDisplayFormat = '%.2f';
            app.l_t.HorizontalAlignment = 'center';
            app.l_t.Enable = 'off';
            app.l_t.Layout.Row = 2;
            app.l_t.Layout.Column = 3;
            app.l_t.Value = -1;

            % Create NLabel
            app.NLabel = uilabel(app.GridLayout35);
            app.NLabel.FontWeight = 'bold';
            app.NLabel.Tooltip = {'Spring constants are calculated by multiplying the covariance of connected pairs by this number and passing the result through a ReLU layer. The resulting loss is also rescaled to this value, meaning it cannot exceed this value. If a covariance value is unavailable, the spring constant is set equal to this number. default: 1.0'; ''; 'TIP: Increase up to 10.0 for non-deforming datasets. Decrease down to 0.01 or turn off for large motion/deformation. Optimal value tends to be between 1.0-4.0. Set to 0 or -1 if regularization is unnecessary (this can speed up performance).'};
            app.NLabel.Layout.Row = 3;
            app.NLabel.Layout.Column = 1;
            app.NLabel.Text = 'λN';

            % Create EditField4Label
            app.EditField4Label = uilabel(app.GridLayout35);
            app.EditField4Label.WordWrap = 'on';
            app.EditField4Label.Tooltip = {'Spring constants are calculated by multiplying the covariance of connected pairs by this number and passing the result through a ReLU layer. The resulting loss is also rescaled to this value, meaning it cannot exceed this value. If a covariance value is unavailable, the spring constant is set equal to this number. default: 1.0'; ''; 'TIP: Increase up to 10.0 for non-deforming datasets. Decrease down to 0.01 or turn off for large motion/deformation. Optimal value tends to be between 1.0-4.0. Set to 0 or -1 if regularization is unnecessary (this can speed up performance).'};
            app.EditField4Label.Layout.Row = 3;
            app.EditField4Label.Layout.Column = 2;
            app.EditField4Label.Text = 'Coefficient for spring constant for intra-keypoint spatial regularization, λN.';

            % Create l_n
            app.l_n = uieditfield(app.GridLayout35, 'numeric');
            app.l_n.ValueDisplayFormat = '%.2f';
            app.l_n.HorizontalAlignment = 'center';
            app.l_n.Enable = 'off';
            app.l_n.Tooltip = {'Spring constants are calculated by multiplying the covariance of connected pairs by this number and passing the result through a ReLU layer. The resulting loss is also rescaled to this value, meaning it cannot exceed this value. If a covariance value is unavailable, the spring constant is set equal to this number. default: 1.0'; ''; 'TIP: Increase up to 10.0 for non-deforming datasets. Decrease down to 0.01 or turn off for large motion/deformation. Optimal value tends to be between 1.0-4.0. Set to 0 or -1 if regularization is unnecessary (this can speed up performance).'};
            app.l_n.Layout.Row = 3;
            app.l_n.Layout.Column = 3;
            app.l_n.Value = 5;

            % Create NmodeLabel
            app.NmodeLabel = uilabel(app.GridLayout35);
            app.NmodeLabel.FontWeight = 'bold';
            app.NmodeLabel.Tooltip = {'''disp'': use inter-keypoint displacements'; '''norm'': use inter-keypoint distances (rotation is not penalized)'; '''ljp'': use a Lenard-Jones potential on inter-keypoint distances (collapsing onto the same position is highly penalized)'; 'default: ''disp'''};
            app.NmodeLabel.Layout.Row = 4;
            app.NmodeLabel.Layout.Column = 1;
            app.NmodeLabel.Text = 'λN mode';

            % Create MethodtouseforcalculatingNLabel
            app.MethodtouseforcalculatingNLabel = uilabel(app.GridLayout35);
            app.MethodtouseforcalculatingNLabel.Layout.Row = 4;
            app.MethodtouseforcalculatingNLabel.Layout.Column = 2;
            app.MethodtouseforcalculatingNLabel.Text = 'Method to use for calculating LN.';

            % Create l_n_mode
            app.l_n_mode = uidropdown(app.GridLayout35);
            app.l_n_mode.Items = {'disp', 'norm', 'ljp'};
            app.l_n_mode.Editable = 'on';
            app.l_n_mode.Enable = 'off';
            app.l_n_mode.BackgroundColor = [1 1 1];
            app.l_n_mode.Layout.Row = 4;
            app.l_n_mode.Layout.Column = 3;
            app.l_n_mode.Value = 'disp';

            % Create nn_maxLabel
            app.nn_maxLabel = uilabel(app.GridLayout35);
            app.nn_maxLabel.FontWeight = 'bold';
            app.nn_maxLabel.Tooltip = {'default: 5'};
            app.nn_maxLabel.Layout.Row = 5;
            app.nn_maxLabel.Layout.Column = 1;
            app.nn_maxLabel.Text = 'nn_max';

            % Create EditFieldLabel_2
            app.EditFieldLabel_2 = uilabel(app.GridLayout35);
            app.EditFieldLabel_2.WordWrap = 'on';
            app.EditFieldLabel_2.Tooltip = {'default: 5'};
            app.EditFieldLabel_2.Layout.Row = 5;
            app.EditFieldLabel_2.Layout.Column = 2;
            app.EditFieldLabel_2.Text = 'Maximum number of neighboring keypoints to be connected by springs for calculating λN.';

            % Create nn_max
            app.nn_max = uieditfield(app.GridLayout35, 'numeric');
            app.nn_max.ValueDisplayFormat = '%.2f';
            app.nn_max.HorizontalAlignment = 'center';
            app.nn_max.Enable = 'off';
            app.nn_max.Tooltip = {'default: 5'};
            app.nn_max.Layout.Row = 5;
            app.nn_max.Layout.Column = 3;

            % Create GradientLearningRateTab
            app.GradientLearningRateTab = uitab(app.AdvSetTab);
            app.GradientLearningRateTab.Title = 'Gradient & Learning Rate';

            % Create GridLayout32
            app.GridLayout32 = uigridlayout(app.GradientLearningRateTab);
            app.GridLayout32.ColumnWidth = {'0.15x', '1x', '0.15x'};
            app.GridLayout32.RowHeight = {23, 23, 23, 23, 23};

            % Create lr_ceilingLabel
            app.lr_ceilingLabel = uilabel(app.GridLayout32);
            app.lr_ceilingLabel.FontWeight = 'bold';
            app.lr_ceilingLabel.Layout.Row = 4;
            app.lr_ceilingLabel.Layout.Column = 1;
            app.lr_ceilingLabel.Text = 'lr_ceiling';

            % Create EditFieldLabel_3
            app.EditFieldLabel_3 = uilabel(app.GridLayout32);
            app.EditFieldLabel_3.Layout.Row = 4;
            app.EditFieldLabel_3.Layout.Column = 2;
            app.EditFieldLabel_3.Text = 'Maximum value for initial learning rate. Note that learning rate decays by a factor of 0.5 every 10 epochs.';

            % Create lr_ceiling
            app.lr_ceiling = uieditfield(app.GridLayout32, 'numeric');
            app.lr_ceiling.HorizontalAlignment = 'center';
            app.lr_ceiling.Enable = 'off';
            app.lr_ceiling.Layout.Row = 4;
            app.lr_ceiling.Layout.Column = 3;
            app.lr_ceiling.Value = 0.2;

            % Create LRFloorLabel
            app.LRFloorLabel = uilabel(app.GridLayout32);
            app.LRFloorLabel.FontWeight = 'bold';
            app.LRFloorLabel.Layout.Row = 3;
            app.LRFloorLabel.Layout.Column = 1;
            app.LRFloorLabel.Text = 'LR Floor';

            % Create Minimumvalueforinitiallearningratedefault002EditFieldLabel
            app.Minimumvalueforinitiallearningratedefault002EditFieldLabel = uilabel(app.GridLayout32);
            app.Minimumvalueforinitiallearningratedefault002EditFieldLabel.Layout.Row = 3;
            app.Minimumvalueforinitiallearningratedefault002EditFieldLabel.Layout.Column = 2;
            app.Minimumvalueforinitiallearningratedefault002EditFieldLabel.Text = 'Minimum value for initial learning rate. default: 0.02';

            % Create lr_floor
            app.lr_floor = uieditfield(app.GridLayout32, 'numeric');
            app.lr_floor.ValueDisplayFormat = '%.2f';
            app.lr_floor.HorizontalAlignment = 'center';
            app.lr_floor.Enable = 'off';
            app.lr_floor.Layout.Row = 3;
            app.lr_floor.Layout.Column = 3;
            app.lr_floor.Value = 0.02;

            % Create LRCoeffLabel
            app.LRCoeffLabel = uilabel(app.GridLayout32);
            app.LRCoeffLabel.FontWeight = 'bold';
            app.LRCoeffLabel.Tooltip = {'TIP: If a dynamic learning rate is not necessary for your dataset, set to 0 or lower to disable. This will also skip calculation of distances between frames which can be very computationally costly for long datasets.'};
            app.LRCoeffLabel.Layout.Row = 2;
            app.LRCoeffLabel.Layout.Column = 1;
            app.LRCoeffLabel.Text = 'LR Coeff';

            % Create EditField6Label
            app.EditField6Label = uilabel(app.GridLayout32);
            app.EditField6Label.WordWrap = 'on';
            app.EditField6Label.Layout.Row = 2;
            app.EditField6Label.Layout.Column = 2;
            app.EditField6Label.Text = 'Coefficient for initial learning rate, multiplied by the distance between current frame and its parent.';

            % Create lr_coeff
            app.lr_coeff = uieditfield(app.GridLayout32, 'numeric');
            app.lr_coeff.ValueDisplayFormat = '%.2f';
            app.lr_coeff.HorizontalAlignment = 'center';
            app.lr_coeff.Enable = 'off';
            app.lr_coeff.Tooltip = {'TIP: If a dynamic learning rate is not necessary for your dataset, set to 0 or lower to disable. This will also skip calculation of distances between frames which can be very computationally costly for long datasets.'};
            app.lr_coeff.Layout.Row = 2;
            app.lr_coeff.Layout.Column = 3;
            app.lr_coeff.Value = 2;

            % Create clip_gradLabel
            app.clip_gradLabel = uilabel(app.GridLayout32);
            app.clip_gradLabel.FontWeight = 'bold';
            app.clip_gradLabel.Tooltip = {'TIP: If motion is small, set lower to ~0.1. This is a more aggressive tactic than lr_ceiling.'};
            app.clip_gradLabel.Layout.Row = 1;
            app.clip_gradLabel.Layout.Column = 1;
            app.clip_gradLabel.Text = 'clip_grad';

            % Create EditFieldLabel
            app.EditFieldLabel = uilabel(app.GridLayout32);
            app.EditFieldLabel.WordWrap = 'on';
            app.EditFieldLabel.Tooltip = {'TIP: If motion is small, set lower to ~0.1. This is a more aggressive tactic than lr_ceiling.'};
            app.EditFieldLabel.Layout.Row = 1;
            app.EditFieldLabel.Layout.Column = 2;
            app.EditFieldLabel.Text = 'Maximum value for gradients for gradient descent. Use -1 to uncap. default: 1.0';

            % Create clip_grad
            app.clip_grad = uieditfield(app.GridLayout32, 'numeric');
            app.clip_grad.ValueDisplayFormat = '%.2f';
            app.clip_grad.HorizontalAlignment = 'center';
            app.clip_grad.Enable = 'off';
            app.clip_grad.Layout.Row = 1;
            app.clip_grad.Layout.Column = 3;
            app.clip_grad.Value = -1;

            % Create Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel
            app.Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel = uilabel(app.GridLayout32);
            app.Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel.Tooltip = {'Since the internal coordinate system is rescaled from -1 to 1 in all directions, gradients in the z-axis may be too small when there is a large disparity between the xy- and z-shapes of the dataset, and thus fail to track motion in the z-axis. Increasing this will compensate for the disparity. Note that gradients will still be clipped to (clip_grad * z_compensator) if clip_grad is enabled. Set to 0 or -1 to disable. default: -1'};
            app.Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel.Layout.Row = 5;
            app.Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel.Layout.Column = 2;
            app.Multiplygradientsinthezaxisby1z_compensatorEditFieldLabel.Text = 'Multiply gradients in the z-axis by (1 + z_compensator).';

            % Create z_comp
            app.z_comp = uieditfield(app.GridLayout32, 'numeric');
            app.z_comp.ValueDisplayFormat = '%.2f';
            app.z_comp.HorizontalAlignment = 'center';
            app.z_comp.Enable = 'off';
            app.z_comp.Layout.Row = 5;
            app.z_comp.Layout.Column = 3;
            app.z_comp.Value = -1;

            % Create ZCompLabel
            app.ZCompLabel = uilabel(app.GridLayout32);
            app.ZCompLabel.FontWeight = 'bold';
            app.ZCompLabel.Tooltip = {'Since the internal coordinate system is rescaled from -1 to 1 in all directions, gradients in the z-axis may be too small when there is a large disparity between the xy- and z-shapes of the dataset, and thus fail to track motion in the z-axis. Increasing this will compensate for the disparity. Note that gradients will still be clipped to (clip_grad * z_compensator) if clip_grad is enabled. Set to 0 or -1 to disable. default: -1'};
            app.ZCompLabel.Layout.Row = 5;
            app.ZCompLabel.Layout.Column = 1;
            app.ZCompLabel.Text = 'Z Comp.';

            % Create ImageMotionTab
            app.ImageMotionTab = uitab(app.AdvSetTab);
            app.ImageMotionTab.Title = 'Image & Motion';

            % Create GridLayout34
            app.GridLayout34 = uigridlayout(app.ImageMotionTab);
            app.GridLayout34.ColumnWidth = {'0.16x', '1x', '0.15x'};
            app.GridLayout34.RowHeight = {23, 23, 23, 23};

            % Create foveasigmaLabel
            app.foveasigmaLabel = uilabel(app.GridLayout34);
            app.foveasigmaLabel.FontWeight = 'bold';
            app.foveasigmaLabel.Layout.Row = 2;
            app.foveasigmaLabel.Layout.Column = 1;
            app.foveasigmaLabel.Text = 'fovea sigma';

            % Create EditFieldLabel_4
            app.EditFieldLabel_4 = uilabel(app.GridLayout34);
            app.EditFieldLabel_4.Layout.Row = 2;
            app.EditFieldLabel_4.Layout.Column = 2;
            app.EditFieldLabel_4.Text = 'Sigma for Gaussian mask over foveated regions of the descriptors.';

            % Create fovea_sigma
            app.fovea_sigma = uieditfield(app.GridLayout34, 'numeric');
            app.fovea_sigma.HorizontalAlignment = 'center';
            app.fovea_sigma.Enable = 'off';
            app.fovea_sigma.Tooltip = {'Decreasing this can help prioritize keeping a keypoint at the center. Increase to a large number or set at -1 to disable.'};
            app.fovea_sigma.Layout.Row = 2;
            app.fovea_sigma.Layout.Column = 3;
            app.fovea_sigma.Value = 2.5;

            % Create grid_shapeLabel
            app.grid_shapeLabel = uilabel(app.GridLayout34);
            app.grid_shapeLabel.FontWeight = 'bold';
            app.grid_shapeLabel.Layout.Row = 1;
            app.grid_shapeLabel.Layout.Column = 1;
            app.grid_shapeLabel.Text = 'grid_shape';

            % Create SizeoftheimagedescriptorsinthexyplaneinpixelsEditFieldLabel
            app.SizeoftheimagedescriptorsinthexyplaneinpixelsEditFieldLabel = uilabel(app.GridLayout34);
            app.SizeoftheimagedescriptorsinthexyplaneinpixelsEditFieldLabel.Layout.Row = 1;
            app.SizeoftheimagedescriptorsinthexyplaneinpixelsEditFieldLabel.Layout.Column = 2;
            app.SizeoftheimagedescriptorsinthexyplaneinpixelsEditFieldLabel.Text = 'Size of the image descriptors in the xy-plane in pixels.';

            % Create grid_shape
            app.grid_shape = uieditfield(app.GridLayout34, 'numeric');
            app.grid_shape.HorizontalAlignment = 'center';
            app.grid_shape.Enable = 'off';
            app.grid_shape.Layout.Row = 1;
            app.grid_shape.Layout.Column = 3;
            app.grid_shape.Value = 25;

            % Create motion_predictLabel
            app.motion_predictLabel = uilabel(app.GridLayout34);
            app.motion_predictLabel.FontWeight = 'bold';
            app.motion_predictLabel.Layout.Row = 3;
            app.motion_predictLabel.Layout.Column = 1;
            app.motion_predictLabel.Text = 'motion_predict';

            % Create DropDownLabel
            app.DropDownLabel = uilabel(app.GridLayout34);
            app.DropDownLabel.Layout.Row = 3;
            app.DropDownLabel.Layout.Column = 2;
            app.DropDownLabel.Text = 'Enable parent-child flow field to predict low-freq. motion & initialize new keypoints pos. for current frame.';

            % Create motion_predict
            app.motion_predict = uidropdown(app.GridLayout34);
            app.motion_predict.Items = {'True', 'False'};
            app.motion_predict.Enable = 'off';
            app.motion_predict.Layout.Row = 3;
            app.motion_predict.Layout.Column = 3;
            app.motion_predict.Value = 'False';

            % Create dimmer_ratioLabel
            app.dimmer_ratioLabel = uilabel(app.GridLayout34);
            app.dimmer_ratioLabel.FontWeight = 'bold';
            app.dimmer_ratioLabel.Layout.Row = 4;
            app.dimmer_ratioLabel.Layout.Column = 1;
            app.dimmer_ratioLabel.Text = 'dimmer_ratio';

            % Create CoefficientfordimmingnonfoveatedregionsEditFieldLabel
            app.CoefficientfordimmingnonfoveatedregionsEditFieldLabel = uilabel(app.GridLayout34);
            app.CoefficientfordimmingnonfoveatedregionsEditFieldLabel.Layout.Row = 4;
            app.CoefficientfordimmingnonfoveatedregionsEditFieldLabel.Layout.Column = 2;
            app.CoefficientfordimmingnonfoveatedregionsEditFieldLabel.Text = 'Coefficient for dimming non-foveated regions.';

            % Create dimmer_ratio
            app.dimmer_ratio = uieditfield(app.GridLayout34, 'numeric');
            app.dimmer_ratio.HorizontalAlignment = 'center';
            app.dimmer_ratio.Enable = 'off';
            app.dimmer_ratio.Layout.Row = 4;
            app.dimmer_ratio.Layout.Column = 3;

            % Create MiscellaneousTab
            app.MiscellaneousTab = uitab(app.AdvSetTab);
            app.MiscellaneousTab.Title = 'Miscellaneous';

            % Create GridLayout37
            app.GridLayout37 = uigridlayout(app.MiscellaneousTab);
            app.GridLayout37.ColumnWidth = {'0.15x', '1x', '0.15x'};
            app.GridLayout37.RowHeight = {'1x', '1x', '1x', '1x'};

            % Create CreditTab
            app.CreditTab = uitab(app.TabGroup);
            app.CreditTab.AutoResizeChildren = 'off';
            app.CreditTab.Title = 'Credit';

            % Create GridLayout14
            app.GridLayout14 = uigridlayout(app.CreditTab);
            app.GridLayout14.ColumnWidth = {50, '1x', '1x', '1x', 50};
            app.GridLayout14.RowHeight = {105, 51, 10, 22, '1x'};
            app.GridLayout14.ColumnSpacing = 5.16666666666667;
            app.GridLayout14.RowSpacing = 2.66666666666667;

            % Create Label
            app.Label = uilabel(app.GridLayout14);
            app.Label.WordWrap = 'on';
            app.Label.FontSize = 14;
            app.Label.Layout.Row = 1;
            app.Label.Layout.Column = [3 4];
            app.Label.Text = 'Tracing relies on a modified version of Zephir, a multiple object tracking algorithm based on image registration and developed by James Yu et al. ZephIR tracks keypoints in a 2D or 3D movie by registering image descriptors sampled around each keypoint. ';

            % Create LaboratoryPageButton
            app.LaboratoryPageButton = uibutton(app.GridLayout14, 'push');
            app.LaboratoryPageButton.ButtonPushedFcn = createCallbackFcn(app, @LaboratoryPageButtonPushed, true);
            app.LaboratoryPageButton.FontSize = 14;
            app.LaboratoryPageButton.FontWeight = 'bold';
            app.LaboratoryPageButton.Layout.Row = 2;
            app.LaboratoryPageButton.Layout.Column = 4;
            app.LaboratoryPageButton.Text = 'Laboratory Page';

            % Create ViewPreprintButton
            app.ViewPreprintButton = uibutton(app.GridLayout14, 'push');
            app.ViewPreprintButton.ButtonPushedFcn = createCallbackFcn(app, @ViewPreprintButtonPushed, true);
            app.ViewPreprintButton.FontSize = 14;
            app.ViewPreprintButton.FontWeight = 'bold';
            app.ViewPreprintButton.Layout.Row = 2;
            app.ViewPreprintButton.Layout.Column = 2;
            app.ViewPreprintButton.Text = 'View Preprint';

            % Create GithubRepositoryButton
            app.GithubRepositoryButton = uibutton(app.GridLayout14, 'push');
            app.GithubRepositoryButton.ButtonPushedFcn = createCallbackFcn(app, @GithubRepositoryButtonPushed, true);
            app.GithubRepositoryButton.FontSize = 14;
            app.GithubRepositoryButton.FontWeight = 'bold';
            app.GithubRepositoryButton.Layout.Row = 2;
            app.GithubRepositoryButton.Layout.Column = 3;
            app.GithubRepositoryButton.Text = 'Github Repository';

            % Create Image2
            app.Image2 = uiimage(app.GridLayout14);
            app.Image2.Layout.Row = 1;
            app.Image2.Layout.Column = 2;
            app.Image2.ImageSource = fullfile(pathToMLAPP, 'External_Dependencies', 'zephir', 'zephir-logo.png');

            % Create CitationTextAreaLabel
            app.CitationTextAreaLabel = uilabel(app.GridLayout14);
            app.CitationTextAreaLabel.VerticalAlignment = 'bottom';
            app.CitationTextAreaLabel.FontSize = 14;
            app.CitationTextAreaLabel.FontWeight = 'bold';
            app.CitationTextAreaLabel.Layout.Row = 4;
            app.CitationTextAreaLabel.Layout.Column = 2;
            app.CitationTextAreaLabel.Text = 'Citation';

            % Create CitationTextArea
            app.CitationTextArea = uitextarea(app.GridLayout14);
            app.CitationTextArea.Layout.Row = 5;
            app.CitationTextArea.Layout.Column = [2 4];
            app.CitationTextArea.Value = {'Versatile Multiple Object Tracking in Sparse 2D/3D Videos Via Diffeomorphic Image Registration'; 'James Yu, Amin Nejatbakhsh, Mahdi Torkashvand, Sahana Gangadharan, Maedeh Seyedolmohadesin, Jinmahn Kim, Liam Paninski, Vivek Venkatachalam bioRxiv 2022.07.18.500485; doi: https://doi.org/10.1101/2022.07.18.500485'; 'This article is a preprint and has not been certified by peer review'};

            % Create VolumeViewerPanel
            app.VolumeViewerPanel = uipanel(app.MainTraceGrid);
            app.VolumeViewerPanel.TitlePosition = 'centertop';
            app.VolumeViewerPanel.Title = 'Volume Viewer';
            app.VolumeViewerPanel.Layout.Row = 2;
            app.VolumeViewerPanel.Layout.Column = 1;
            app.VolumeViewerPanel.FontWeight = 'bold';

            % Create VolumeViewerGrid
            app.VolumeViewerGrid = uigridlayout(app.VolumeViewerPanel);
            app.VolumeViewerGrid.ColumnWidth = {'1x', 1};
            app.VolumeViewerGrid.RowHeight = {46, 23, '1x'};
            app.VolumeViewerGrid.Padding = [0 0 0 0];

            % Create Npal_Axes
            app.Npal_Axes = uiaxes(app.VolumeViewerGrid);
            app.Npal_Axes.Toolbar.Visible = 'off';
            app.Npal_Axes.XTickLabel = '';
            app.Npal_Axes.YTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.Npal_Axes.YTickLabel = '';
            app.Npal_Axes.Layout.Row = [2 3];
            app.Npal_Axes.Layout.Column = [1 2];

            % Create VolumeViewerControls
            app.VolumeViewerControls = uipanel(app.VolumeViewerGrid);
            app.VolumeViewerControls.BorderType = 'none';
            app.VolumeViewerControls.Layout.Row = 1;
            app.VolumeViewerControls.Layout.Column = [1 2];

            % Create GridLayout38
            app.GridLayout38 = uigridlayout(app.VolumeViewerControls);
            app.GridLayout38.ColumnWidth = {125, '1x'};
            app.GridLayout38.RowHeight = {'1x'};
            app.GridLayout38.RowSpacing = 0;
            app.GridLayout38.Padding = [10 0 10 10];

            % Create Panel_20
            app.Panel_20 = uipanel(app.GridLayout38);
            app.Panel_20.Layout.Row = 1;
            app.Panel_20.Layout.Column = 1;

            % Create GridLayout40
            app.GridLayout40 = uigridlayout(app.Panel_20);
            app.GridLayout40.ColumnWidth = {108};
            app.GridLayout40.RowHeight = {'1x'};
            app.GridLayout40.Padding = [10 3 5 3];

            % Create DisplayNeuronsCheckBox
            app.DisplayNeuronsCheckBox = uicheckbox(app.GridLayout40);
            app.DisplayNeuronsCheckBox.ValueChangedFcn = createCallbackFcn(app, @DisplayNeuronsCheckBoxValueChanged, true);
            app.DisplayNeuronsCheckBox.Text = 'Display Neurons';
            app.DisplayNeuronsCheckBox.Layout.Row = 1;
            app.DisplayNeuronsCheckBox.Layout.Column = 1;

            % Create Panel_21
            app.Panel_21 = uipanel(app.GridLayout38);
            app.Panel_21.Layout.Row = 1;
            app.Panel_21.Layout.Column = 2;

            % Create GridLayout41
            app.GridLayout41 = uigridlayout(app.Panel_21);
            app.GridLayout41.ColumnWidth = {95, '1x', 95};
            app.GridLayout41.RowHeight = {'1x'};

            % Create NeuroPALImageLabel
            app.NeuroPALImageLabel = uilabel(app.GridLayout41);
            app.NeuroPALImageLabel.HorizontalAlignment = 'center';
            app.NeuroPALImageLabel.Layout.Row = 1;
            app.NeuroPALImageLabel.Layout.Column = 1;
            app.NeuroPALImageLabel.Text = 'NeuroPAL Image';

            % Create AlphaSlider
            app.AlphaSlider = uislider(app.GridLayout41);
            app.AlphaSlider.MajorTicks = [];
            app.AlphaSlider.MajorTickLabels = {''};
            app.AlphaSlider.ValueChangedFcn = createCallbackFcn(app, @AlphaSliderValueChanged, true);
            app.AlphaSlider.MinorTicks = [];
            app.AlphaSlider.Enable = 'off';
            app.AlphaSlider.Layout.Row = 1;
            app.AlphaSlider.Layout.Column = 2;

            % Create GCaMPVideoLabel
            app.GCaMPVideoLabel = uilabel(app.GridLayout41);
            app.GCaMPVideoLabel.HorizontalAlignment = 'center';
            app.GCaMPVideoLabel.Layout.Row = 1;
            app.GCaMPVideoLabel.Layout.Column = 3;
            app.GCaMPVideoLabel.Text = 'GCaMP Video';

            % Create SizeWarningLabel
            app.SizeWarningLabel = uilabel(app.VolumeViewerGrid);
            app.SizeWarningLabel.HorizontalAlignment = 'center';
            app.SizeWarningLabel.VerticalAlignment = 'bottom';
            app.SizeWarningLabel.FontColor = [1 0 0];
            app.SizeWarningLabel.Visible = 'off';
            app.SizeWarningLabel.Layout.Row = 2;
            app.SizeWarningLabel.Layout.Column = 1;
            app.SizeWarningLabel.Text = 'Warning: NeuroPAL volume and GCaMP video sizes do not match, resized for visualization purposes.';

            % Create ClicktoselectvideofileButton
            app.ClicktoselectvideofileButton = uibutton(app.MainTraceGrid, 'push');
            app.ClicktoselectvideofileButton.ButtonPushedFcn = createCallbackFcn(app, @ClicktoselectvideofileButtonPushed, true);
            app.ClicktoselectvideofileButton.BackgroundColor = [1 1 1];
            app.ClicktoselectvideofileButton.FontSize = 48;
            app.ClicktoselectvideofileButton.FontWeight = 'bold';
            app.ClicktoselectvideofileButton.Layout.Row = [1 2];
            app.ClicktoselectvideofileButton.Layout.Column = 2;
            app.ClicktoselectvideofileButton.Text = 'Click to select video file.';

            % Create AdjustNeuronMarkerAlignmentPanel
            app.AdjustNeuronMarkerAlignmentPanel = uipanel(app.NeuroPAL_IDTraceWindowUIFigure);
            app.AdjustNeuronMarkerAlignmentPanel.Title = 'Adjust Neuron Marker Alignment';
            app.AdjustNeuronMarkerAlignmentPanel.Visible = 'off';
            app.AdjustNeuronMarkerAlignmentPanel.FontWeight = 'bold';
            app.AdjustNeuronMarkerAlignmentPanel.Position = [-820 703 795 375];

            % Create NeuronMarkerGrid
            app.NeuronMarkerGrid = uigridlayout(app.AdjustNeuronMarkerAlignmentPanel);
            app.NeuronMarkerGrid.ColumnWidth = {'1x', '1x', '1x'};
            app.NeuronMarkerGrid.RowHeight = {'1x', '1x', '1x', '1x', '1x'};

            % Create TransformNeuronMarkersPanel
            app.TransformNeuronMarkersPanel = uipanel(app.NeuronMarkerGrid);
            app.TransformNeuronMarkersPanel.TitlePosition = 'centertop';
            app.TransformNeuronMarkersPanel.Title = 'Transform Neuron Markers';
            app.TransformNeuronMarkersPanel.Layout.Row = [1 2];
            app.TransformNeuronMarkersPanel.Layout.Column = 3;
            app.TransformNeuronMarkersPanel.FontWeight = 'bold';

            % Create GridLayout17
            app.GridLayout17 = uigridlayout(app.TransformNeuronMarkersPanel);
            app.GridLayout17.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout17.RowSpacing = 5;

            % Create HeightSpinnerLabel
            app.HeightSpinnerLabel = uilabel(app.GridLayout17);
            app.HeightSpinnerLabel.HorizontalAlignment = 'right';
            app.HeightSpinnerLabel.Layout.Row = 1;
            app.HeightSpinnerLabel.Layout.Column = 1;
            app.HeightSpinnerLabel.Text = 'Height';

            % Create HeightSpinner
            app.HeightSpinner = uispinner(app.GridLayout17);
            app.HeightSpinner.ValueChangedFcn = createCallbackFcn(app, @HeightSpinnerValueChanged, true);
            app.HeightSpinner.HorizontalAlignment = 'center';
            app.HeightSpinner.Layout.Row = 1;
            app.HeightSpinner.Layout.Column = 2;

            % Create WidthSpinnerLabel
            app.WidthSpinnerLabel = uilabel(app.GridLayout17);
            app.WidthSpinnerLabel.HorizontalAlignment = 'right';
            app.WidthSpinnerLabel.Layout.Row = 2;
            app.WidthSpinnerLabel.Layout.Column = 1;
            app.WidthSpinnerLabel.Text = 'Width';

            % Create WidthSpinner
            app.WidthSpinner = uispinner(app.GridLayout17);
            app.WidthSpinner.HorizontalAlignment = 'center';
            app.WidthSpinner.Layout.Row = 2;
            app.WidthSpinner.Layout.Column = 2;

            % Create ScaleEditFieldLabel
            app.ScaleEditFieldLabel = uilabel(app.GridLayout17);
            app.ScaleEditFieldLabel.HorizontalAlignment = 'right';
            app.ScaleEditFieldLabel.Layout.Row = 3;
            app.ScaleEditFieldLabel.Layout.Column = 1;
            app.ScaleEditFieldLabel.Text = 'Scale';

            % Create ScaleEditField
            app.ScaleEditField = uieditfield(app.GridLayout17, 'numeric');
            app.ScaleEditField.ValueChangedFcn = createCallbackFcn(app, @ScaleEditFieldValueChanged, true);
            app.ScaleEditField.Layout.Row = 3;
            app.ScaleEditField.Layout.Column = 2;

            % Create ResetMoveButton
            app.ResetMoveButton = uibutton(app.NeuronMarkerGrid, 'push');
            app.ResetMoveButton.ButtonPushedFcn = createCallbackFcn(app, @ResetMoveButtonPushed, true);
            app.ResetMoveButton.Layout.Row = 3;
            app.ResetMoveButton.Layout.Column = 3;
            app.ResetMoveButton.Text = 'Reset Move';

            % Create SaveResultButton
            app.SaveResultButton = uibutton(app.NeuronMarkerGrid, 'push');
            app.SaveResultButton.ButtonPushedFcn = createCallbackFcn(app, @SaveResultButtonPushed, true);
            app.SaveResultButton.Layout.Row = 5;
            app.SaveResultButton.Layout.Column = 3;
            app.SaveResultButton.Text = 'Save Result';

            % Create ResetTransformButton
            app.ResetTransformButton = uibutton(app.NeuronMarkerGrid, 'push');
            app.ResetTransformButton.ButtonPushedFcn = createCallbackFcn(app, @ResetTransformButtonPushed, true);
            app.ResetTransformButton.Enable = 'off';
            app.ResetTransformButton.Layout.Row = 4;
            app.ResetTransformButton.Layout.Column = 3;
            app.ResetTransformButton.Text = 'Reset Transform';

            % Create MoveNeuronMarkersPanel
            app.MoveNeuronMarkersPanel = uipanel(app.NeuronMarkerGrid);
            app.MoveNeuronMarkersPanel.TitlePosition = 'centertop';
            app.MoveNeuronMarkersPanel.Title = 'Move Neuron Markers';
            app.MoveNeuronMarkersPanel.Layout.Row = [1 5];
            app.MoveNeuronMarkersPanel.Layout.Column = [1 2];
            app.MoveNeuronMarkersPanel.FontWeight = 'bold';

            % Create GridLayout16
            app.GridLayout16 = uigridlayout(app.MoveNeuronMarkersPanel);
            app.GridLayout16.ColumnWidth = {'1x', '0.5x', '0.5x', '1x'};
            app.GridLayout16.RowHeight = {35, '1x', '1x', 56, 56};

            % Create FlipVerticallyButton
            app.FlipVerticallyButton = uibutton(app.GridLayout16, 'push');
            app.FlipVerticallyButton.ButtonPushedFcn = createCallbackFcn(app, @FlipVerticallyButtonPushed, true);
            app.FlipVerticallyButton.Layout.Row = 5;
            app.FlipVerticallyButton.Layout.Column = [3 4];
            app.FlipVerticallyButton.Text = 'Flip Vertically';

            % Create CenterVerticallyButton
            app.CenterVerticallyButton = uibutton(app.GridLayout16, 'push');
            app.CenterVerticallyButton.ButtonPushedFcn = createCallbackFcn(app, @CenterVerticallyButtonPushed, true);
            app.CenterVerticallyButton.Layout.Row = 4;
            app.CenterVerticallyButton.Layout.Column = [1 2];
            app.CenterVerticallyButton.Text = 'Center Vertically';

            % Create CenterHorizontallyButton
            app.CenterHorizontallyButton = uibutton(app.GridLayout16, 'push');
            app.CenterHorizontallyButton.ButtonPushedFcn = createCallbackFcn(app, @CenterHorizontallyButtonPushed, true);
            app.CenterHorizontallyButton.Layout.Row = 4;
            app.CenterHorizontallyButton.Layout.Column = [3 4];
            app.CenterHorizontallyButton.Text = 'Center Horizontally';

            % Create Panel_13
            app.Panel_13 = uipanel(app.GridLayout16);
            app.Panel_13.BorderType = 'none';
            app.Panel_13.Layout.Row = 1;
            app.Panel_13.Layout.Column = [1 3];

            % Create GridLayout18
            app.GridLayout18 = uigridlayout(app.Panel_13);
            app.GridLayout18.ColumnWidth = {'1x', 35, '1x'};
            app.GridLayout18.RowHeight = {'1x'};
            app.GridLayout18.Padding = [0 0 0 0];

            % Create pixelsatatimeLabel
            app.pixelsatatimeLabel = uilabel(app.GridLayout18);
            app.pixelsatatimeLabel.Layout.Row = 1;
            app.pixelsatatimeLabel.Layout.Column = 3;
            app.pixelsatatimeLabel.Text = 'pixels at a time.';

            % Create MoveEditField_2
            app.MoveEditField_2 = uieditfield(app.GridLayout18, 'numeric');
            app.MoveEditField_2.ValueDisplayFormat = '%.0f';
            app.MoveEditField_2.HorizontalAlignment = 'center';
            app.MoveEditField_2.Layout.Row = 1;
            app.MoveEditField_2.Layout.Column = 2;
            app.MoveEditField_2.Value = 5;

            % Create MoveLabel
            app.MoveLabel = uilabel(app.GridLayout18);
            app.MoveLabel.HorizontalAlignment = 'right';
            app.MoveLabel.Layout.Row = 1;
            app.MoveLabel.Layout.Column = 1;
            app.MoveLabel.Text = 'Move ';

            % Create Panel_15
            app.Panel_15 = uipanel(app.GridLayout16);
            app.Panel_15.Layout.Row = [2 3];
            app.Panel_15.Layout.Column = [1 4];

            % Create GridLayout27
            app.GridLayout27 = uigridlayout(app.Panel_15);
            app.GridLayout27.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout27.ColumnSpacing = 3;
            app.GridLayout27.RowSpacing = 3;
            app.GridLayout27.Padding = [5 5 5 5];
            app.GridLayout27.BackgroundColor = [0.8 0.8 0.8];

            % Create CW
            app.CW = uibutton(app.GridLayout27, 'push');
            app.CW.ButtonPushedFcn = createCallbackFcn(app, @CWButtonPushed, true);
            app.CW.BackgroundColor = [0.3922 0.8314 0.0745];
            app.CW.FontSize = 18;
            app.CW.FontWeight = 'bold';
            app.CW.FontColor = [1 1 1];
            app.CW.Layout.Row = 1;
            app.CW.Layout.Column = [1 2];
            app.CW.Text = '↻';

            % Create CCW
            app.CCW = uibutton(app.GridLayout27, 'push');
            app.CCW.ButtonPushedFcn = createCallbackFcn(app, @CCWButtonPushed, true);
            app.CCW.BackgroundColor = [0.3922 0.8314 0.0745];
            app.CCW.FontSize = 18;
            app.CCW.FontWeight = 'bold';
            app.CCW.FontColor = [1 1 1];
            app.CCW.Layout.Row = 1;
            app.CCW.Layout.Column = [5 6];
            app.CCW.Text = '↺';

            % Create Down
            app.Down = uibutton(app.GridLayout27, 'push');
            app.Down.ButtonPushedFcn = createCallbackFcn(app, @DownButtonPushed, true);
            app.Down.IconAlignment = 'bottom';
            app.Down.BackgroundColor = [0.0745 0.6235 1];
            app.Down.FontSize = 18;
            app.Down.Layout.Row = 2;
            app.Down.Layout.Column = [3 4];
            app.Down.Text = '⬇️';

            % Create Right
            app.Right = uibutton(app.GridLayout27, 'push');
            app.Right.ButtonPushedFcn = createCallbackFcn(app, @RightButtonPushed, true);
            app.Right.IconAlignment = 'bottom';
            app.Right.BackgroundColor = [0.0745 0.6235 1];
            app.Right.FontSize = 18;
            app.Right.Layout.Row = 2;
            app.Right.Layout.Column = [5 6];
            app.Right.Text = '➡️';

            % Create Up
            app.Up = uibutton(app.GridLayout27, 'push');
            app.Up.ButtonPushedFcn = createCallbackFcn(app, @UpPushed, true);
            app.Up.IconAlignment = 'bottom';
            app.Up.BackgroundColor = [0.0745 0.6235 1];
            app.Up.FontSize = 18;
            app.Up.Layout.Row = 1;
            app.Up.Layout.Column = [3 4];
            app.Up.Text = '⬆️';

            % Create Left
            app.Left = uibutton(app.GridLayout27, 'push');
            app.Left.ButtonPushedFcn = createCallbackFcn(app, @LeftButtonPushed, true);
            app.Left.IconAlignment = 'bottom';
            app.Left.BackgroundColor = [0.0745 0.6235 1];
            app.Left.FontSize = 18;
            app.Left.Layout.Row = 2;
            app.Left.Layout.Column = [1 2];
            app.Left.Text = '⬅️';

            % Create FlipHorizontallyButton
            app.FlipHorizontallyButton = uibutton(app.GridLayout16, 'push');
            app.FlipHorizontallyButton.ButtonPushedFcn = createCallbackFcn(app, @FlipHorizontallyButtonPushed, true);
            app.FlipHorizontallyButton.Layout.Row = 5;
            app.FlipHorizontallyButton.Layout.Column = [1 2];
            app.FlipHorizontallyButton.Text = 'Flip Horizontally';

            % Show the figure after all components are created
            app.NeuroPAL_IDTraceWindowUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = trace_window(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NeuroPAL_IDTraceWindowUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NeuroPAL_IDTraceWindowUIFigure)
        end
    end
end