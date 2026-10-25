# sysctl rationale

Each setting in [`sysctl/99-ps5-gaming.conf`](../sysctl/99-ps5-gaming.conf) explained with the reason it is tuned and the trade-off involved.

## Memory

### `vm.swappiness=10` (default 60)

Controls how aggressively the kernel moves anonymous pages to swap. Default 60 is tuned for mixed server workloads where swap is desirable. On a gaming desktop with 14 GiB RAM and a 7 GiB zram, pushing to swap means decompressing on fault — latency spike during gameplay. Value 10 reserves swap for genuine pressure.

**Trade-off**: on long sessions with heavy multitasking the kernel may keep more idle anonymous pages in RAM. Harmless on a dedicated gaming system.

### `vm.vfs_cache_pressure=50` (default 100)

Rate at which the kernel reclaims directory and inode cache. Default 100 reclaims as aggressively as page cache. 50 keeps FS metadata cache around longer, which makes repeated file open calls faster — relevant for game asset streaming.

**Trade-off**: slightly higher metadata RAM footprint, usually under 100 MiB.

### `vm.dirty_ratio=10` and `vm.dirty_background_ratio=5` (defaults 20 / 10)

Thresholds for when dirty pages (written but not yet flushed) start being written back. Defaults allow very large dirty page accumulation on 14 GiB RAM — up to 2.8 GiB. When the flush eventually happens it stalls I/O.

Lower thresholds mean more frequent, smaller flushes. Avoids multi-second I/O freezes during saves, shader cache dumps, or Steam downloads that complete during gameplay.

**Trade-off**: slightly higher sustained disk write activity. On SSD this is negligible.

## Network

### `tcp_congestion_control=bbr` + `default_qdisc=fq` (defaults cubic + fq_codel)

BBR (Google, 2016) uses measured bandwidth and RTT instead of packet loss as a congestion signal. On WiFi — where packet loss can be high but not indicative of congestion — this consistently outperforms CUBIC in both throughput and tail latency.

`fq` is the pacing-aware queue discipline BBR requires to work optimally.

Requires the `tcp_bbr` kernel module (see [`modules-load.d/bbr.conf`](../scripts/apply-all.sh) step 2).

**Trade-off**: none practical. BBR has been default on Google backbone for years.

### `rmem_max` / `wmem_max=16777216` (default ~200 KB)

Maximum socket receive and send buffers. BBR on a 1 Gbps link can want much more than the default. Capping low leaves BBR unable to open its sending window; symptoms include slow Steam downloads despite fast WiFi.

### `rmem_default` / `wmem_default=2097152` (default ~200 KB)

Starting buffer size for every socket. UDP in particular benefits — multiplayer game sockets rarely raise their buffers themselves, so the starting size is often the effective ceiling.

### `netdev_max_backlog=5000` (default 1000)

Depth of the per-CPU packet queue between the NIC and the IP stack. On gigabit WiFi under burst the default 1000 can drop packets.

## inotify

### `max_user_watches=524288` (default 65536)

Each Proton wine prefix, Steam library, and background sync tool consumes watches. On a system with multiple Proton prefixes the default 65 k is exhausted mid-session; symptoms include file-change notifications stopping (Steam library not refreshing, game config not reloading).

Steam officially recommends 524288.

### `max_user_instances=1024` (default 128)

Number of inotify descriptors per user. Multiple watchers (Steam, DE, Flatpak portal) need enough to coexist.
