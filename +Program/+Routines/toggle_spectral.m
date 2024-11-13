function toggle_spectral(mode)
    app = Program.GUIHandling.app;

    switch mode
        case 'colormap'
            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(5) = {212};
            app.ProcSideGrid.RowHeight = side_grid;

        case 'video'
            side_grid = app.ProcSideGrid.RowHeight;
            side_grid(5) = {0};
            app.ProcSideGrid.RowHeight = side_grid;
    end

    spectral_unmixing_gui = app.SpectralUnmixingGrid.Children;
    for comp=1:length(spectral_unmixing_gui)
        component = spectral_unmixing_gui(comp);
        if ismember(properties(component), 'Enable')
            component.Enable = ~component.Enable;
        end
    end
end