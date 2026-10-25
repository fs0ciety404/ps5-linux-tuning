# Benchmark report template

Copy this file into `benchmarks/<game>-<yyyymmdd>-<handle>.md` and fill in.

## Setup

- PS5 model + firmware:
- Linux kernel version:
- Mesa version (`glxinfo | grep "OpenGL version"`):
- Proton version:
- `scripts/check-state.sh` all green? (yes/no)
- External SSD model + USB port used:

## Game

- Title + Steam appid:
- Build + patch level:
- Graphics preset tested:
- Resolution:
- Launch options (verbatim):

## Measurement method

- MangoHud? FPS counter? External capture?
- Scene (static, in-game, cutscene, specific area):
- Session length:

## Results

| Setting change | Average FPS | 1% low | VRAM peak | Notes |
|----------------|-------------|--------|-----------|-------|
| baseline       |             |        |           |       |
| with repo tunings |          |        |           |       |

## Delta

Numbers only, no editorializing. If you also compared to vanilla PS5 OS of the same game, say so.

## Attachments

Optional: screenshot of MangoHud frametime graph, config dumps.
