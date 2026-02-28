FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install prerequisites and add GNU Radio PPA
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    gpg-agent \
    && add-apt-repository -y ppa:gnuradio/gnuradio-releases \
    && apt-get update

# Install GNU Radio, UHD, and GUI/X11/GTK dependencies
RUN apt-get install -y --no-install-recommends \
    gnuradio \
    uhd-host \
    libuhd-dev \
    python3-packaging \
    # GTK3 and GObject Introspection (required for gnuradio-companion GUI)
    gir1.2-gtk-3.0 \
    gir1.2-pango-1.0 \
    gir1.2-gdkpixbuf-2.0 \
    gir1.2-gobject-2.0-dev \
    libgtk-3-0t64 \
    python3-gi \
    python3-gi-cairo \
    python3-cairo \
    # X11 / display dependencies
    libgl1 \
    libx11-xcb1 \
    libxcb-xinerama0 \
    libxkbcommon-x11-0 \
    libfontconfig1 \
    libdbus-1-3 \
    dbus-x11 \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-keysyms1 \
    libxcb-shape0 \
    libxcb-render0 \
    libxcb-randr0 \
    libxcb-xfixes0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxrender1 \
    libxi6 \
    libxtst6 \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf-2.0-0 \
    libatk1.0-0t64 \
    libatk-bridge2.0-0t64 \
    xdg-utils \
    # Adwaita theme so GTK widgets render properly
    adwaita-icon-theme \
    gnome-themes-extra \
    # GTK audio event module (silences "Failed to load canberra-gtk-module" warning)
    libcanberra-gtk3-module \
    # Useful extras
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Download UHD FPGA images for all B-series devices at build time
RUN uhd_images_downloader -t b2 && \
    uhd_images_downloader -t b200 || true

# Set environment so UHD can find firmware
ENV UHD_IMAGES_DIR=/usr/share/uhd/images

ENTRYPOINT ["gnuradio-companion"]
