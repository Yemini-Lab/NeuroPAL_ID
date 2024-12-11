function load_file(mode, path)
            app = Program.app;
            window = Program.window;

            d = uiprogressdlg(window,"Title","NeuroPAL ID","Message","Initializing Processing Tab...",'Indeterminate','off');    
            app.flags = struct();
            app.rotation_stack.cache = struct('Colormap', {{}}, 'Video', {{}});
            gammas = [];
            
            [filepath, name, ext] = fileparts(path);

            switch mode
                case "image"
                    Program.Routines.GUI.add_volume('Colormap')
                    mat_file = fullfile(filepath, [name, '.mat']);
                    if ~isfile(mat_file)
                        DataHandling.NeuroPALImage.open(path);
                        path = mat_file;
                    end

                    app.proc_image = matfile(mat_file);

                    vol_size = size(app.proc_image, 'data');
                    nx = vol_size(2);
                    ny = vol_size(1);
                    nz = vol_size(3);
                    nc = vol_size(4);
                    nt = 1;

                    prefs = app.proc_image.prefs;
                    gammas = prefs.gamma;

                    % Using intmax is faster as it avoids loading the
                    % entire variable, but it also distorts the histograms.
                    % max_val = double(intmax(class(app.proc_image.data(1, 1, 1, 1))));
                    maximum_value = double(max(app.proc_image.data, [], 'all'));

                    app.VolumeDropDown.Value = 'Colormap';
                    app.data_flags.('NeuroPAL_Volume') = 1;
                    Program.Routines.GUI.toggle_colormap();

                case "video"
                    Program.Routines.GUI.add_volume('Video')
                    Program.Routines.Videos.load(path);
                    maximum_value = double(intmax(class(app.retrieve_frame(3))));

                    nx = app.video_info.nx;
                    ny = app.video_info.ny;
                    nz = app.video_info.nz;
                    nc = app.video_info.nc;
                    nt = app.video_info.nt;

                    app.VolumeDropDown.Value = 'Video';
                    app.data_flags.('Video_Volume') = 1;
                    
                    Program.Routines.GUI.toggle_video();
            end
    
            d.Value = 2 / 5;
            d.Message = sprintf('Calculating threshold...');
            Program.GUIHandling.set_thresholds(app, maximum_value);
    
            d.Value = 3 / 5;
            d.Message = sprintf('Mapping channels...');
            Program.Handlers.channels.initialize(path);
    
            app.nameMap = containers.Map( ...
                {app.ProcRDropDown.Value, app.ProcGDropDown.Value, app.ProcBDropDown.Value, ...
                 app.ProcWDropDown.Value, app.ProcDICDropDown.Value, app.ProcGFPDropDown.Value}, ...
                {'Red', 'Green', 'Blue', 'White', 'DIC', 'GFP'} ...
            );
    
            app.shortMap = containers.Map( ...
                {app.ProcRDropDown.Value, app.ProcGDropDown.Value, app.ProcBDropDown.Value, ...
                 app.ProcWDropDown.Value, app.ProcDICDropDown.Value, app.ProcGFPDropDown.Value}, ...
                {'r', 'g', 'b', 'k', 'k', 'y'} ...
            );
    
            d.Value = 4 / 5;
            d.Message = sprintf('Configuring GUI...');
            daspect(app.proc_xyAxes, [1 1 1]);

            if nc < 4
                app.ProcHistogramGrid.RowHeight = {'1x'};
            end
            
            Program.Routines.GUI.set_limits(nx, ny, nz, nt);

            app.ProcXYFactorEditField.Enable = 'on';
            app.ProcZSlicesEditField.Enable = 'on';

            set(app.proc_xEditField, 'Enable', 'off');
            set(app.proc_yEditField, 'Enable', 'off');
    
            if isempty(gammas)
                app.tl_GammaEditField.Value = 1;
                app.tm_GammaEditField.Value = 1;
                app.tr_GammaEditField.Value = 1;
                app.bl_GammaEditField.Value = 1;
                app.bm_GammaEditField.Value = 1;
                app.br_GammaEditField.Value = 1;
            else
                for n=1:size(gammas, 2)
                    switch n
                        case 1
                            app.tl_GammaEditField.Value = gammas(1);
                        case 2
                            app.tm_GammaEditField.Value = gammas(2);
                        case 3
                            app.tr_GammaEditField.Value = gammas(3);
                        case 4
                            app.bl_GammaEditField.Value = gammas(4);
                        case 5
                            app.bm_GammaEditField.Value = gammas(5);
                        case 6
                            app.br_GammaEditField.Value = gammas(6);
                    end
                end
            end
    
            d.Value = 5 / 5;
            d.Message = sprintf('Drawing image...');
            app.drawProcImage();

            app.ImageProcessingTab.Tag = 'rendered';
            set(app.ProcessingButton, 'Visible', 'off');
            set(app.ProcessingGridLayout, 'Visible', 'on');

            app.TabGroup.SelectedTab = app.ImageProcessingTab;
            close(d)

            check = uiconfirm(app.CELL_ID, "We recommend starting by cropping your image to ensure that there is no superfluous space taking up memory. Do you want to do so now?", "NeuroPAL_ID", "Options", ["Yes", "No, skip cropping."]);
            switch check
                case "Yes"
                    app.ProcCropImageButtonPushed([]);
                    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
                case "No, skip cropping."
                    app.drawProcImage();
                    Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
            end

            Program.GUIHandling.gui_lock(app, 'unlock', 'processing_tab');
end

