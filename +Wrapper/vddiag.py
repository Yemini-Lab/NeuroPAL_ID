import pkg_resources

# Create a list of all installed libraries in the current environment
pip_list = [str(d) for d in pkg_resources.working_set]