function [xy, z_gui, z_data] = extract_z_slice(volume, z_gui, is_z_flip)
    if nargin < 3 || isempty(is_z_flip)
        is_z_flip = false;
    end

    nz = size(volume, 3);
    z_gui = Program.Helpers.gui_z_to_data_index(z_gui, nz, false);
    z_data = Program.Helpers.gui_z_to_data_index(z_gui, nz, is_z_flip);
    xy = squeeze(volume(:, :, z_data, :, :));
end
