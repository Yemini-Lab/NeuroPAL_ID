def is_file(fmt, data):
    match fmt:
        case "neuropal":
            d_keys = data.keys()
            is_valid_file = all(['data', 'info', 'prefs', 'version', 'worm'] in d_keys)

        case "vt_cache":
            d_keys = data.keys()
            is_valid_file = all(['frames', 'path', 'provenances', 'wl_record', 'worldlines'] in d_keys)

        case "config":
            d_keys = data.keys()
            is_valid_file = 'is_config' in d_keys

        case _:
            is_valid_file = 2

    return is_valid_file


def is_valid_annotation(annotation):
    return annotation.x != 0 and annotation.y != 0 and annotation.z != 0
