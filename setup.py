import os
import platform
import subprocess
import sys


def create_virtual_env():
    subprocess.run([sys.executable, "-m", "venv", "./venv"], check=True)


def install_requirements():
    req_file = "requirements.txt"
    pip_path = os.path.join("venv", "Scripts", "pip.exe")

    if platform.system() != "Windows":
        req_file = "requirements-macos.txt"
        pip_path = os.path.join("venv", "bin", "pip")

    subprocess.run([pip_path, "install", "-r", req_file], check=True)


if __name__ == "__main__":
    try:
        create_virtual_env()
        install_requirements()
    except subprocess.CalledProcessError as exc:
        print(f"Bootstrap failed: {exc}", file=sys.stderr)
        raise SystemExit(exc.returncode)
