classdef tif
    %TIF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods (Static, Access = public)

        function np_file = to_npal(file)
            %CONVERTND2 Convert an ND2 file to NeuroPAL format.
            %
            % nd2_file = the ND2 file to convert
            % np_file = the NeuroPAL format file

            f = bfGetReader(file);                                              % Get reader object.

            nx = f.getSizeX;                                                    % Get width.
            ny = f.getSizeY;                                                    % Get height.
            nz = f.getSizeZ;                                                    % Get depth.
            nc = f.getSizeC;                                                    % Get channel count.
            nt = f.getSizeT;                                                    % Get frame count.

            bits = f.getMetadataStore.getPixelsSignificantBits(0).getValue();   % Get bit depth.
            bit_depth = sprintf("uint%.f", bits);                               % Convert bit depth to class string.

            if nz < 2 && nt > 1
                check = uiconfirm(uifigure(), ...
                    "No z-slices found. Use frames as slices?", "NeuroPAL_ID", ...
                    "Options", ["Yes", "No"]);

                if strcmp(check, "Yes")
                    % Preallocate array to hold the extracted image planes
                    data = zeros(ny, nx, nz, nc, 'like', bits);
                    nz = nt;
                    nt = -1;
                    
                else
                    return
                end
            end
        
            % Loop through indices to retrieve planes
            for z = 1:nz
                for c = 1:nc
                    if nt < 0        
                        % Calculate the index for the specific plane in the reader object
                        planeIndex = f.getIndex(0, c - 1, z - 1) + 1;
        
                        % Retrieve the plane data for the specified index
                        plane = bfGetPlane(f, planeIndex, 1, 1, nx, ny);
        
                        % Store the retrieved plane in the multidimensional array
                        data(:, :, z, c) = squeeze(plane);

                    else
                        for t = 1:nt            
                            % Calculate the index for the specific plane in the reader object
                            planeIndex = f.getIndex(z - 1, c - 1, t - 1) + 1;
            
                            % Retrieve the plane data for the specified index
                            plane = bfGetPlane(f, planeIndex, 1, 1, nx, ny);
            
                            % Store the retrieved plane in the multidimensional array
                            data(:, :, z, c, t) = squeeze(plane);
                        end
                    end
                end
            end

            info = struct('file', {file});                                      % Initialize info struct.

            scale = inputdlg({'X & Y microns/pixel:','Z microns/pixel:'}, ...
                'Image Scale', [1 35], {'0.3','0.9'});

            if isempty(scale)
                info.scale = [0 0 0];
            else
                xy_scale = str2double(scale{1});
                z_scale = str2double(scale{2});
                info.scale = [xy_scale, xy_scale, z_scale];
            end
            
            info.RGBW = 1:3;                                                    % Set RGBW indices.
            
            if nc > 4
                info.DIC = '5';                                                 % Set DIC if present, else set to 0.
            else
                info.DIC = nan;
            end

            if nc > 5
                info.GFP = '6';                                                 % Set GFP is present, else set to 0.
            else
                info.GFP = nan;
            end

            info.bit_depth = bit_depth;
            
            % Determine the gamma.
            info.gamma = Program.Handlers.channels.config{'default_gamma'};     % Set gamma to default since we can't get it from ND2 hashtable.
            
            % Initialize the user preferences.
            prefs.RGBW = info.RGBW;
            prefs.DIC = info.DIC;
            prefs.GFP = info.GFP;
            prefs.gamma = info.gamma;
            prefs.rotate.horizontal = false;
            prefs.rotate.vertical = false;
            prefs.z_center = ceil(nz / 2);
            prefs.is_Z_LR = true;
            prefs.is_Z_flip = true;
            
            % Initialize the worm info.
            worm.body = 'Head';
            worm.age = 'Adult';
            worm.sex = 'XX';
            worm.strain = '';
            worm.notes = '';
            
            % Save the ND2 file to our MAT file format.
            np_file = strrep(file, 'tif', 'mat');
            version = Program.information.version;
            save(np_file, 'version', 'data', 'info', 'prefs', 'worm', '-v7.3');
        end
    end
end

