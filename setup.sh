#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# setup.sh — Install GNU Radio Companion (Docker) on the target machine
#
# Usage:  sudo ./setup.sh
# This script is meant to be run from inside the extracted deploy archive.
# -----------------------------------------------------------------------------
set -euo pipefail

INSTALL_DIR="/opt/gnuradio-airgapped"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_FILE="gnuradio-companion.desktop"
IMAGE_TAR="gnuradio-airgapped-image.tar"
SYMLINK_PATH="/usr/local/bin/gnuradio-companion"

# ── Helpers ──────────────────────────────────────────────────────────────────
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m    $*"; }
err()   { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
die()   { err "$@"; exit 1; }

# ── Pre-flight checks ───────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "Please run this script as root:  sudo ./setup.sh"

command -v docker &>/dev/null || die "Docker is not installed. Please install Docker first."

[[ -f "${SCRIPT_DIR}/${IMAGE_TAR}" ]] || die "Docker image tar not found: ${SCRIPT_DIR}/${IMAGE_TAR}"

# ── Load Docker image ───────────────────────────────────────────────────────
info "Loading Docker image (this may take a few minutes)…"
docker load -i "${SCRIPT_DIR}/${IMAGE_TAR}"
ok "Docker image loaded successfully."

# ── Install application files ───────────────────────────────────────────────
info "Installing to ${INSTALL_DIR}…"
mkdir -p "${INSTALL_DIR}"

install -m 0755 "${SCRIPT_DIR}/run.sh"              "${INSTALL_DIR}/run.sh"
install -m 0644 "${SCRIPT_DIR}/gnuradio-icon.png"   "${INSTALL_DIR}/gnuradio-icon.png" 2>/dev/null || \
    info "Icon file not found — skipping icon install."

ok "Application files installed."

# ── Create gnuradio-companion symlink ────────────────────────────────────────
info "Creating symlink ${SYMLINK_PATH} → ${INSTALL_DIR}/run.sh"
ln -sf "${INSTALL_DIR}/run.sh" "${SYMLINK_PATH}"
ok "Symlink created. You can run 'gnuradio-companion' from any terminal."

# ── Install desktop entry ───────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "${REAL_USER}" | cut -d: -f6)

install_desktop_entry() {
    local dest="$1"
    mkdir -p "$(dirname "${dest}")"
    cp "${SCRIPT_DIR}/${DESKTOP_FILE}" "${dest}"
    chmod 0644 "${dest}"
    chown "${REAL_USER}:${REAL_USER}" "${dest}"
}

# Desktop shortcut
DESKTOP_DIR="${REAL_HOME}/Desktop"
if [[ -d "${DESKTOP_DIR}" ]]; then
    install_desktop_entry "${DESKTOP_DIR}/${DESKTOP_FILE}"
    # Mark trusted so GNOME/KDE doesn't show "untrusted" warning
    su - "${REAL_USER}" -c "gio set '${DESKTOP_DIR}/${DESKTOP_FILE}' metadata::trusted true" 2>/dev/null || true
    ok "Desktop shortcut installed."
else
    info "No ~/Desktop directory found — skipping desktop shortcut."
fi

# Application launcher
APP_DIR="${REAL_HOME}/.local/share/applications"
install_desktop_entry "${APP_DIR}/${DESKTOP_FILE}"
ok "Application launcher entry installed."

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
ok "Installation complete!"
echo ""
echo "  Launch GNU Radio Companion in any of these ways:"
echo "    1.  gnuradio-companion          (from terminal)"
echo "    2.  Double-click the desktop icon"
echo "    3.  Search 'GNU Radio' in your application launcher"
echo ""
echo "  Your home directory is mounted inside the container,"
echo "  so GRC projects under ${REAL_HOME} are accessible."
echo ""
