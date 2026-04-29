function gamma = expand_gamma(gamma, n_slots)
if nargin < 2
    n_slots = 6;
end

if isempty(gamma)
    gamma = ones(1, n_slots);
    return
end

gamma = double(gamma(:)');

if isscalar(gamma)
    expanded = ones(1, n_slots);
    expanded(1:min(3, n_slots)) = gamma;
    gamma = expanded;
elseif numel(gamma) < n_slots
    expanded = ones(1, n_slots);
    expanded(1:numel(gamma)) = gamma;
    gamma = expanded;
else
    gamma = gamma(1:n_slots);
end
end
