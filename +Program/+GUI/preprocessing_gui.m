classdef preprocessing_gui
    %PREPROCESSING_GUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        canvas = [];        % image_editing_canvas instance.
        sidebar = [];       % preprocessing_sidebar instance.
        histograms = [];    % histograms instance.
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
    end
end

