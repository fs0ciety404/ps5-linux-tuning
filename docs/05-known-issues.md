# Known issues

Open items on this setup, with best-known workarounds. PRs welcome.

## Bluetooth

### Chip stuck DOWN after cold boot

**Fixed** by [`ps5-bt-reset.service`](../systemd/ps5-bt-reset.service). See [02-bluetooth-fix.md](02-bluetooth-fix.md).

### Chip dead after warm reboot (kexec)

**Not fixed.** See [03-warm-reboot-bt.md](03-warm-reboot-bt.md). Workaround is to not warm-reboot when BT is needed afterward.

### DualSense in-game disconnects

Only during active gameplay, specifically with games that drive haptics / adaptive triggers / lightbar frequently (DualSense native support via `hid-playstation`). Not reproduced during desktop use.

Hypothesis: the chip's single bulk-OUT endpoint for ACL is being saturated by the HID feature reports. PS5 OS reportedly polls at 250+ Hz, while Linux `hid-playstation` is capped at ~125 Hz, so the headroom is tighter.

Workarounds:
- Disable in-game vibration + adaptive triggers.
- Use USB-C cable (bypasses BT entirely).
- Set `/sys/class/bluetooth/hci0/power/control` to `on` (already in [`udev/99-ps5-bt-fantasma.rules`](../udev/99-ps5-bt-fantasma.rules)).

### Classic BT polling cap

Linux Classic BT polling tops out around 125 Hz, versus PS5 OS which can go higher via vendor driver. Not fixable without a BT stack patch.

## Display

### GDM login screen color banding

Partial banding visible on first login with some HDMI monitors. Caused by GDM X session negotiating 10 bpc but the display not supporting it cleanly through the loader's video path.

Partial workaround: force `maxbpc=8` in `/var/lib/gdm3/.config/monitors.xml`.
Full workaround currently used in this setup: GDM autologin, which bypasses the login screen entirely.

A proper fix would be an Xorg config forcing `-depth 24` on the GDM X server. `xserver-xorg` is not installed on the base image shipped by soniciso1.

### No HDR output

RADV does not expose HDR to Wayland on this kernel. Not a PS5-specific issue — upstream.

### No 4K @ 120 Hz over the loader video chain

Tested only up to 4K@60 and 1080p@120. Loader `video=` cmdline uses PS5 display engine with DP output; 4K@120 negotiation does not complete. Not investigated.

## Storage

### Internal M.2 untouched

The internal NVMe is excluded from any writes by project policy. The user-facing Linux root lives on an external USB SSD. If you want to install to the internal M.2, this repo does not help you and the author will not advise on it.

### UASP vs usb-storage BOT

Some external enclosures expose both UAS and BOT modes. UAS is faster but some chipsets misbehave on this kernel; symptom is multi-minute dmesg storms of `uas_eh_abort_handler`. If seen, add the enclosure's vendor:product to `usb-storage.quirks=VVVV:PPPP:u` on cmdline to force BOT.

## Audio

### No Tempest Engine

PS5's dedicated audio DSP is not accessible to Linux. All audio runs on the x86 cores via PipeWire + ALSA, with no 3D audio hardware acceleration.

### Game dialogue stereo

Some Proton games route 5.1 by default and no dialogue center channel is reproduced on stereo output. Set in-game audio to Stereo in CP2077 and most other titles.

## Jailbreak chain

### Loses chain on hard reboot

Expected. Any `poweroff` requires re-running Relapse + loader to get back into Linux. There is no persistence of the kernel exploit on this chain.

### `ps5-stage-firmware.service` dependency cycle (fixed)

Historically this unit had `Before=` relationships that formed a cycle with `systemd-sysctl`, `systemd-modules-load`, and `apparmor`, breaking boot. Fixed in later soniciso1 builds; if you encounter it on an older image, the fix is to remove `Before=sysinit.target` and let the unit be ordered by its natural `After=` only.
