# UKHUPACHA mockup layout metadata

These files are a machine-readable transcription of the current five reference-driven mockups. `ukhupacha_ui_work/generate_mockups.py` is authoritative: coordinates, draw order, source paths, scale factors, nine-slice margins, colors, strings, fonts and text bounds were captured from its compositor calls rather than estimated from screenshots.

## Files

- `hud.json`
- `main_menu.json`
- `equipment_menu.json`
- `pause_menu.json`
- `puzzle_terminal.json`

Each document describes one 640×360 logical-pixel canvas.

## Coordinate convention

- `viewport`: `[640, 360]`
- origin: top-left
- positive X: right
- positive Y: down
- `rect`: `[x, y, width, height]` in logical pixels
- primitive `coordinates`: exact compositor coordinates, retained in addition to the enclosing rect
- text `rect`: the exact Pillow ink bounding box returned for the rendered string, font, anchor and stroke settings; it is not a guessed Control minimum size

For a Godot `Control`, use the rect’s X/Y as the logical anchor offset from its parent’s top-left when parents themselves do not apply coordinate transforms. All current `parent_group` values are logical grouping hints; they are not encoded as coordinate-transforming containers.

## Element schema

Every item in `elements` has the common fields:

```json
{
  "id": "unique_within_screen",
  "category": "asset_composite | text | primitive | background_placeholder",
  "source_asset": "relative/original/pack/path.png or null",
  "rect": [0, 0, 0, 0],
  "z": 1,
  "tint": "#RRGGBB or #RRGGBBAA",
  "scale": [1.0, 1.0],
  "composition": "direct | scaled | nine_slice | tiled | primitive | text",
  "flip_h": false,
  "flip_v": false,
  "godot_node": "suggested Control-derived node",
  "parent_group": "logical_group"
}
```

Additional fields depend on category.

### Asset composites

- `source_asset` is relative to the workspace root and always points to an original downloaded-pack PNG.
- `TextureRect` is suggested for `scaled` or `direct` composites.
- `NinePatchRect` is suggested for `nine_slice` composites.
- `scale` is the target-width/source-width and target-height/source-height ratio. For a nine-slice it is descriptive only; do not uniformly scale the texture by this value.
- `source_dimensions` records the original PNG dimensions for nine-sliced items.
- `patch_margins` records the exact explicit compositor border used on each side. All current nine-slices therefore have `verify_in_godot: false`. If a future entry lacks explicit margins, use `null` and set `verify_in_godot: true`.
- `tint` records the requested palette color. The mockup compositor’s tint operation is a grayscale/contrast conversion blended 62% toward this color; a plain Godot `modulate` will not be pixel-identical. Use these values as design tint metadata or reproduce the compositor tint in a shader/import step if exact appearance is required.
- Pack pixels may also be layered with neighboring elements. Each source-backed draw call has its own entry; layering is expressed by `z`.

### Text

Text entries add:

- `text`: exact rendered string
- `font`: exact font file used by the mockup
- `font_size`: logical-pixel font size
- `alignment`: readable alignment name
- `anchor`: exact Pillow anchor (`null` means its default left anchor)
- `color`
- `stroke_width` and `stroke_color`

The suggested node is `Label`. Godot and Pillow may rasterize the same font differently, so use the compositor position/alignment as authoritative and validate final baselines visually.

### Primitive geometry

Primitive entries add:

- `primitive_type`
- `coordinates`
- `fill_color`
- `outline_color`
- `line_width` where applicable
- `replacement_required`
- `runtime_primitive` where relevant

The suggested node is a custom-drawing `Control`. Puzzle relation shafts and arrowheads have `runtime_primitive: true` and `replacement_required: false`; they are intentionally retained for runtime relation drawing.

### Background placeholders

The repeated 203-cell checker field and diagonal lines are intentionally represented by one `background` entry per screen. That entry describes the base, checker and diagonal parameters without polluting the normal UI hierarchy with 203 rectangle records.

- Equipment, pause and puzzle set `replace_with_dimmed_gameplay: true`.
- Main menu sets `replace_with_final_menu_background: true`.
- HUD sets `hud_gameplay_background: true`.
- HUD’s `world_space_disc` and `world_inner_field` are separately documented placeholders with `include_in_future_ui: false`; they must not become UI nodes in the future HUD.

## Z-order

`z` is a strictly increasing integer in exact compositor draw order. Higher values draw over lower values. It is intentionally screen-local and starts at 1 for the consolidated background placeholder. Text participates in the same sequence, so labels remain above the surfaces that preceded them.

In Godot, this can be reproduced through child order, explicit `z_index`, or both. If logical parent Controls are introduced, ensure their effective canvas ordering does not invalidate the global sequence recorded here.

## Godot reconstruction mapping

| Metadata composition | Suggested Godot node | Reconstruction note |
|---|---|---|
| `scaled` / `direct` | `TextureRect` | Disable filtering for the pixel-art treatment; use explicit rect. |
| `nine_slice` | `NinePatchRect` | Apply the recorded four patch margins and explicit target rect. |
| `text` | `Label` | Load recorded font and size; reproduce anchor/alignment and color. |
| `primitive` relation geometry | custom `Control` | Draw from exact coordinate arrays at runtime. |
| `background_placeholder` | `Control` only during comparison | Replace according to its screen-specific flag. |

No JSON entry selects a replacement asset or changes the approved mockup design.

## Coverage validation

The extraction captured one record for every compositor draw call after consolidating the explicitly exempted checker/diagonal field. Expected and actual non-placeholder element counts are:

| Screen | Asset composites | Text | Runtime primitives | Non-placeholder total |
|---|---:|---:|---:|---:|
| HUD | 19 | 8 | 0 | 27 |
| Main menu | 19 | 10 | 0 | 29 |
| Equipment menu | 29 | 21 | 0 | 50 |
| Pause menu | 20 | 8 | 0 | 28 |
| Puzzle terminal | 25 | 22 | 4 | 51 |

HUD additionally contains three documented placeholders: the consolidated shared background and two temporary game-world shapes. Every other screen contains one consolidated background placeholder. IDs are unique within each file, every asset source resolves to an existing original pack PNG, and every non-placeholder visible component has exactly one JSON entry.
