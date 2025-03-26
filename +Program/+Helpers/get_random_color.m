function color = get_random_color()
    cmap1 = cool(15);
    random_row = randi(size(cmap1, 1), [1, 1]);
    color = cmap1(random_row, :);
end

