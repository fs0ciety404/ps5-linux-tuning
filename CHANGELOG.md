# Changelog

## v0.1.0 — 2026-10-25

Initial public release.

- sysctl bundle: VM pressure, dirty page thresholds, TCP BBR + fq, UDP buffer sizes, inotify watches.
- systemd service `ps5-bt-reset.service`: works around MediaTek 0xfd98 ISO setup timeout on boot.
- modprobe rules: Marvell driver blacklist, btusb autosuspend disable.
- udev rules: hide ghost HID interfaces on MediaTek BT USB, force runtime PM on.
- Mesa shader cache env: raise to 5 GiB, single-file packing.
- Service tuning: mask `systemd-oomd`, disable `NetworkManager-wait-online`.
- Installer / rollback / state-check scripts.
- Documentation for every tuning, with rationale and trade-offs.
- Known-issues file: warm-reboot BT death, DualSense disconnects, GDM banding, Tempest DSP unavailable.
