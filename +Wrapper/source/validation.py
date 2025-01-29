def is_file(fmt, data):
    match fmt:
        case "neuropal":
            is_valid_file = all(['data', 'info', 'prefs', 'version', 'worm'] in data.keys)

        case "vt_cache":
            is_valid_file = all(['frames', 'path', 'provenances', 'wl_record', 'worldlines'] in data.keys)

        case "config":
            is_valid_file = all(['is_config'] in data.keys)

        case _:
            is_valid_file = 2

    return is_valid_file


def is_valid_annotation(annotation):
    return annotation.x != 0 and annotation.y != 0 and annotation.z != 0
