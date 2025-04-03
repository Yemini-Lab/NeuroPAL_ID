classdef preprocessing_gui
    %PREPROCESSING_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        canvas = [];            % image_editing_canvas instance.
        sidebar = [];           % preprocessing_sidebar instance.
        histograms = [];        % histograms instance.
        maximum_bytes = 13e7;   % The maximum size of arrays we allow users to load without triggering our preprocessing routine.
    end
    
    methods
        function obj = preprocessing_gui(type)
            %PREPROCESSING_GUI Constructs a persistent instance
            %   of the preprocessing gui.
            %
            %   Inputs:
            %   - type (Optional): string/char representing the type of
            %       volume we are dealing with. One of 'image' or 'video'.
            %
            %   Outputs:
            %   - obj: preprocessing_gui instance.
            persistent gui_instance

            % If uninitialized...
            if isempty(gui_instance)
                % Update persistent instance with constructed object.
                gui_instance = obj;

                % Construct or retrieve image_editing_canvas object & set
                % to canvas property.
                gui_instance.canvas = Program.GUI.Panels.image_editing_canvas();

                % Construct or retrieve preprocessing_sidebar object & set
                % to canvas property.
                gui_instance.sidebar = Program.GUI.Panels.preprocessing_sidebar();

                % Construct or retrieve histograms object & set to
                % histograms property. This will be added in the upcoming 
                % agnostic volume reader update.
                %gui_instance.histograms = Program.GUI.Panels.histograms();

                % Check whether a volume type (i.e. image or video) was
                % passed to the constructor.
                if exist('mode', 'var')
                    % If yes, configure the preprocessing gui accordingly.
                    gui_instance.set_gui_configuration(type);
                end
            end

            % Return the persistent instance.
            obj = gui_instance;
        end

        function obj = set_gui_configuration(obj, type)
            %SET_GUI_CONFIGURATION Configures all child GUI components to
            %   ensure that only those relevant to the selected volume type
            %   (i.e. image or video) are accessible.
            %
            %   Inputs:
            %   - obj: preprocessing_gui instance.
            %   - type: string/char, one of "image" or "video".
            %
            %   Outputs:
            %   - obj: preprocessing_gui instance.

            % Propagate the configuration call throughout all child
            % instances. We delegate updating their child components to
            % them to ensure modularity.
            obj.canvas.set_gui_configuration(type);
            obj.sidebar.set_gui_configuration(type);

            % Depending on the type, we grab the image/video dimensions
            % from different places. This is fixed in the upcoming
            % agnostic volume reader update.
            switch type
                case 'image'
                    limits = size(app.proc_image, 'data');
                case 'video'
                    limits = [ ...
                        app.video_info.nx, 
                        app.video_info.ny, 
                        app.video_info.nz, 
                        app.video_info.nc, 
                        app.video_info.nt]; 
            end

            % Update the preprocessing gui's limits based on the loaded
            % dimensions.
            obj.set_gui_limits( ...
                'x', limits(1), ...
                'y', limits(2), ...
                'z', limits(3), ...
                't', limits(5));
        end

        function obj = set_gui_limits(obj, varargin)
            %SET_GUI_LIMITS Updated all child gui components limit
            %   properties.
            %
            %   Inputs:
            %   - obj: preprocessing_gui instance.
            %   - varargin: Cell array of sequential key-value pairs which
            %       represent variable input arguments (e.g. 'x', 1x2 arr).
            %       See parser below for further details.
            %
            %   Outputs:
            %   - obj: preprocessing_gui instance.

            % Initiate inputParser object, which facilitates key-value
            % parsing of varargin.
            p = inputParser();

            % Initialize expected optional parameters & define their
            % default values should no parameter have been passed.
            addParameter(p, 'x', []);       % 1x2 array representing limits along the x dimension.
            addParameter(p, 'y', []);       % 1x2 array representing limits along the y dimension.
            addParameter(p, 'z', []);       % 1x2 array representing limits along the z dimension.
            addParameter(p, 't', []);       % 1x2 array representing limits along the t dimension.

            % Parse varargin with the parameters specified above.
            parse(p, varargin{:});

            % Remove any parameters that were not passed from our parsed
            % results struct. E.g. if no t parameter was passed, inputs
            % will only contain the fields 'x', 'y', and 'z'.
            inputs = rmfield(p.Results, p.UsingDefaults);

            % Get a cell array of passed parameters.
            input_fields = fieldnames(inputs);

            % For each passed parameter...
            for n=1:length(input_fields)
                % Get parameter key & value.
                field = input_fields{n};
                limits = inputs.(field);

                % Check which parameter we're dealing with.
                switch field
                    case 'x'
                        % If this parameter is x, update every axes
                        % components XLim property.
                        structfun(@(x)(set(x, 'XLim', limits)), ...
                            obj.canvas.axes);

                        % Then update the limits of the x slider.
                        obj.canvas.sliders.x.Limits = limits;

                    case 'y'
                        % If this parameter is y, update every axes
                        % components YLim property.
                        structfun(@(x)(set(x, 'YLim', limits)), ...
                            obj.canvas.axes);

                        % Then update the limits of the y slider.
                        obj.canvas.sliders.y.Limits = limits;
                        
                    case 'z'
                        % If this parameter is z, update the limits of all
                        % z sliders. Note that there are several of these
                        % because we support various projections. See
                        % Program.GUI.Panels.image_editing_canvas.m for
                        % details.
                        structfun(@(x)(set(x, 'Limits', limits)), ...
                            obj.canvas.sliders.z);

                    case 't'
                        % If this parameter is t, update the limits of the
                        % time slider.
                        obj.canvas.video_only_components.timeline.Limits = limits;
                end
            end
        end

        function obj = pass_to_main(obj)
            %PASS_TO_MAIN Transfers processed result to either the ID or
            %   the tracking tab, depending on whether we're dealing with
            %   an image or a video.
            %   
            %   Inputs:
            %   - obj: preprocessing_gui instance.

            % Get running app instance.
            app = Program.ProgramInfo.app;

            % Initialize the struct that will be passed to the appropriate
            % load function.
            result_package = struct();

            % Check which volume type we're working with (i.e. image or
            % video).
            switch app.VolumeDropDown.Value
                case 'Colormap'
                    % If it's a color stack, grab the target file path from
                    % the "Source" property of the lazy loaded matfile 
                    % instance referenced by proc_image.
                    result_package.file = app.proc_image.Properties.Source;

                    %app.id_file = DataHandling.Helpers.npal.create_neurons('matfile', app.proc_image);
                    
                    % Switch to the ID Tab.
                    app.TabGroup.SelectedTab = app.NeuroPALIDTab;
        
                case 'Video'
                    % If it's a video, grab the target file path from
                    % the "file" property of the lazy loaded video_info
                    % property.
                    result_package.file = app.video_info.file;

                    % Switch to the video tracking tab.
                    app.TabGroup.SelectedTab = app.VideoTrackingTab;
            end
        end
    end

    methods (Static, Access = public)
        function code = check_for_preprocessing_threshold(file_path)
            %CHECK_FOR_PREPROCESSING_THRESHOLD Checks whether a given file 
            %   needs to be passed to the preprocessing routine. If so,
            %   passes file to preprocessing load function.
            %
            %   Inputs:
            %   - file_path: String/char representing the path to the file
            %       in question.
            %
            %   Outputs:
            %   - code: Integer describing the outcome of running this
            %       function as such:
            %           0 -> File was not submitted to preprocessing.
            %           1 -> File was submitted to preprocessing.
            %           2 -> File needed preprocessing, but user opted out.
            %           3 -> Could not determine whether file needs to be
            %               preprocessed. This occurs if we are unable to
            %               calculate the data size.

            % Check whether the given file meets the preprocessing
            % threshold.
            switch Program.GUI.preprocessing_gui.check_data_size(file_path)
                case 1
                    % If the file exceeds our preprocessing threshold, get
                    % the active window handle.
                    window = Program.ProgramInfo.window;
        
                    % Create a dialogue warning the user and recommending
                    % that the file be preprocessed.
                    dialogue_response = uiconfirm(window, ...
                        sprintf("Your data size exceeds our recommended " + ...
                        "working limit of 100 mb. We strongly recommend " + ...
                        "preprocessing your file as you may run into " + ...
                        "memory issues otherwise.\nPreprocess now?"), ...
                        "Warning!", "Options", ["Yes", "No"]);
        
                    if strcmpi(dialogue_response, "Yes")
                        % If the user opts to preprocess the file, set code
                        % to 1 and pass it the file path to the
                        % preprocessing load function.
                        code = 1;
                        app.proc_load(file_path);
                    else
                        % If the users opts not to preprocess the file, set
                        % code to 2.
                        code = 2;
                    end

                case 2
                    % If the size of the data contained within the file
                    % could not be calculated, set code to 3. This happens
                    % if the given file has no associated helper class.
                    code = 3;
            end
        end

        function code = check_data_size(file_path)   
            %CHECK_FILE_SIZE Calculates the size of the data contained
            %   within a given file and checks it against our preprocessing
            %   threshold.
            %
            %   Inputs:
            %   - file_path: String/char representing the path to the file
            %       in question.
            %
            %   Outputs:
            %   - code: Integer describing the outcome of running this
            %       function as such:
            %           0 -> Data size is smaller than our threshold.
            %           1 -> Data size exceeds preprocessing threshold and
            %               needs to be preprocessed.
            %           2 -> Failed to assess data size.

            % Calculate the maximum possible array size of given system's
            % memory. Note that we limit the maximum file size to 90% of
            % the maximum possible array to leave a compute buffer.

            % Initialize code as 0.
            code = 0;

            % Get the dialogues class handle.
            dlg = Program.GUI.dialogues;

            % If there is an active progress dialogue, prompt it to
            % indicate that we are now checking the size of the file's data.
            dlg.step("Checking data size...")

            % Get the format of the given file.
            [~, ~, file_format] = fileparts(file_path);
            file_format = file_format(2:end);

            % Construct the name of the helper class corresponding to this
            % file format.
            helper = sprintf("DataHandling.Helpers.%s", file_format);

            % If this helper class does not exist...
            if ~exist(helper, 'class')
                % We could theoretically check the file size by calling
                % dir() on the file path, but this would be pointless
                % because we cannot preprocess the file without a helper
                % class. Thus...

                % Set code to 2 in order to indicate that we are unable to
                % perform a size check, then return.
                code = 2;
                return
            end

            % Check the file format.
            switch file_format
                case 'nwb'
                    % Get the nwb helper class.
                    nwb_helper = DataHandling.Helpers.nwb;

                    % If we're dealing with an nwb file, we need to know
                    % which module the user intends to load before we can
                    % check its size. Thus, we use the identify_module
                    % function within the nwb helper class.
                    selected_module = nwb_helper.identify_module( ...
                        file_path);

                    % Check whether the selected module is empty.
                    if isempty(selected_module)
                        % If the selected module is empty, the user
                        % canceled during module selection, so return.
                        return
                    end

                    % Get the dimensions of the module's data.
                    dimensions = selected_module.data.internal_dims();

                    % Get the data type of the module's data.
                    data_type = string(selected_module.data.dataType);
                    
                    % Extract the bit depth from the datatype.
                    bit_depth = str2double( ...
                        extract(data_type, digitsPattern));

                    % Calculate the size of the module's data by
                    % multiplying its dimensions by its bit depth.
                    total_size = prod(dimensions) * bit_depth;

                otherwise
                    % For any other supported file format, the data
                    % constitutes such a large fraction fo the file's size
                    % that we can safely operate under the assumption that
                    % the file size is equal to the data size for all
                    % intended purposes. Thus...

                    % Call dir on the file path to obtains further
                    % information about it.
                    file_info = dir(file_path);

                    % Get the size of this file.
                    total_size = file_info.bytes;
            end

            % Get the maximum array size.
            maximum_array_size = Program.system.get_maximum_array_size;

            % Check whetehr the total bytes exceed the array size that
            % would allow the system to run computationally demanding
            % operations without issues.
            exceeds_maximum_array_size = total_size > maximum_array_size;

            % Check whether the total bytes that would be loaded from this
            % file exceed the threshold that triggers our processing
            % routine.
            exceeds_maximum_bytes = total_size > obj.maximum_bytes;

            % Set code equal to whether the total bytes exceed either the
            % maximum array size or our preprocessing threshold.
            code = exceeds_maximum_array_size || exceeds_maximum_bytes;
        end
    end
end

