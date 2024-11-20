function arr = true_cast(arr, tclass)
    if ~isstring(tclass)
        tclass = class(tclass);
    end

    og_class = class(arr);

    if ~strcmp(og_class, tclass)
        arr = arr/intmax(og_class);
        arr = cast(arr, tclass);
        arr = arr * intmax(tclass);
    end
end

