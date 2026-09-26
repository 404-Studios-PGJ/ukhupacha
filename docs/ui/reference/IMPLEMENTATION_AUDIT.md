# Existing UI implementation audit

Audited before the reference visual refactor against the five approved mockups, JSON layouts, geometry audit, and runtime asset manifest.

| File / responsibility | Classification | Evidence and decision |
|---|---|---|
| `ui/ui_flow.gd` | KEEP | Owns the single UIFlow instance, player lookup and binding, modal switching, Tab/Esc, input and tree pause restoration, focus restoration, restart signal contract and ending/death navigation. Its behavior is independent of the old visual language. |
| `ui/hud.gd` | REFACTOR | Signal subscriptions, initial `get_hud_state()` read, and dynamic values remain. Old rails, tiny bars and `HybridGeometry` equipment glyphs need asset backed replacements at JSON coordinates. |
| `ui/equipment_menu.gd` | REFACTOR | Preserve discovery filtering, player binding, signal driven equipment confirmation and graceful missing API behavior. Replace visual construction, slot geometry and old list placement. |
| `ui/menu_screen.gd` | REFACTOR | Keep action routing and focus behavior across main, pause, controls, death and ending. Replace main/pause geometry and button surfaces; retain utility screens with simple styling. |
| `ui/puzzle_terminal.gd` | REFACTOR | Keep evidence selection, relation submission, incorrect feedback, retry, close and lock restoration. Replace all artistic panels/icons with approved PNGs. Retain only relation shafts and arrowheads as geometry. |
| `ui/ui_build.gd` | REFACTOR | `screen`, `place`, `state` and `input_enabled` are useful. Old `panel`, `button`, `icon`, `patch`, `rule`, `header` and `footer` create obsolete style or layout and must not be used for approved screens. |
| `ui/ui_assets.gd` | REFACTOR | Central texture lookup and color palette remain useful. Most paths refer to deleted legacy PNGs and must be replaced with the approved 36 file set. |
| `ui/hybrid_geometry.gd` | REMOVE | Its architecture, title, pause, helix, weapon and shield drawing consists entirely of obsolete decorative primitives. No approved visual depends on it. |
| `ui/theme/ukhupacha_theme.tres` | REFACTOR | Keep a shared fallback font, palette and utility control styling. Remove asset styleboxes tied to deleted PNGs and artistic `StyleBoxFlat` surfaces from reference screen rendering. |
| `ui/theme/ink.gdshader` | REFACTOR / KEEP IF USEFUL | The shader remaps source luminance to a target ink color, which can approximate compositor tint without changing PNG bytes. Its old shared material handling must be checked per asset. |
| `.tscn` screen roots | KEEP / REFACTOR | Existing script identities and scene paths are behavior contracts. Root scene files can carry approved visual nodes; runtime construction may still host dynamic labels and hit areas. |

`docs/ui/legacy/` is historical context only. The approved JSON supplies exact coordinates, draw order, tint, source asset and nine patch margins. HUD world placeholders are excluded; relation shafts and arrowheads are the only artistic runtime geometry retained.
