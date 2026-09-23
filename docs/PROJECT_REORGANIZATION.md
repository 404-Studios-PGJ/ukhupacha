# Project Reorganization

## FILES MOVED

- `res://Playground.tscn` -> `res://tests/playground/Playground.tscn`
- `res://player/player.tscn` -> `res://actors/player/player.tscn`
- `res://player/scripts/player.gd` -> `res://actors/player/scripts/player.gd`
- `res://player/scripts/player.gd.uid` -> `res://actors/player/scripts/player.gd.uid`

## FILES COPIED

- Complete, hierarchy-preserving byte copies of `p1`, `pONE1`, `pONE2`, and
  `pONE3` to `res://assets/characters/player/`.
- `directional_animations.json` and `DIRECTIONAL_EXTRACTION_REPORT.md` to
  `res://docs/art_pipeline/player/`.

The four review images remain at their source location; none were placed under
`res://assets/`.

## DIRECTORIES CREATED

- `res://actors/player/scripts/`
- `res://assets/characters/player/{p1,pONE1,pONE2,pONE3}/`
- `res://tests/playground/`
- `res://docs/art_pipeline/player/`

## REFERENCES UPDATED

- `project.godot`: main scene now points to
  `res://tests/playground/Playground.tscn`.
- Playground's Player instance now points to `res://actors/player/player.tscn`.
- Player's attached script now points to `res://actors/player/scripts/player.gd`.

## PLAYER SCENE STATUS

PASS. `res://actors/player/player.tscn` loads in a Godot 4.7.2 headless
three-frame smoke test (exit code 0), and the Player script remains attached.
Gameplay code was not redesigned or changed.

## PLAYGROUND STATUS

PASS. `res://tests/playground/Playground.tscn` loads in a Godot 4.7.2
headless three-frame smoke test (exit code 0). It remains the configured main
scene.

## PNG COUNT

5,700 validated directional PNGs:

- `p1`: 216
- `pONE1`: 2,580
- `pONE2`: 2,600
- `pONE3`: 304

The families remain separate and their internal hierarchies and filenames were
preserved.

## HASH VALIDATION

PASS. SHA-256 manifests for all 5,700 source and destination PNGs are
identical. Source assets were read only; no image processing was performed.

## GODOT IMPORT STATUS

Godot 4.7.2 completed a project-local import. It generated 5,700 destination
`.import` sidecars and cache entries itself; no source `.import` files or
`.godot` cache data were copied. The existing project default texture filter is
nearest-neighbor (`textures/canvas_textures/default_texture_filter=0`).

## BROKEN REFERENCES

None detected. Searches found no remaining references to the old Player scene,
Player script directory, or Playground path. Editor validation and both scene
smoke tests completed with exit code 0.

## DUPLICATES RETAINED

`res://player/sprites/mc_p1_boxr_v01_base.png` remains in place because the
Player scene still references it. It is a 512x512 legacy 8x8 sprite sheet; no
byte-identical equivalent exists among the imported directional `p1` strips.
The reference was intentionally retained.

## NOT VERIFIED

- No interactive visual gameplay test was performed.
- The sandbox prevented writes to `user://logs` and editor settings outside the
  project, and prevented Godot's local editor TCP listener. These environment
  warnings did not affect the successful project/scene load exit codes.
- No SpriteFrames, AnimatedSprite2D animation integration, FPS assignment, or
  gameplay changes were performed.
