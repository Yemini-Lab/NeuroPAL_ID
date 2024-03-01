import os
import platform
import subprocess


def create_virtual_env(shell_options):
    try:
        subprocess.Popen(["python", "-m", "venv", "./venv"], **shell_options)
    except Exception as e:
        print(f"An error occurred while creating the virtual environment: {e}")


def activate_venv_and_install_requirements(shell_options):
    req_file = "requirements.txt"
    activation_command = ".\\venv\\Scripts\\activate"

    if platform.system() == "Darwin":  # macOS
        req_file = "requirements-macos.txt"
        activation_command = "source ./venv/bin/activate"

    try:
        subprocess.Popen(f"{activation_command} && pip install -r {req_file}", **shell_options)
    except Exception as e:
        print(f"An error occurred while installing requirements: {e}")


if __name__ == "__main__":
    shell_options = {"shell": True, "creationflags": subprocess.CREATE_NO_WINDOW}
    create_virtual_env(shell_options)
    activate_venv_and_install_requirements(shell_options)
    done = 1
