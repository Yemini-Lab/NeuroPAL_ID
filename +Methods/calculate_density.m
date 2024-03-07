function new_densities = calculate_density(densities, stage, pos)
    % Calculate volumes
    volume = max(pos(:,1)) * max(pos(:,2)) * max(pos(:,3));
    
    % Calculate density
    new_density = size(pos, 1) / volume;

    % Check if densities is empty or not a containers.Map, initialize if necessary
    if isempty(densities) || ~isa(densities, 'containers.Map')
        densities = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    % Create a new struct for the current stage
    stageData = struct('density', new_density, 'positions', pos, 'time', stage);
    
    % Append or update the stage data in the densities map
    densities(stage) = stageData;
    
    % Return the updated densities map
    new_densities = densities;
end
