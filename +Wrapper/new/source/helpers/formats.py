import sys
from typing import Union
from shutil import get_terminal_size

trm = get_terminal_size().columns - 2


def wrap(message: Union[str, dict], title: str = None):
    if title is None:
        title = f"[ {sys._getframe().f_back.f_code.co_name} ]"
    else:
        title = f"[ {title} ]"

    l_pad = round((trm - len(title)) / 2)
    r_pad = trm - (l_pad + len(title))

    wrapped_out = f'\n┌{"─" * l_pad}{title}{"─" * r_pad}┐'

    match type(message).__name__:
        case 'str':
            db_string = f"│ {message}"
            padding = ' ' * (trm - len(db_string) + 1)
            wrapped_out = f"{wrapped_out}\n{db_string}{padding}│"

        case 'dict':
            for key, value in message.items():
                db_string = f"│ {key}: {value}"
                padding = ' ' * (trm - len(db_string) + 1)
                wrapped_out = f"{wrapped_out}\n{db_string}{padding}│"

    wrapped_out = f"{wrapped_out}\n└{'─' * trm}┘\n"

    return wrapped_out
