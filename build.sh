#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# build.sh — Build the GNU Radio Docker image and create the deploy archive
#
# Usage:  ./build.sh
# Output: gnuradio-airgapped-deploy.tar.gz
# -----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="gnuradio-airgapped:latest"
IMAGE_TAR="gnuradio-airgapped-image.tar"
DEPLOY_TAR="gnuradio-airgapped-deploy.tar.gz"
STAGE_DIR="${SCRIPT_DIR}/.deploy-staging"

info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m    $*"; }
err()   { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

# ── Pre-flight ───────────────────────────────────────────────────────────────
command -v docker &>/dev/null || { err "Docker is not installed."; exit 1; }

# ── Build Docker image ───────────────────────────────────────────────────────
info "Building Docker image '${IMAGE_NAME}'…"
docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
ok "Docker image built."

# ── Export Docker image ──────────────────────────────────────────────────────
info "Saving Docker image to ${IMAGE_TAR} (this may take a while)…"
docker save "${IMAGE_NAME}" -o "${SCRIPT_DIR}/${IMAGE_TAR}"
ok "Docker image saved ($(du -h "${SCRIPT_DIR}/${IMAGE_TAR}" | cut -f1))."

# ── Extract GNU Radio icon from the image ────────────────────────────────────
info "Extracting GNU Radio icon from image…"
ICON_SRC="/usr/share/icons/hicolor/scalable/apps/gnuradio-grc.svg"
ICON_PNG="${SCRIPT_DIR}/gnuradio-icon.png"

# Try to extract SVG and convert, or grab a PNG directly
CONTAINER_ID=$(docker create "${IMAGE_NAME}" /bin/true)
if docker cp "${CONTAINER_ID}:${ICON_SRC}" "${SCRIPT_DIR}/gnuradio-grc.svg" 2>/dev/null; then
    # Convert SVG to PNG if rsvg-convert or convert is available
    if command -v rsvg-convert &>/dev/null; then
        rsvg-convert -w 256 -h 256 "${SCRIPT_DIR}/gnuradio-grc.svg" > "${ICON_PNG}"
        rm -f "${SCRIPT_DIR}/gnuradio-grc.svg"
    elif command -v convert &>/dev/null; then
        convert -resize 256x256 "${SCRIPT_DIR}/gnuradio-grc.svg" "${ICON_PNG}"
        rm -f "${SCRIPT_DIR}/gnuradio-grc.svg"
    else
        # Just ship the SVG as the icon
        mv "${SCRIPT_DIR}/gnuradio-grc.svg" "${ICON_PNG}"
        info "No SVG converter found — shipping SVG as icon."
    fi
    ok "Icon extracted."
else
    # Try a PNG fallback path
    PNG_SRC="/usr/share/icons/hicolor/256x256/apps/gnuradio-grc.png"
    if docker cp "${CONTAINER_ID}:${PNG_SRC}" "${ICON_PNG}" 2>/dev/null; then
        ok "Icon extracted (PNG)."
    else
        info "Could not extract icon from image — desktop entry will have no icon."
        touch "${ICON_PNG}"  # empty placeholder
    fi
fi
docker rm "${CONTAINER_ID}" > /dev/null 2>&1

# ── Stage the deploy archive ────────────────────────────────────────────────
info "Staging deploy archive…"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"

cp "${SCRIPT_DIR}/${IMAGE_TAR}"                    "${STAGE_DIR}/"
cp "${SCRIPT_DIR}/setup.sh"                        "${STAGE_DIR}/"
cp "${SCRIPT_DIR}/run.sh"                          "${STAGE_DIR}/"
cp "${SCRIPT_DIR}/gnuradio-companion.desktop"      "${STAGE_DIR}/"
[[ -s "${ICON_PNG}" ]] && cp "${ICON_PNG}" "${STAGE_DIR}/"

chmod +x "${STAGE_DIR}/setup.sh" "${STAGE_DIR}/run.sh"

# ── Create tar.gz ────────────────────────────────────────────────────────────
info "Creating ${DEPLOY_TAR}…"
tar -czf "${SCRIPT_DIR}/${DEPLOY_TAR}" -C "${STAGE_DIR}" .
ok "Deploy archive created: ${DEPLOY_TAR} ($(du -h "${SCRIPT_DIR}/${DEPLOY_TAR}" | cut -f1))"

# ── Cleanup ──────────────────────────────────────────────────────────────────
rm -rf "${STAGE_DIR}" "${SCRIPT_DIR}/${IMAGE_TAR}" "${ICON_PNG}"

echo ""
ok "Build complete!"
echo ""
echo "  To deploy on an airgapped machine:"
echo "    1.  Copy ${DEPLOY_TAR} to the target"
echo "    2.  mkdir gnuradio-airgapped && tar -xzf ${DEPLOY_TAR} -C gnuradio-airgapped"
echo "    3.  cd gnuradio-airgapped && sudo ./setup.sh"
echo ""
