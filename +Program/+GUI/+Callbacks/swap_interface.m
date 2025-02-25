function swap_interface()
    app = Program.app;
    selected_tab = app.TabGroup.SelectedTab;
    Program.states.set('interface', selected_tab.Title);

    if strcmp(selected_tab.Tag, 'raw')
        tab_type = selected_tab.Title.split(' ');
        loader = lower(sprintf("%s_tab", tab_type(end)));
        Program.Routines.Loaders.(loader);
        selected_tab.Tag = 'rendered';
    end
end

