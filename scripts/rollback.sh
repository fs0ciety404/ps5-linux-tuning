#!/bin/bash
# Rolls back every file installed by apply-all.sh.
# Restores pre-install files from the most recent backup directory.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: run as root (sudo ./scripts/rollback.sh)" >&2
    exit 1
fi

LATEST_BACKUP="$(ls -td /root/ps5-linux-tuning-backup-* 2>/dev/null | head -1 || true)"

echo "[*] Removing installed files"
rm -f /etc/sysctl.d/99-ps5-gaming.conf
rm -f /etc/modules-load.d/bbr.conf
rm -f /etc/modprobe.d/blacklist-marvell.conf
rm -f /etc/modprobe.d/btusb-ps5.conf
rm -f /etc/udev/rules.d/99-ps5-bt-fantasma.rules
rm -f /etc/environment.d/99-mesa-cache.conf
rm -f /etc/systemd/system/ps5-bt-reset.service

systemctl daemon-reload
systemctl disable ps5-bt-reset.service 2>/dev/null || true

echo "[*] Restoring services"
systemctl enable NetworkManager-wait-online.service 2>/dev/null || true
systemctl unmask systemd-oomd.service systemd-oomd.socket 2>/dev/null || true
systemctl enable systemd-oomd.service 2>/dev/null || true

if [[ -n "$LATEST_BACKUP" && -d "$LATEST_BACKUP" ]]; then
    echo "[*] Restoring originals from $LATEST_BACKUP"
    for f in "$LATEST_BACKUP"/*.orig; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f" .orig)"
        case "$base" in
            99-ps5-gaming.conf) dst=/etc/sysctl.d/$base ;;
            blacklist-marvell.conf|btusb-ps5.conf) dst=/etc/modprobe.d/$base ;;
            99-ps5-bt-fantasma.rules) dst=/etc/udev/rules.d/$base ;;
            99-mesa-cache.conf) dst=/etc/environment.d/$base ;;
            *) continue ;;
        esac
        cp -a "$f" "$dst"
        echo "    restored: $dst"
    done
fi

udevadm control --reload-rules
sysctl --system > /dev/null

echo "[OK] Rollback complete. Reboot recommended."
