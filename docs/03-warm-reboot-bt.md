# Warm reboot (kexec) breaks MediaTek BT

## TL;DR

**Do not warm-reboot if you plan to use Bluetooth after.** A `kexec` warm reboot leaves the MediaTek MT7921 Bluetooth chip in a state from which Linux cannot recover without a full hardware power cycle (which also means losing the jailbreak and re-running the Relapse chain).

## Pattern

1. Cold boot via Relapse + `ps5-linux-loader.elf`: BT comes up (after [ps5-bt-reset.service](02-bluetooth-fix.md)).
2. Run `/usr/local/sbin/ps5-linux-warm-reboot.sh` (kexec).
3. New kernel starts, BT device enumerates in lsusb, firmware loads.
4. `dmesg` shows:

   ```
   usb 5-1: device descriptor read/64, error -71
   ```

   `-71` is `-EPROTO` (USB protocol error).
5. `hciconfig hci0 reset` returns success but leaves the chip DOWN.
6. PCI remove + rescan (`echo 1 > /sys/bus/pci/devices/0000:40:00.6/remove` and `echo 1 > /sys/bus/pci/rescan`) makes it worse:

   ```
   pci 0000:40:00.6: BAR 0 [mem size 0x00200000 64bit pref]: can't assign; no space
   xhci_hcd 0000:40:00.6: init 0000:40:00.6 fail, -517
   xhci_hcd 0000:40:00.6: probe with driver xhci_hcd failed with error -16
   ```

   The XHCI controller behind the BT device fails to re-probe. From here only a full power cycle recovers.

## Likely cause

The MediaTek chip's USB PHY sits on an XHCI controller inside the PS5 APU south complex. On a warm reboot, the APU's south complex is not power-cycled: the XHCI controller comes up with its BAR allocation from the previous boot, which is no longer aligned with the fresh PCI probe. The chip itself ends up in a half-reset state that neither `hciconfig reset` nor PCI unbind/rebind clears, because the controller feeding it is stuck.

A full `poweroff` plus Sony boot takes the APU south complex through its full reset and restores a clean state.

## What to do instead

| Need | Action |
|------|--------|
| Load a new kernel for testing | Warm reboot is fine. Accept BT loss until next cold boot. |
| Use BT in the next session | Cold shut down (`poweroff`), let PS5 boot its own OS, re-run jailbreak + loader chain. |
| Just restart a frozen desktop | Try `systemctl restart gdm` first. Avoid full reboot. |

## Possible mitigation (untested)

If someone wants to investigate: the XHCI driver on Linux has `xhci.quirks` module parameters, including options for not resetting the controller on boot. On PS5 the opposite is wanted — a hard controller reset before probe. A kexec hook that writes to the XHCI controller reset register before handing off might work. Not attempted in this repo.
