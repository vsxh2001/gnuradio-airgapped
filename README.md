# GNU Radio Airgapped — Docker Deployment for USRP B-series

Containerised GNU Radio Companion with UHD support for Ettus USRP B200, B210, and B200mini.
Designed for airgapped / offline deployment — everything is bundled into a single archive.

## Quick Start

### Build (requires internet)

```bash
./build.sh
```

This produces **`gnuradio-airgapped-deploy.tar.gz`** containing the Docker image and installer.

### Deploy (airgapped OK)

```bash
# Copy the archive to the target machine, then:
mkdir gnuradio-airgapped && tar -xzf gnuradio-airgapped-deploy.tar.gz -C gnuradio-airgapped
cd gnuradio-airgapped
sudo ./setup.sh
```

The installer will:
- Load the Docker image
- Install a launcher script to `/opt/gnuradio-airgapped/`
- Create a `gnuradio-companion` symlink in `/usr/local/bin/`
- Add a desktop icon and application launcher entry

### Launch

```bash
# From terminal
gnuradio-companion

# Or open a specific flowgraph
gnuradio-companion ~/my-project/flowgraph.grc
```

You can also double-click the **GNU Radio Companion** icon on your desktop.

## How It Works

The container runs **privileged** with:
- `/dev/bus/usb` mounted for USRP USB access
- `$HOME` mounted so your GRC projects are directly accessible
- X11 forwarding for the GUI

## Prerequisites

### Build machine
- Docker
- Internet access (to pull base image and packages)

### Target machine
- Docker installed, current user able to run `docker` commands
- X11 display server (Wayland with XWayland also works)
- USRP device connected via USB

## Troubleshooting

### USRP not detected

Run inside a terminal to check:
```bash
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb gnuradio-airgapped:latest uhd_find_devices
```

If no devices are found, verify the USB connection with `lsusb` on the host.

### GUI does not appear

Make sure `$DISPLAY` is set and X11 is running. The `run.sh` script calls
`xhost +local:docker` automatically — if this is blocked by your security policy,
you may need to configure X11 auth manually.

### File permissions

The container runs as your host UID/GID so file ownership should match.
If you encounter permission issues, check that your home directory is readable.

## Contents of the Deploy Archive

| File | Purpose |
|------|---------|
| `gnuradio-airgapped-image.tar` | Docker image (GNU Radio + UHD + B-series firmware) |
| `setup.sh` | Installer script |
| `run.sh` | Container launcher |
| `gnuradio-companion.desktop` | Desktop entry file |
| `gnuradio-icon.png` | Application icon |
