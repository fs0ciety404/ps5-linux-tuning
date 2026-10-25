# Bluetooth fix: MediaTek 0xfd98 timeout

## Symptom

After a cold boot, with the [WizGery/ps5-mediatek-fixes](https://github.com/WizGery/ps5-mediatek-fixes) `btusb.ko` loaded, Bluetooth comes up partially. `hciconfig hci0` reports:

```
hci0:   Type: Primary  Bus: USB
        BD Address: 00:00:00:00:00:00  ACL MTU: 0:0  SCO MTU: 0:0
        DOWN INIT RUNNING
```

`dmesg` shows:

```
Bluetooth: hci0: command 0xfd98 tx timeout
Bluetooth: hci0: Failed to apply iso setting (-110)
Bluetooth: hci0: HCI Enhanced Setup Synchronous Connection command is advertised, but not supported.
```

Attempts to pair any device fail. `bluetoothd` logs `Rejected (0x0b)` on mode / privacy requests.

## Diagnosis

- The chip enumerates (`usb 5-1: Manufacturer: MediaTek Inc.`, SerialNumber present).
- Firmware loads (`HW/SW Version: 0x008a008a, Build Time: 20260224…`).
- Setup completes with an exceptionally long duration (`Device setup in 2466912 usecs`).
- The failing command, `0xfd98`, is a MediaTek vendor-specific HCI command for Isochronous (LE Audio) channel setup. It times out at 2 seconds.
- The chip remains stuck in a half-initialized state. `bluetoothd` cannot register the controller because the controller index is invalid.

Root cause appears to be the MT7921 firmware's ISO setup path. On PS5 OS the vendor driver silently handles this; on Linux the generic `btusb` emits the error and gives up.

## Workaround

Issuing `hciconfig hci0 reset` after boot forces a HCI-level reset. The chip comes back with a valid BD address and `UP RUNNING PSCAN` state. `hciconfig hci0 up` then brings the interface online.

The [`systemd/ps5-bt-reset.service`](../systemd/ps5-bt-reset.service) unit automates this: it waits 2 seconds after `bluetooth.service` starts, runs the reset, and brings the interface up. The 2-second delay lets `bluez` finish its initial probe attempt (which is what emits the 0xfd98 timeout in `dmesg`); without it, our reset races the kernel's own setup path.

## Verification

After installing the service and rebooting:

```bash
hciconfig hci0
```

Expected:

```
hci0:   Type: Primary  Bus: USB
        BD Address: 9C:37:CB:XX:XX:XX  ACL MTU: 1021:6  SCO MTU: 240:8
        UP RUNNING PSCAN
```

Journal confirmation:

```bash
systemctl status ps5-bt-reset.service
```

Should show `Active: inactive (dead)` with recent `ExecStart` success — oneshot units go inactive after completing.

## What this does NOT fix

- **Warm-reboot BT death**: a `kexec` warm reboot leaves the chip in a state where even this reset cannot recover it. See [03-warm-reboot-bt.md](03-warm-reboot-bt.md).
- **DualSense bulk-OUT saturation**: heavy haptic / adaptive-trigger write load can still saturate the chip's BT bulk OUT endpoint and cause mid-game disconnects. Workaround: disable in-game vibration, or use USB-C cable.

## Open questions

If you have deeper MediaTek firmware knowledge and can decode the 0xfd98 ISO payload shape, a proper patch belongs in `btusb.ko` or firmware, not in a userspace reset. PRs welcome.
