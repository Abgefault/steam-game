# Third-Party Licenses & Asset Provenance

## Engine

**Godot Engine 4.7.1 (stable)** — MIT License. © Juan Linietsky, Ariel Manzur
and the Godot Engine contributors. https://godotengine.org

The exported game bundles the Godot runtime (export template) as permitted by
the MIT license. Godot's full license and third-party component notices are
distributed with the engine and available at
https://github.com/godotengine/godot/blob/master/LICENSE.txt and
https://godotengine.org/license.

## Game assets

All game assets in this repository are **original** and were created for this
project. No third-party art, audio, fonts, or models are used.

- **Audio** — every sound and music loop is procedurally synthesized by
  `tools/generate_audio.py` (pure Python standard library, no samples). Output
  lives in `assets/audio/*.wav`. There is no sampled, recorded, or licensed
  audio in the project.
- **3D models & environments** — built procedurally at runtime from Godot
  primitive meshes (`scripts/world/*.gd`, `scripts/world/facility_builder.gd`).
  No imported model files.
- **Icon** — `assets/icon.svg`, an original vector drawn for this project.
- **UI** — built in code via `scripts/ui/ui_kit.gd`; fonts are Godot's built-in
  default font (covered by the engine's license above).
- **Game data** — `data/*.json`, authored for this project via
  `tools/generate_data.py`. All product, district, event, machine, strain, and
  character names are fictional and original; no real trademarks are used.

## Tooling (development only, not shipped)

- **Python 3** standard library — used by the data/audio generator scripts.
  Not part of the shipped game.

If any third-party asset is ever added, record its source URL, version,
license, and any required attribution here, and confirm the license permits
commercial redistribution before use.
