function resize_window()
    % Resize the figure to fit most of the screen size.
    window = Program.GUIHandling.window_fig;

    screen_size = get(groot, 'ScreenSize');
    screen_size = screen_size(3:4);
    screen_margin = floor(screen_size .* [0.07,0.05]);

    figure_size(1:2) = screen_margin / 2;
    figure_size(3) = screen_size(1) - screen_margin(1);
    figure_size(4) = screen_size(2) - 2*screen_margin(2);
    
    window.Position = figure_size;
end

