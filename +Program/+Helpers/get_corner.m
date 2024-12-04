function corner = get_corner(positional_array, which_corner)
    if exist('which_corner', 'var')
        switch which_corner
            case {'tr', 'top_right', 'top right'}
                % Find indices of points with max x
                xMax = max(positional_array(:,1));
                xMaxIndices = find(positional_array(:,1) == xMax);
                % From those, find indices with min y
                yMin = min(positional_array(xMaxIndices,2));
                yMinIndices = xMaxIndices(positional_array(xMaxIndices,2) == yMin);
                if ~isempty(yMinIndices)
                    idx = yMinIndices(1); % pick the first one
                else
                    % Choose the one with max x and closest to min y
                    [~, sortIdx] = sort(positional_array(xMaxIndices,2));
                    idx = xMaxIndices(sortIdx(1));
                end
                corner = positional_array(idx, :);

            case {'tl', 'top_left', 'top left'}
                % Find indices of points with min x
                xMin = min(positional_array(:,1));
                xMinIndices = find(positional_array(:,1) == xMin);
                % From those, find indices with min y
                yMin = min(positional_array(xMinIndices,2));
                yMinIndices = xMinIndices(positional_array(xMinIndices,2) == yMin);
                if ~isempty(yMinIndices)
                    idx = yMinIndices(1); % pick the first one
                else
                    % Choose the one with min x and closest to min y
                    [~, sortIdx] = sort(positional_array(xMinIndices,2));
                    idx = xMinIndices(sortIdx(1));
                end
                corner = positional_array(idx, :);

            case {'br', 'bottom_right', 'bottom right'}
                % Find indices of points with max x
                xMax = max(positional_array(:,1));
                xMaxIndices = find(positional_array(:,1) == xMax);
                % From those, find indices with max y
                yMax = max(positional_array(xMaxIndices,2));
                yMaxIndices = xMaxIndices(positional_array(xMaxIndices,2) == yMax);
                if ~isempty(yMaxIndices)
                    idx = yMaxIndices(1); % pick the first one
                else
                    % Choose the one with max x and closest to max y
                    [~, sortIdx] = sort(positional_array(xMaxIndices,2), 'descend');
                    idx = xMaxIndices(sortIdx(1));
                end
                corner = positional_array(idx, :);

            case {'bl', 'bottom_left', 'bottom left'}
                % Find indices of points with min x
                xMin = min(positional_array(:,1));
                xMinIndices = find(positional_array(:,1) == xMin);
                % From those, find indices with max y
                yMax = max(positional_array(xMinIndices,2));
                yMaxIndices = xMinIndices(positional_array(xMinIndices,2) == yMax);
                if ~isempty(yMaxIndices)
                    idx = yMaxIndices(1); % pick the first one
                else
                    % Choose the one with min x and closest to max y
                    [~, sortIdx] = sort(positional_array(xMinIndices,2), 'descend');
                    idx = xMinIndices(sortIdx(1));
                end
                corner = positional_array(idx, :);

            otherwise
                error('Invalid value for which_corner.');
        end
    else
        corner = struct( ...
            'top_right', Program.Helpers.get_corner(positional_array, 'tr'), ...
            'top_left', Program.Helpers.get_corner(positional_array, 'tl'), ...
            'bottom_right', Program.Helpers.get_corner(positional_array, 'br'), ...
            'bottom_left', Program.Helpers.get_corner(positional_array, 'bl'));
    end
end
