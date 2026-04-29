function debug_log(varargin)
if Program.Helpers.debug_enabled()
    fprintf(varargin{:});
end
end
