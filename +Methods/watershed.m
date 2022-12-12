function [bn_output, boundary] = watershed(image_pred, z_range, min_distance)
    % A function for segmenting cells with watershed in 3D images
    %
    % Parameters
    % ----------
    % image_pred : the binary image of cell region and background (predicted by 3D U-net)
    % z_range : number of layers
    % min_distance : the minimum cell distance allowed in the result
    %
    % Returns
    % -------
    % bn_output : binary image (cell/bg) removing boundaries detected by _watershed
    % boundary : image of cell boundaries
    
    boundary = zeros(size(image_pred), 'logical');

    for z = 1:z_range
        bn_image = image_pred(:,:,z) > 0.5;
        dist = bwdist(bn_image);
        dist_smooth = imgaussfilt(dist, 2);
    
        local_maxi = imregionalmax(dist_smooth, 'MinProminence', min_distance);
        markers = bwlabel(local_maxi);
        labels_ws = watershed(-dist_smooth, markers, bn_image);
        labels_bd = bwboundaries(labels_ws, 'noholes', 'outer');
    
        boundary(:,:,z) = labels_bd;
    end
    
    bn_output = image_pred > 0.5;
    bn_output(boundary == 1) = 0;
end

function [labels_wo_bd, labels_clear, min_size, cell_num] = watershed_3d(image_watershed2d, samplingrate, method, min_size, cell_num, min_distance)
  dist = distance_transform_edt(image_watershed2d, sampling=samplingrate);
  dist_smooth = filters.gaussian_filter(dist, [2, 2, 0.3], 'constant');
  local_maxi = peak_local_max(dist_smooth, min_distance=min_distance, exclude_border=0, indices=false);
  markers = morphology.label(local_maxi);
  labels_ws = watershed(-dist_smooth, markers, mask=image_watershed2d);

  if strcmp(method, "min_size")
      cell_num = sum(sort(histc(labels_ws(:), unique(labels_ws)), 'descend') >= min_size) - 1;
  elseif strcmp(method, "cell_num")
      min_size = sort(histc(labels_ws(:), unique(labels_ws)), 'descend')(cell_num + 1);
  else
      error("The method parameter should be either min_size or cell_num");
  end

  labels_clear = remove_small_objects(labels_ws, min_size=min_size, connectivity=3);

  labels_bd = find_boundaries(labels_clear, connectivity=3, mode='outer', background=0);
  labels_wo_bd = labels_clear.copy();
  labels_wo_bd(labels_bd == 1) = 0;
  labels_wo_bd = remove_small_objects(labels_wo_bd, min_size=min_size, connectivity=3);
end

function labels_ws = watershed_2d_markers(image_pred, mask, z_range=21)
  labels_ws = zeros(size(image_pred), 'int');
  for z = 1:z_range
      bn_image = logical_or(image_pred(:, :, z) > 0, mask(:, :, z) > 1);
      markers = image_pred(:, :, z);
      markers(mask(:, :, z) > 1) = 0;
      dist = distance_transform_edt(mask(:, :, z) > 1, sampling=[1, 1]);
      labels_ws(:, :, z) = watershed(dist, markers, mask=bn_image);
  end
end
