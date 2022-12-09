classdef SegResults
    % Class to store the segmentation result.
    
    % Attributes
    % ----------
    % image_cell_bg : numpy.ndarray
    %     The cell/non-cell predictions by 3D U-Net
    % l_center_coordinates : list of tuple
    %     The detected centers coordinates of the cells, using voxels as the unit
    % segmentation_auto : numpy.ndarray
    %     The individual cells predicted by 3D U-Net + watershed
    % image_gcn : numpy.ndarray
    %     The raw image divided by 65535
    % r_coordinates_segment : numpy.ndarray
    %     Transformed from l_center_coordinates, with the z coordinates corrected by the resolution relative to x-y plane
    
    properties
        image_cell_bg
        l_center_coordinates
        segmentation_auto
        image_gcn
        r_coordinates_segment
    end
    
    methods
        function obj = SegResults()
            % Construct an instance of the SegResults class
            obj.image_cell_bg = [];
            obj.l_center_coordinates = [];
            obj.segmentation_auto = [];
            obj.image_gcn = [];
            obj.r_coordinates_segment = [];
        end
        
        function obj = update_results(obj, image_cell_bg, l_center_coordinates, segmentation_auto, image_gcn, r_coordinates_segment)
            % Update the attributes of a SegResults instance
            obj.image_cell_bg = image_cell_bg;
            obj.l_center_coordinates = l_center_coordinates;
            obj.segmentation_auto = segmentation_auto;
            obj.image_gcn = image_gcn;
            obj.r_coordinates_segment = r_coordinates_segment;
        end
    end
end
