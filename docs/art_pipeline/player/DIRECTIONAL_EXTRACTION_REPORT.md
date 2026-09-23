# Directional Extraction Report — Phase 2B

## Authoritative direction mapping

| Neutral Phase 2A row | Approved direction |
|---|---|
| DIR_A | down |
| DIR_B | up |
| DIR_C | right |
| DIR_D | left |

This human-approved mapping was applied verbatim to every family. No direction was inferred, reordered, mirrored, or synthesized.

## Processing summary

- Families processed: p1, pONE1, pONE2, pONE3.
- Phase 1 blocks processed: 1425.
- Expected directional strips: 5700 (one each for down, up, right, left).
- Actual directional strips: 5700.
- pONE3 identity: pONE3 remains authoritative user-supplied metadata for the legacy `comprimir/generated` composites; no source files were renamed.

## Per-family counts

| Family | Composites | Animations | Strips |
|---|---:|---|---:|
| p1 | 9 | stand, push, pull, jump, walk, run | 216 |
| pONE1 | 129 | draw_sheath, parry, dodge, hurt, dead | 2580 |
| pONE2 | 130 | idle, move, crouch, retreat, lunge | 2600 |
| pONE3 | 19 | slash1, slash2, trusty, shield_bash | 304 |

## Frame-count distribution

| Frames per strip | Strip count |
|---:|---:|
| 1 | 3144 |
| 2 | 624 |
| 3 | 552 |
| 4 | 1344 |
| 6 | 36 |

## Pixel-integrity validation

Every output was saved as a direct rectangular crop of its mapped 64-pixel-high source row, reopened, and compared byte-for-byte in RGBA against that source row. This verifies source pixels, alpha, row choice, original frame order, and absence of interpolation.

## Structural inconsistencies and errors

- Structural inconsistencies: none.
- Files requiring human review: none; representative validation sheets are supplied for confirmation only.
- Source files modified: 0 (SHA-256 pre/post comparison of all 1425 Phase 1 animation blocks).

## Review samples

Four representative-only sheets appear in `review/`, labeled DOWN, UP, RIGHT, and LEFT. They are enlarged 2× with nearest-neighbour scaling solely for visual validation.

No individual frame files, Godot resources, or game changes were created.
