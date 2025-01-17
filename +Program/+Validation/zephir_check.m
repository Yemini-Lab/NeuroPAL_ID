function arr = zephir_check(np, arr)
    is_zephir = max(arr) < 1;

    if is_zephir
        arr = arr * np;
    end
end

