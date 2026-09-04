Run this from the normal Termux prompt, not from inside Debian.

It will:

Verify Termux is 64-bit.
Update Termux.
Install proot-distro.
Remove the old Debian container if one exists.
Install 64-bit Debian (aarch64).
Verify Debian is actually 64-bit.
Install Python 3.13, venv, pip and required build libraries.
Create the Home Assistant virtual environment.
Install Home Assistant.
Verify the installation.
Create a startup script for later automatic launching.
