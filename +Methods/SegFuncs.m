function Unet3Prediction(img, model, shrink(24, 24, 2))
    % Predict cell/non-cell regions by applying 3D U-net on each sub-sub_images.
    % 
    % Parameters
    % ----------
    % img : numpy.ndarray
    %     Shape: (sample, x, y, z, channel), the normalized images to be segmented.
    % model : keras.Model
    %     The pre-trained 3D U-Net model.
    % shrink : tuple
    %     The surrounding voxels to make pad. It is also used to discard surrounding regions of each predicted sub-region.
    % 
    % Returns
    % -------
    % out_img : numpy.ndarray
    %     Predicted cell regions, shape: (sample, x, y, z, channel)
end

function r_disp = transform_layer_to_real(self, voxel_disp)
    % Transform the coordinates from layer to real
    r_disp = self._transform_disps(voxel_disp, self.z_xy_ratio);
end

function i_disp = transform_real_to_interpolated(self, r_disp)
    % Transform the coordinates from real to interpolated
    i_disp = round(self._transform_disps(r_disp, self.z_scaling / self.z_xy_ratio));
    i_disp = int32(i_disp);
end

function l_disp = transform_real_to_layer(self, r_disp)
    % Transform the coordinates from real to layer
    l_disp = round(self._transform_disps(r_disp, 1 / self.z_xy_ratio));
    l_disp = int32(l_disp);
end

function l_disp = transform_interpolated_to_layer(self, i_disp)
    % Transform the coordinates from interpolated to layer
    l_disp = round(self._transform_disps(i_disp, 1 / self.z_scaling));
    l_disp = int32(l_disp);
end

function [out_array, fw_map, inv_map] = relabel_sequential(label_field, offset)
   
    %{
    Relabel arbitrary labels to {`offset`, ... `offset` + number_of_labels}.
    This function also returns the forward map (mapping the original labels to
    the reduced labels) and the inverse map (mapping the reduced labels back
    to the original ones).
    Parameters
    ----------
    label_field : numpy array of int, arbitrary shape
        An array of labels, which must be non-negative integers.
    offset : int, optional
        The return labels will start at `offset`, which should be
        strictly positive.
    Returns
    -------
    relabeled : numpy array of int, same shape as `label_field`
        The input label field with labels mapped to
        {offset, ..., number_of_labels + offset - 1}.
        The data type will be the same as `label_field`, except when
        offset + number_of_labels causes overflow of the current data type.
    forward_map : ArrayMap
        The map from the original label space to the returned label
        space. Can be used to re-apply the same mapping. See examples
        for usage. The output data type will be the same as `relabeled`.
    inverse_map : ArrayMap
        The map from the new label space to the original space. This
        can be used to reconstruct the original label field from the
        relabeled one. The output data type will be the same as `label_field`.
    Notes
    -----
    The label 0 is assumed to denote the background and is never remapped.
    The forward map can be extremely big for some inputs, since its
    length is given by the maximum of the label field. However, in most
    situations, ``label_field.max()`` is much smaller than
    ``label_field.size``, and in these cases the forward map is
    guaranteed to be smaller than either the input or output images.
    Examples
    --------
    >>> from skimage.segmentation import relabel_sequential
    >>> label_field = np.array([1, 1, 5, 5, 8, 99, 42])
    >>> relab, fw, inv = relabel_sequential(label_field)
    >>> relab
    array([1, 1, 2, 2, 3, 5, 4])
    >>> print(fw)
    ArrayMap:
      1 → 1
      5 → 2
      8 → 3
      42 → 4
      99 → 5
    >>> np.array(fw)
    array([0, 1, 0, 0, 0, 2, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5])
    >>> np.array(inv)
    array([ 0,  1,  5,  8, 42, 99])
    >>> (fw[label_field] == relab).all()
    True
    >>> (inv[relab] == label_field).all()
    True
    >>> relab, fw, inv = relabel_sequential(label_field, offset=5)
    >>> relab
    array([5, 5, 6, 6, 7, 9, 8])
    %}

    if nargin < 2
        offset = 1;
    end

    if offset <= 0
        error("Offset must be strictly positive.")
    end

    if min(label_field(:)) < 0
        error("Cannot relabel array that contains negative values.")
    end

    offset = int32(offset);

    if in_vals(1) == 0
        % always map 0 to 0
        out_vals = [0, offset:offset+length(in_vals)-1];
    else
        out_vals = offset:offset+length(in_vals);
    end

    input_type = class(label_field);
    required_type = class(cast(out_vals(end), 'like', out_vals(end)));

    if strcmp(input_type, 'int8') || strcmp(input_type, 'int16') || ...
            strcmp(input_type, 'int32') || strcmp(input_type, 'int64')
        % input is integer type
        if strcmp(required_type, 'uint8') || strcmp(required_type, 'uint16') || ...
                strcmp(required_type, 'uint32') || strcmp(required_type, 'uint64')
            % required type is unsigned integer
            output_type = required_type;
        elseif strcmp(required_type, 'double')
            % required type is double
            output_type = required_type;
        else
            % required type is signed integer
            output_type = input_type;
            if out_vals(end) < intmin(output_type) || out_vals(end) > intmax(output_type)
                output_type = required_type;
            end
        end

    else
        % input is non-integer type
        output_type = required_type;
    end

    out_array = zeros(size(label_field), output_type);
    out_vals = cast(out_vals, output_type);
    map_array(label_field, in_vals, out_vals, out_array);
    fw_map = ArrayMap(in_vals, out_vals);
    inv_map = ArrayMap(out_vals, in_vals);
end

function [bn_output, boundary] = watershed_2d(image_pred, z_range, min_distance)
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
