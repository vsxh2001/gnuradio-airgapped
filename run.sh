#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# run.sh — Launch GNU Radio Companion inside Docker with USRP B-series support
# -----------------------------------------------------------------------------
set -euo pipefail

IMAGE_NAME="gnuradio-airgapped:latest"

# Allow local Docker containers to connect to the X server
xhost +local:docker > /dev/null 2>&1

cleanup() {
    xhost -local:docker > /dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --rm -it \
    --privileged \
    --net=host \
    -e DISPLAY="${DISPLAY}" \
    -e HOME="${HOME}" \
    -e XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
    -e DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}" \
    -e NO_AT_BRIDGE=1 \
    -e GTK_THEME=Adwaita \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/bus/usb:/dev/bus/usb \
    -v "${HOME}:${HOME}" \
    -v "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}:${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
    -w "${HOME}" \
    --user "$(id -u):$(id -g)" \
    "${IMAGE_NAME}" \
    "$@"
