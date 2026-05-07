classdef GUIPreferences < handle
    %GUIPreferences GUI preferences.
    
    % Constant GUI properties.
    properties (Constant, Access = public)
        
        % Version.
        %version = Program.ProgramInfo.version;
        
        % Preferences file info.
        prefs_dir = ''; %'NeuroPAL_ID/appdata/';
        prefs_name = '.NeuroPAL_ID_prefs.mat';
    end
    
    % User GUI properties.
    properties (Access = public)
        
        % Preferences file.
        prefs_file = [];
        
        % Data directories.
        image_dir = [];
        trace_path = [];
        seg_path = [];
        
        % Display info.
        GFP_color = [1,1,0]; % GFP reporter color for GUI
        neuron_dot; % neuron dot info: (un)selected marker + line sizes
        is_show_birth_times = false; % show the neuron birth times?
        is_auto_name = true; % auto-complete neuron names?
        is_autoID_updates = true; % auto-update neuron IDs?
        detection_backend = 'mp'; % one of: mp, nn, cellpose
        is_MP_detect = true; % are we using MP (or NN) to detect neurons?
    end
    
    % GUI public static methods.
    methods (Static, Access = public)
        function obj = instance()
            %INSTANCE get the GUIPreferences singelton.
             persistent instance;
             if isempty(instance)
                 
                 % Instantiate the class.
                 obj = Program.GUIPreferences();
                 
                 % Setup the preferences file location.
                 if ~isdeployed
                     obj.prefs_file = obj.prefs_name;
                 else
                     if ismac
                        prefs_root = '~/Library/Application Support';
                     else
                        prefs_root = ctfroot;
                     end

                     %prefs_root = prefs_root(1:i(end));
                     obj.prefs_file = ...
                         [prefs_root filesep obj.prefs_name];
                 end
                 
                 % Add the image directory.
                 if ispc
                     user_dir = what('\');
                 else
                     user_dir = what('~/');
                 end
                 obj.image_dir = user_dir.path;
                 
                 % Initilaize the neurons dots.
                obj.neuron_dot.marker.unselected = 40; % unselected neuron marker size
                if ismac % selected neuron marker size
                    obj.neuron_dot.marker.selected = 200;
                else
                    obj.neuron_dot.marker.selected = 100;
                end
                obj.neuron_dot.line = 2; % neuron line size
                % Applied to ID scatter markers in get_slice / renders.draw_z (keep mask on/off identical).
                obj.neuron_dot.marker_size_scale = 0.3;
                obj.neuron_dot.marker_line_scale = 0.3;
                 
                 % Save the instantiation.
                 instance = obj;
             else
               obj = instance;
             end
        end
        
        function save()
            %SAVE save the GUI preferences to their file.
            
            % Instantiate the class.
            obj = Program.GUIPreferences.instance();
            
            % Save the preferences.
            version = Program.ProgramInfo.version;
            GUI_prefs = obj;
            save(obj.prefs_file, 'version', 'GUI_prefs');
        end
        
        function is_loaded = load()
            %LOAD load the GUI preferences from their file.
            
            % Instantiate the class.
            obj = Program.GUIPreferences.instance();
            
            % Load the preferences.
            is_loaded = false;
            if exist(obj.prefs_file, 'file')
                is_loaded = true;
                prefs = load(obj.prefs_file);
                Program.GUIPreferences.read(prefs.GUI_prefs);
            end
        end
        
        function read(prefs)
            %READ read and store the GUI preferences.
            
            % Instantiate the class.
            obj = Program.GUIPreferences.instance();
            
            % Read the preferences.
            obj.prefs_file = prefs.prefs_file;
            obj.image_dir = prefs.image_dir;
            obj.GFP_color = prefs.GFP_color;
            obj.neuron_dot = prefs.neuron_dot;
            if ~isfield(obj.neuron_dot, 'marker_size_scale')
                obj.neuron_dot.marker_size_scale = 0.3;
            end
            if ~isfield(obj.neuron_dot, 'marker_line_scale')
                obj.neuron_dot.marker_line_scale = 0.3;
            end
            
            % Check for new properties.
            if isprop(prefs, 'is_show_birth_times')
                obj.is_show_birth_times = prefs.is_show_birth_times;
            end
            if isprop(prefs, 'is_auto_name')
                obj.is_auto_name = prefs.is_auto_name;
            end
            if isprop(prefs, 'is_autoID_updates')
                obj.is_autoID_updates = prefs.is_autoID_updates;
            end
            if isprop(prefs, 'detection_backend')
                obj.detection_backend = char(prefs.detection_backend);
            end
            if isprop(prefs, 'is_MP_detect')
                obj.is_MP_detect = prefs.is_MP_detect;
            end
            obj.detection_backend = Program.GUIPreferences.normalize_detection_backend( ...
                obj.detection_backend, obj.is_MP_detect);
            obj.is_MP_detect = strcmp(obj.detection_backend, 'mp');
        end

        function [marker_size_scale, marker_line_scale] = neuron_marker_display_scales()
            %NEURON_MARKER_DISPLAY_SCALES Scatter SizeData / LineWidth scale for ID view markers.
            % Fixed values so neuron dots look the same when opening a file, when toggling
            % Cellpose masks, and across get_slice vs renders.draw_z redraw paths. Stored
            % neuron_dot.marker_*_scale prefs are not applied here (they remain for compatibility).
            marker_size_scale = 0.3;
            marker_line_scale = 0.3;
        end

        function backend = get_detection_backend(varargin)
            %GET_DETECTION_BACKEND Return the normalized detector backend label.
            if nargin >= 1 && isa(varargin{1}, 'Program.GUIPreferences')
                obj = varargin{1};
            else
                obj = Program.GUIPreferences.instance();
            end
            backend = Program.GUIPreferences.normalize_detection_backend( ...
                obj.detection_backend, obj.is_MP_detect);
        end

        function set_detection_backend(varargin)
            %SET_DETECTION_BACKEND Store the detector backend and legacy flag.
            if nargin == 1
                obj = Program.GUIPreferences.instance();
                backend = varargin{1};
            elseif nargin == 2 && isa(varargin{1}, 'Program.GUIPreferences')
                obj = varargin{1};
                backend = varargin{2};
            else
                error('Program:GUIPreferences:InvalidBackendCall', ...
                    'set_detection_backend expects either (backend) or (obj, backend).');
            end
            backend = Program.GUIPreferences.normalize_detection_backend(backend, true);
            obj.detection_backend = backend;
            obj.is_MP_detect = strcmp(backend, 'mp');
        end
        
        function dot = inputNeuronDot()
            %INPUTNEURONDOT get the neuron dot info from the user.
            
            % Instantiate the class.
            obj = Program.GUIPreferences.instance();
            
            % Initialize the input dialog.
            title = 'Neuron Dots';
            prompt = {'Selected neuron dot size:', ...
                'Unselected neuron dot size:', ...
                'Neuron line size:'};
            definput = {num2str(obj.neuron_dot.marker.selected), ...
                num2str(obj.neuron_dot.marker.unselected), ...
                num2str(obj.neuron_dot.line)};
            dims = [1 35];
            
            % Get the user input.
            dot = [];
            answer = inputdlg(prompt, title, dims, definput);
            if isempty(answer)
                return;
            end
            
            % Parse the user input.
            dot.marker.selected = round(str2double(answer{1}));
            dot.marker.unselected = round(str2double(answer{2}));
            dot.line = round(str2double(answer{3}));
            
            % Check the user input.
            if dot.marker.selected < 1
                dot.marker.selected = 1;
            end
            if dot.marker.unselected < 1
                dot.marker.unselected = 1;
            end
            if dot.line < 1
                dot.line = obj.neuron_dot.line;
            end
            
            % Store the user input.
            obj.neuron_dot.marker.selected = dot.marker.selected;
            obj.neuron_dot.marker.unselected = dot.marker.unselected;
            obj.neuron_dot.line = dot.line;
        end
        
        function color = inputGFPColor()
            %INPUTGFPCOLOR get the GFP reporter color from the user.
            
            % Instantiate the class.
            obj = Program.GUIPreferences.instance();
            
            % Determine the current value.
            value = 1;
            if isequaln(obj.GFP_color, [1,1,0]) % 'yellow'
                value = 1;
            elseif isequaln(obj.GFP_color, [0,1,1]) % 'cyan'
                value = 2;
            elseif isequaln(obj.GFP_color, [1,0,1]) % 'magenta'
                value = 3;
            elseif isequaln(obj.GFP_color, [1,1,1]) % 'white'
                value = 4;
            elseif isequaln(obj.GFP_color, [1,0,0]) % 'red'
                value = 5;
            elseif isequaln(obj.GFP_color, [0,1,0]) % 'green'
                value = 6;
            elseif isequaln(obj.GFP_color, [0,0,1]) % 'blue'
                value = 7;
            end
            
            % Initialize the input dialog.
            title = 'GFP Reporter Color';
            prompt = 'Color for the GFP reporter channel:';
            list = {'yellow', 'cyan', 'magenta', 'white', ...
                'red', 'green', 'blue'};
            [color_i,~] = listdlg('PromptString', prompt, 'Name', title, ...
                'ListString', list, 'InitialValue', value, ...
                'SelectionMode', 'single');
            
            % Get the user input.
            color = [];
            if isempty(color_i)
                return;
            end
            
            % Parse and store the user input.
            color = list{color_i};
            switch color
                case 'yellow'
                    obj.GFP_color = [1,1,0];
                case 'cyan'
                    obj.GFP_color = [0,1,1];
                case 'magenta'
                    obj.GFP_color = [1,0,1];
                case 'white'
                    obj.GFP_color = [1,1,1];
                case 'red'
                    obj.GFP_color = [1,0,0];
                case 'green'
                    obj.GFP_color = [0,1,0];
                case 'blue'
                    obj.GFP_color = [0,0,1];
            end
        end
    end
    
    
    %% PRIVATE.
    
    % GUI private methods.
    methods (Static, Access = private)
        % Hide the constructor.
        function obj = GUIPreferences()
        end
    end

    methods (Static, Access = private)
        function backend = normalize_detection_backend(backend, is_mp_detect)
            %NORMALIZE_DETECTION_BACKEND Canonicalize persisted detector backend values.
            if nargin < 1 || isempty(backend)
                backend = '';
            end
            if nargin < 2
                is_mp_detect = true;
            end

            backend = lower(strtrim(char(string(backend))));
            switch backend
                case {'mp', 'matching_pursuit'}
                    backend = 'mp';
                case {'nn', 'neural', 'neural_network'}
                    backend = 'nn';
                case {'cellpose', 'cp'}
                    backend = 'cellpose';
                otherwise
                    if is_mp_detect
                        backend = 'mp';
                    else
                        backend = 'nn';
                    end
            end
        end
    end
end
