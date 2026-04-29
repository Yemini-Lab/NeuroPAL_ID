function tf = bfTestInRange(value, ~, maxValue)
%BFTESTINRANGE Validate a 1-based scalar index or tile size for bfmatlab.
%
%   This helper is used by bfGetPlane inputParser validators. Some Bio-Formats
%   distributions ship bfGetPlane.m but omit this companion function.

tf = isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && ...
    value >= 1 && value <= double(maxValue) && value == floor(value);

end
