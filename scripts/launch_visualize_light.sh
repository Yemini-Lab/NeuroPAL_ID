#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

if [ -n "${MATLAB_BIN:-}" ]; then
    matlab_bin="$MATLAB_BIN"
elif [ -x "/Applications/MATLAB_R2024a.app/bin/matlab" ]; then
    matlab_bin="/Applications/MATLAB_R2024a.app/bin/matlab"
elif command -v matlab >/dev/null 2>&1; then
    matlab_bin=$(command -v matlab)
else
    echo "Could not find a MATLAB binary." >&2
    echo "Set MATLAB_BIN or install MATLAB somewhere on PATH." >&2
    exit 1
fi

exec "$matlab_bin" \
    -desktop \
    -sd "$repo_root" \
    -r "try, run(fullfile(pwd,'scripts','launch_visualize_light.m')); catch ME, disp(getReport(ME,'extended','hyperlinks','off')); end"
