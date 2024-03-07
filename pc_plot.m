function pc_plot()
    % Load data from CSV files
    data1 = readtable('E:\data\for_kevin\for_kevin\alignment_test\zenodo\head-full-unmatched-atlas-output.csv');
    data2 = readtable('E:\data\for_kevin\for_kevin\alignment_test\base\head-full-unmatched-atlas-output.csv');
    data3 = readtable('E:\data\for_kevin\for_kevin\alignment_test\full\head-full-unmatched-atlas-output.csv');
    %data4 = readtable('E:\\data\\for_kevin\\for_kevin\\20190924_01\\aligned-head-fake-old.csv');
    %data5 = readtable('E:\\data\\for_kevin\\for_kevin\\20190924_01\\real-head-fake-full.csv');
    %data6 = readtable('E:\\data\\for_kevin\\for_kevin\\20190924_01\\aligned-head-fake-full.csv');
    
    % Load atlas data
    %atlas1 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\atlas_xx_rgb.mat');
    %atlas1 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\NP_atlas_matched.mat');
    atlas1 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\full_atlas_matched_exgroup2.mat');
    x1 = atlas1.atlas.head.model.mu(:, 1);
    y1 = atlas1.atlas.head.model.mu(:, 2);
    z1 = atlas1.atlas.head.model.mu(:, 3);
    
    %atlas2 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\NP_atlas_matched.mat');
    %atlas2 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\atlas_xx_rgb.mat');
    atlas2 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\full_atlas_matched_exgroup2.mat');
    x2 = atlas2.atlas.head.model.mu(:, 1);
    y2 = atlas2.atlas.head.model.mu(:, 2);
    z2 = atlas2.atlas.head.model.mu(:, 3);
    
    atlas3 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\full_atlas_matched_exgroup2.mat');
    %atlas3 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\atlas_xx_rgb.mat');
    %atlas3 = load('C:\\Users\\Yemini Laboratory\\Documents\\GitHub\\NeuroPAL_ID\\Data\\Models\\NP_atlas_matched.mat');
    x3 = atlas3.atlas.head.model.mu(:, 1);
    y3 = atlas3.atlas.head.model.mu(:, 2);
    z3 = atlas3.atlas.head.model.mu(:, 3);
    
    % Create 3D scatter plots
    figure;
    
    % Plot 1
    subplot(1, 3, 1);
    scatter3(x1, y1, z1, 'green', 'DisplayName', 'Atlas', 'Marker', '.');
    hold on;
    scatter3(data1.real_X, data1.real_Y, data1.real_Z, 'blue', 'DisplayName', 'real_XYZ', 'Marker', '.');
    scatter3(data1.aligned_X, data1.aligned_Y, data1.aligned_Z, 'red', 'DisplayName', 'aligned_XYZ', 'Marker', '.');
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Zenodo');
    legend;
    daspect([1 1 1]);
    hold off;
    
    % Plot 2
    subplot(1, 3, 2);
    scatter3(x2, y2, z2, 'green', 'DisplayName', 'Atlas', 'Marker', '.');
    hold on;
    scatter3(data2.real_X, data2.real_Y, data2.real_Z, 'blue', 'DisplayName', 'real_XYZ', 'Marker', '.');
    scatter3(data2.aligned_X, data2.aligned_Y, data2.aligned_Z, 'red', 'DisplayName', 'aligned_XYZ', 'Marker', '.');
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Base');
    legend;
    daspect([1 1 1]);
    hold off;
    
    % Plot 3
    subplot(1, 3, 3);
    scatter3(x3, y3, z3, 'green', 'DisplayName', 'Atlas', 'Marker', '.');
    hold on;
    scatter3(data3.real_X, data3.real_Y, data3.real_Z, 'blue', 'DisplayName', 'real_XYZ', 'Marker', '.');
    scatter3(data3.aligned_X, data3.aligned_Y, data3.aligned_Z, 'red', 'DisplayName', 'aligned_XYZ', 'Marker', '.');
    xlabel('X');
    ylabel('Y');    
    zlabel('Z');
    title('Consolidated');
    legend;
    daspect([1 1 1]);
    hold off;
end