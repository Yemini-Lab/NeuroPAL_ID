function z_data = gui_z_to_data_index(z_gui, nz, is_z_flip)
    if nargin < 3 || isempty(is_z_flip)
        is_z_flip = false;
    end

    nz = max(1, round(double(nz)));
    z_gui = min(max(round(double(z_gui)), 1), nz);
    z_data = z_gui;

    if is_z_flip
        z_data = nz - z_gui + 1;
    end
end
