# Contributing

## What is welcome

- Reproductions on other PS5 revisions (CFI-10xx, CFI-20xx variants, PS5 Pro).
- Benchmarks using [benchmarks/TEMPLATE.md](benchmarks/TEMPLATE.md).
- Fixes or better workarounds for anything in [docs/05-known-issues.md](docs/05-known-issues.md).
- Documentation improvements, Italian/English parity, typo fixes.
- Additional sysctl or systemd tunings — with an explanation of why, not just what.

## What is not accepted

- Binary blobs of any kind (firmware, compiled drivers, Mesa builds).
- Scene exploit chain code — link to upstream repos instead.
- Scripts that touch the internal M.2 or PS5 firmware.
- "Add tuning X because distro Y uses it" — needs rationale and ideally a before/after measurement.
- Anything that strips the disclaimer in the README.

## Opening a PR

1. Fork, branch, change.
2. Run `./scripts/check-state.sh` after `apply-all.sh` to verify your change still passes.
3. If adding a sysctl or systemd unit, update `docs/` with rationale and update `check-state.sh` to verify it.
4. One topic per PR.

## Opening an issue

Include:
- PS5 model and firmware.
- Linux kernel and Ubuntu version.
- `uname -a`, `lsusb`, `lspci -nn | grep -i mediatek`, relevant `dmesg` lines.
- What you expected, what happened.

## Code style

Shell scripts: `set -euo pipefail`, no unquoted variable expansion, idempotent.

Config files: comment every setting with its rationale. "Set to X" is not a comment; "set to X because Y" is.

Markdown: wrap near 100 columns in docs, no wrap in tables.
