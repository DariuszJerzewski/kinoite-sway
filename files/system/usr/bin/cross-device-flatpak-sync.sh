#!/usr/bin/env bash
set -euo pipefail

SYNC_DIR="/etc/kinoite-sway-config/sync"
PACKAGE_LIST="$SYNC_DIR/flatpak-pkgs.txt"

mkdir -p "$SYNC_DIR"

wget -q -O "$PACKAGE_LIST" "https://raw.githubusercontent.com/DariuszJerzewski/cross-device-os-sync/refs/heads/main/flatpak-pkgs.txt"

flatpak install flathub -y $(<"$PACKAGE_LIST")
