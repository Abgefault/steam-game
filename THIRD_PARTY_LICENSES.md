# Third-Party Licenses & Asset Provenance

## Engine

**Godot Engine 4.7.1 (stable)** — MIT License. © Juan Linietsky, Ariel Manzur
and the Godot Engine contributors. https://godotengine.org

The exported game bundles the Godot runtime (export template) as permitted by
the MIT license. Godot's full license and third-party component notices are
distributed with the engine and available at
https://github.com/godotengine/godot/blob/master/LICENSE.txt and
https://godotengine.org/license.

## PBR texture library (CC0)

The materials under `assets/textures/` are from **ambientCG**
(https://ambientcg.com), published under **Creative Commons CC0 1.0 Universal**
(public-domain dedication — free for commercial use, no attribution required;
attribution given here as a courtesy and provenance record).

Downloaded 2026-07-19 as `<AssetID>_1K-JPG.zip` from
`https://ambientcg.com/get?file=<AssetID>_1K-JPG.zip`; only the Color,
NormalGL and Roughness maps are shipped:

| AssetID | Used for |
|---|---|
| Concrete034 | Production/warehouse floors, grime patches |
| WoodFloor051 | Store floor, shelves, counters, desk |
| Metal030 | Machine bodies, fixtures, van, conveyor rails |
| PaintedMetal004 | Red pallet-rack steel |
| DiamondPlate006C | Machine service platforms, rack shelves |
| Road007 | Street asphalt |
| PavingStones128 | Sidewalk |
| Bricks097 | Neighboring building exteriors |
| Cardboard004 | Containers, product/stock boxes |
| Plaster001 | Interior walls |
| CorrugatedSteel007A | Ceiling deck |
| Rubber004 | Conveyor belts |
| Carpet016 | Office floor |
| Metal009 (2K) | Machine bodies (brushed steel) |
| Metal012 (2K) | Stainless tanks, lab bench, counter tops |
| Plastic010 | Analyzer housings, plastic details |
| Facade006 | Glass office towers (city) |
| Facade012 | Distant lit office windows (city skyline) |
| Facade018A | Brick mixed-use buildings (city) |
| Facade019A | Concrete/glass towers (city) |
| Concrete046 | Building parapets, curbs, planters |
| RoofingTiles013A | Roof surfaces |

License text: https://creativecommons.org/publicdomain/zero/1.0/

## Original game assets

All remaining assets are **original**, created for this project:

- **Audio** — every sound and music loop is procedurally synthesized by
  `tools/generate_audio.py` (pure Python standard library, no samples). Output
  lives in `assets/audio/*.wav`. There is no sampled, recorded, or licensed
  audio in the project.
- **3D models & environments** — built procedurally at runtime from Godot
  primitive meshes (`scripts/world/*.gd`, `scripts/world/facility_builder.gd`)
  using the CC0 materials above. No imported model files.
- **Sprites/decals** — `assets/textures/plant/leaf.png` (stylized leaf) and
  `assets/textures/hazard/color.jpg` (hazard stripes) are original, generated
  procedurally by `tools/generate_sprites.py`.
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
