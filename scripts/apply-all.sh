#!/bin/bash
# Idempotent installer: applies every tuning in this repo.
# Must run as root. Verifies state before applying each piece.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: run as root (sudo ./scripts/apply-all.sh)" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="/root/ps5-linux-tuning-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "[*] Backup directory: $BACKUP_DIR"

install_file() {
    local src="$1" dst="$2"
    if [[ -f "$dst" ]]; then
        cp -a "$dst" "$BACKUP_DIR/$(basename "$dst").orig"
        echo "    backed up: $dst"
    fi
    install -m 0644 "$src" "$dst"
    echo "    installed: $dst"
}

echo "[1/7] sysctl"
install_file "$REPO_DIR/sysctl/99-ps5-gaming.conf" /etc/sysctl.d/99-ps5-gaming.conf

echo "[2/7] tcp_bbr autoload"
echo tcp_bbr > /etc/modules-load.d/bbr.conf
modprobe tcp_bbr || echo "    warning: tcp_bbr load failed (kernel module missing?)"

echo "[3/7] modprobe rules"
install_file "$REPO_DIR/modprobe/blacklist-marvell.conf" /etc/modprobe.d/blacklist-marvell.conf
install_file "$REPO_DIR/modprobe/btusb-ps5.conf" /etc/modprobe.d/btusb-ps5.conf

echo "[4/7] udev rules"
install_file "$REPO_DIR/udev/99-ps5-bt-fantasma.rules" /etc/udev/rules.d/99-ps5-bt-fantasma.rules
udevadm control --reload-rules

echo "[5/7] mesa env"
mkdir -p /etc/environment.d
install_file "$REPO_DIR/env/99-mesa-cache.conf" /etc/environment.d/99-mesa-cache.conf

echo "[6/7] BT reset systemd service"
install -m 0644 "$REPO_DIR/systemd/ps5-bt-reset.service" /etc/systemd/system/ps5-bt-reset.service
systemctl daemon-reload
systemctl enable ps5-bt-reset.service

echo "[7/7] disable NetworkManager-wait-online + mask systemd-oomd"
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
systemctl disable --now systemd-oomd.service 2>/dev/null || true
systemctl disable --now systemd-oomd.socket 2>/dev/null || true
systemctl mask systemd-oomd.service systemd-oomd.socket 2>/dev/null || true

echo "[*] Reloading sysctl"
sysctl --system > /dev/null

echo ""
echo "[OK] Applied. Reboot recommended."
echo "    Run: ./scripts/check-state.sh"
echo "    Backup kept at: $BACKUP_DIR"
