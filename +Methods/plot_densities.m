function plot_densities(densities, dir)
    % Check if 'dir' ends with a typical file extension, indicating it's not a directory
    [parentDir,~,ext] = fileparts(dir);
    if ~isempty(ext)
        % If there's an extension, use the parent directory instead
        dir = parentDir;
    end
    
    % Ensure 'densities' is a containers.Map
    if ~isa(densities, 'containers.Map')
        error('densities must be a containers.Map object');
    end
    
    % Iterate over each entry in the map
    keys = densities.keys;
    for n = 1:length(keys)
        key = keys{n};
        densityData = densities(key);
        density = densityData.density;
        pos = densityData.positions;
        stage = densityData.time;

        % Plot 3D figure of the point cloud without displaying it
        fig = figure('Visible', 'off');
        scatter3(pos(:,1), pos(:,2), pos(:,3), 'filled');
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title(sprintf('Point Cloud @ %s (Density = %.6f)', stage, density));
        grid on;
        
        % Adjustments to improve figure interaction
        axis equal; % Set equal scaling for all axes to prevent distortion
        daspect([1 1 1]);
        
        % Construct the filename ensuring the directory ends correctly
        filename = fullfile(dir, sprintf('%s.fig', stage)); % Change the extension to .fig
        
        % Save figure in MATLAB .fig format
        savefig(fig, filename); % Use savefig for .fig files
        close(fig); % Close the figure without displaying it
    end
end
