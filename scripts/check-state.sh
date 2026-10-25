#!/bin/bash
# Reports whether each tuning in this repo is currently active.
# Does not require root.
set -u

pass() { echo "  [OK]   $*"; }
warn() { echo "  [WARN] $*"; }
fail() { echo "  [FAIL] $*"; }

check_sysctl() {
    local key="$1" expect="$2"
    local got
    got=$(sysctl -n "$key" 2>/dev/null || echo "<missing>")
    if [[ "$got" == "$expect" ]]; then
        pass "$key = $got"
    else
        fail "$key = $got (expected $expect)"
    fi
}

echo "=== sysctl ==="
check_sysctl vm.swappiness 10
check_sysctl vm.vfs_cache_pressure 50
check_sysctl vm.dirty_ratio 10
check_sysctl vm.dirty_background_ratio 5
check_sysctl net.ipv4.tcp_congestion_control bbr
check_sysctl net.core.default_qdisc fq
check_sysctl net.core.rmem_max 16777216
check_sysctl net.core.wmem_max 16777216
check_sysctl net.core.rmem_default 2097152
check_sysctl net.core.wmem_default 2097152
check_sysctl fs.inotify.max_user_watches 524288

echo "=== modules ==="
if lsmod | grep -q "^tcp_bbr"; then pass "tcp_bbr loaded"; else fail "tcp_bbr not loaded"; fi

echo "=== systemd ==="
if [[ "$(systemctl is-enabled ps5-bt-reset.service 2>/dev/null)" == "enabled" ]]; then
    pass "ps5-bt-reset.service enabled"
else
    fail "ps5-bt-reset.service not enabled"
fi
if [[ "$(systemctl is-enabled NetworkManager-wait-online.service 2>/dev/null)" == "disabled" ]]; then
    pass "NetworkManager-wait-online.service disabled"
else
    warn "NetworkManager-wait-online.service still enabled"
fi
if [[ "$(systemctl is-enabled systemd-oomd.service 2>/dev/null)" == "masked" ]]; then
    pass "systemd-oomd.service masked"
else
    warn "systemd-oomd.service not masked"
fi

echo "=== files ==="
for f in \
    /etc/sysctl.d/99-ps5-gaming.conf \
    /etc/modules-load.d/bbr.conf \
    /etc/modprobe.d/blacklist-marvell.conf \
    /etc/modprobe.d/btusb-ps5.conf \
    /etc/udev/rules.d/99-ps5-bt-fantasma.rules \
    /etc/environment.d/99-mesa-cache.conf \
    /etc/systemd/system/ps5-bt-reset.service ; do
    if [[ -f "$f" ]]; then pass "exists: $f"; else fail "missing: $f"; fi
done

echo "=== BT ==="
if hciconfig hci0 2>/dev/null | grep -q "UP RUNNING"; then
    bd=$(hciconfig hci0 | awk '/BD Address/ {print $3}')
    pass "hci0 UP RUNNING (BD $bd)"
else
    warn "hci0 not UP RUNNING (ps5-bt-reset may run on next boot)"
fi
