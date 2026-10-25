# Boot time tuning

## `NetworkManager-wait-online.service` disable

Default-enabled on Ubuntu. Delays `multi-user.target` until NetworkManager reports an interface is "up and routable". On PS5 Linux, the WiFi driver (MT7921) and association can take 3-5 seconds post-login, during which the service blocks the whole boot.

`systemd-analyze blame` on a stock install shows:

```
4.007s NetworkManager-wait-online.service
```

Disabling it moves network bring-up fully asynchronous — services that genuinely need network wait on `network.target` or do their own probing, which is fine for login managers, Steam, SSH listener, etc.

**Trade-off**: a service that assumes network is up at `multi-user.target` without declaring `Wants=network-online.target` may hit a race. Rare in practice.

Disabled via `systemctl disable NetworkManager-wait-online.service` in [`apply-all.sh`](../scripts/apply-all.sh).

## `systemd-oomd` mask

Default-enabled on Ubuntu 26.04. User-space OOM killer that monitors cgroup pressure and kills processes before the kernel OOM path triggers.

Problems on a gaming desktop:
- Occupies ~50 MiB resident at idle.
- Can target game processes under high memory pressure (CP2077 with full HD textures can genuinely approach the 14 GiB cap).
- Behavior tunable but non-obvious; a kernel OOM is at least predictable.

Masking is more thorough than disabling: it also disables the `.socket` unit that would otherwise re-activate the service on demand.

**Trade-off**: on a real system crunch (memory + swap exhausted) the kernel OOM path runs instead. This may freeze the UI for seconds before resolving. On this hardware a swap-only scenario with 7 GiB zram ought to be sufficient for CP2077-class workloads.

## Not disabled (deliberately)

- `snapd.service`: Firefox and Mesa are Snap packages on Ubuntu 26.04. Disabling snapd breaks the GPU driver and browser.
- `apparmor.service`: Ubuntu's MAC layer. Some scene services rely on it being present.
- `cups.service`: harmless if idle; a user who prints will miss its absence.
