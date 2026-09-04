cat > ~/install-homeassistant.sh <<'SCRIPT'
#!/data/data/com.termux/files/usr/bin/bash

set -Eeuo pipefail

echo
echo "=========================================="
echo " Home Assistant - Termux ARM64 Installer"
echo "=========================================="
echo

fail() {
    echo
    echo "ERROR: $1"
    echo
    exit 1
}

echo "[1/10] Checking Termux architecture..."

TERMUX_ARCH="$(uname -m)"
TERMUX_DPKG_ARCH="$(dpkg --print-architecture)"

echo "  uname -m: $TERMUX_ARCH"
echo "  dpkg architecture: $TERMUX_DPKG_ARCH"

if [[ "$TERMUX_ARCH" != "aarch64" && "$TERMUX_DPKG_ARCH" != "arm64" ]]; then
    fail "Termux is not running as 64-bit ARM. Expected aarch64/arm64."
fi

echo "  OK: Termux is 64-bit ARM."
echo

echo "[2/10] Updating Termux..."

pkg update -y
pkg upgrade -y

echo
echo "[3/10] Installing PRoot-Distro..."

pkg install -y proot-distro

echo
echo "[4/10] Removing any old Debian installation..."

if proot-distro list | grep -qE '^[[:space:]]*\*?[[:space:]]*debian([[:space:]]|$)'; then
    echo "  Existing Debian detected."
    proot-distro remove debian
else
    echo "  No old Debian container found."
fi

echo
echo "[5/10] Installing 64-bit Debian..."

proot-distro install debian --architecture aarch64

echo
echo "[6/10] Verifying Debian architecture..."

DEBIAN_ARCH="$(proot-distro login debian -- bash -lc 'uname -m')"
DEBIAN_DPKG="$(proot-distro login debian -- bash -lc 'dpkg --print-architecture')"

echo "  Debian uname -m: $DEBIAN_ARCH"
echo "  Debian dpkg architecture: $DEBIAN_DPKG"

if [[ "$DEBIAN_ARCH" != "aarch64" ]]; then
    fail "Debian is NOT aarch64. Refusing to continue."
fi

if [[ "$DEBIAN_DPKG" != "arm64" ]]; then
    fail "Debian dpkg architecture is NOT arm64. Refusing to continue."
fi

echo "  OK: Debian is 64-bit ARM."
echo

echo "[7/10] Installing Debian dependencies..."

proot-distro login debian -- bash -lc '
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

apt update
apt full-upgrade -y

apt install -y \
    python3 \
    python3-venv \
    python3-pip \
    build-essential \
    libffi-dev \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    libopenjp2-7-dev \
    pkg-config \
    rustc \
    cargo \
    curl \
    wget \
    git \
    ca-certificates
'

echo
echo "[8/10] Creating Home Assistant virtual environment..."

proot-distro login debian -- bash -lc '
set -Eeuo pipefail

rm -rf /opt/homeassistant

python3 --version

python3 -m venv /opt/homeassistant

source /opt/homeassistant/bin/activate

python -m pip install --upgrade pip setuptools wheel
'

echo
echo "[9/10] Installing Home Assistant..."

proot-distro login debian -- bash -lc '
set -Eeuo pipefail

source /opt/homeassistant/bin/activate

python -m pip install homeassistant

echo
echo "Home Assistant version:"
hass --version
'

echo
echo "[10/10] Creating Home Assistant startup script..."

proot-distro login debian -- bash -lc '
cat > /usr/local/bin/start-homeassistant << "EOF"
#!/bin/bash
set -e

source /opt/homeassistant/bin/activate

exec hass -c /root/.homeassistant
EOF

chmod +x /usr/local/bin/start-homeassistant
'

echo
echo "=========================================="
echo " INSTALLATION SUCCESSFUL"
echo "=========================================="
echo
echo "Debian architecture:"
proot-distro login debian -- bash -lc 'uname -m && dpkg --print-architecture'

echo
echo "Python:"
proot-distro login debian -- bash -lc 'python3 --version'

echo
echo "Home Assistant:"
proot-distro login debian -- bash -lc 'source /opt/homeassistant/bin/activate && hass --version'

echo
echo "To start Home Assistant:"
echo
echo "  proot-distro login debian"
echo "  /usr/local/bin/start-homeassistant"
echo
echo "Then open:"
echo
echo "  http://PHONE-IP:8123"
echo
echo "=========================================="
SCRIPT

chmod +x ~/install-homeassistant.sh

~/install-homeassistant.sh
