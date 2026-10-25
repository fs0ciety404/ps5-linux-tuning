# ps5-linux-tuning

System-level tuning + fixes for PlayStation 5 running Linux via [soniciso1 ps5-linux-loader fork](https://github.com/soniciso1/ps5-linux-loader) and companion scene chain.

**Scope**: configuration files, systemd units, udev/modprobe rules and shell scripts only. Zero binaries, zero firmware, zero Sony IP.

## Target setup

| Component | Value |
|-----------|-------|
| Console | PS5 Slim CFI-2016 (B01Y) |
| PS5 firmware | 13.60 (via Relapse jailbreak chain) |
| OS | Ubuntu 26.04 LTS |
| Kernel | 7.1.7 (scene custom) |
| WiFi/BT drivers | MediaTek MT7921 patched via [WizGery/ps5-mediatek-fixes](https://github.com/WizGery/ps5-mediatek-fixes) |
| GPU driver | Mesa RADV 26.2.5+ |
| Boot chain | Relapse + ps5-linux-loader.elf (kexec-based) |

Not tested on PS5 original (CFI-10xx) or PS5 Pro. Should mostly apply but PCI topology differs — verify BT fix section before trusting.

## What this repo gives you

| Area | Benefit |
|------|---------|
| `sysctl` | VM pressure, dirty page flush, TCP BBR, UDP buffers, inotify watches |
| systemd | Auto-reset of MediaTek BT chip after boot (works around 0xfd98 timeout) |
| modprobe | Blacklist absent Marvell driver + btusb autosuspend disable |
| udev | Hide ghost BT HID interface + prevent BT USB autosuspend |
| env | Mesa shader cache 5GB system-wide |
| scripts | Idempotent apply, full rollback, state check |

## Quick start

```bash
git clone https://github.com/<you>/ps5-linux-tuning
cd ps5-linux-tuning
sudo ./scripts/apply-all.sh
# reboot to verify boot time improvement
./scripts/check-state.sh
```

Rollback at any time:

```bash
sudo ./scripts/rollback.sh
```

Everything is reversible via editing `/etc/sysctl.d/99-ps5-gaming.conf` or unmasking services. No binary patches, no kernel rebuild.

## Known issues

See [docs/05-known-issues.md](docs/05-known-issues.md).

Short list:
- Warm reboot (kexec) **breaks** MediaTek BT until cold power cycle + jailbreak re-chain. Avoid warm reboot if BT is in use.
- GDM login screen color banding on some monitors (mitigated via autologin or `maxbpc=8` in `monitors.xml`).
- DualSense BT disconnects under heavy haptic/trigger write load (bulk OUT saturation). Workaround: disable in-game vibration or use USB-C cable.

## Benchmarks

See [benchmarks/](benchmarks/). Community contributions welcome via PR using [TEMPLATE.md](benchmarks/TEMPLATE.md).

Reference external results:
- [Digital Foundry: PS5 Linux Steam games close to native console performance](https://videocardz.com/newz/ps5-linux-tested-steam-games-come-close-to-native-console-performance)
- [Notebookcheck coverage](https://notebookcheck.net/Linux-on-PS5-benchmarked-with-PlayStation-games-impressing-on-Steam-Machine-alternative.1289679.0.html)

## Documentation

- [docs/01-sysctl-rationale.md](docs/01-sysctl-rationale.md) — why each sysctl value
- [docs/02-bluetooth-fix.md](docs/02-bluetooth-fix.md) — 0xfd98 timeout root cause + workaround
- [docs/03-warm-reboot-bt.md](docs/03-warm-reboot-bt.md) — kexec vs MediaTek chip state
- [docs/04-boot-time.md](docs/04-boot-time.md) — 4-second boot shave via wait-online disable
- [docs/05-known-issues.md](docs/05-known-issues.md) — open items + partial workarounds

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Benchmark reports, additional tuning, and reproductions on other PS5 revisions are especially welcome.

## Credits

- [fs0ciety404/ps5-relapse](https://github.com/fs0ciety404/ps5-relapse) — jailbreak chain
- [soniciso1/ps5-linux-loader](https://github.com/soniciso1/ps5-linux-loader) — Linux boot payload
- [WizGery/ps5-mediatek-fixes](https://github.com/WizGery/ps5-mediatek-fixes) — MT7921 WiFi/BT driver patches
- Scene PS5 Discord community

This repo does not redistribute any upstream code. Follow each project's install instructions.

## License

MIT. See [LICENSE](LICENSE).

## Disclaimer

Running Linux on a jailbroken PS5 is unsupported by Sony. The author assumes zero liability for console state, warranty, data loss, or hardware damage. Scripts here operate on userspace Linux config only, never on PS5 firmware or internal NVMe. Do not run on hardware you cannot afford to re-chain or power-cycle.
