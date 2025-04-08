function target_arr = to_type(arr, bits)
    [target_class, ~] = DataHandling.Types.getMATLABDataType(bits);
    target_arr = cast(arr, target_class);
end