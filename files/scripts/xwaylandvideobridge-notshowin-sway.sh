#!/usr/bin/bash
set -euo pipefail

desktop_file=/etc/xdg/autostart/org.kde.xwaylandvideobridge.desktop

if [[ ! -f "$desktop_file" ]]; then
    exit 0
fi

if grep -q '^NotShowIn=.*\bsway\b' "$desktop_file"; then
    exit 0
fi

if grep -q '^NotShowIn=' "$desktop_file"; then
    sed -i 's/^NotShowIn=.*/NotShowIn=sway;/' "$desktop_file"
else
    sed -i '/^X-GNOME-Autostart-enabled=/a NotShowIn=sway;' "$desktop_file"
fi
