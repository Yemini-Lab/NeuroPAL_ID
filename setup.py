import os
import pip
import platform

def install_reqs():
    print("Installing requirements...", flush=True)
    req_file = "requirements.txt"

    if platform.system() == "Darwin":  # macOS
        req_file = "requirements-macos.txt"

    try:
        try:
            pip.main(['install', '-r', req_file])
        except SystemExit:
            pass
    except Exception as e:
        print(f"An error occurred while installing requirements: {e}")

    return


if __name__ == "__main__":
    install_reqs()
    done = 1