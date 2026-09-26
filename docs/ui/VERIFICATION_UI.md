# Reference UI verification

Godot 4.7.2, logical viewport 640×360. The five approved layouts were rendered at runtime in the simulated `ui_lab` host and compared with `docs/ui/reference/mockups/`.

- Godot project import completed; the subsequent headless project parse reported no GDScript errors.
- Runtime ResourceLoader check: 36/36 approved PNGs exist and load; 36 generated `.import` sidecars are present.
- `ui_lab.run_checks()`: 20/20 passed, including initial Player state, health/stamina/equipment signals, discovery filtering, delayed equipment confirmation, pause/input restoration, missing Player API, New Game/Retry, single HUD, puzzle invalid/retry/close and ending.
- `puzzle_lab.run_checks()`: 29/29 passed.
- Actual Tab and Esc key events opened/closed equipment and pause. Modal state, tree pause and Player input were checked after both transitions; one UIFlow instance remained.
- Direct viewport pointer events hovered an equipment slot, selected `axe`, and activated its Equip badge; the simulated Player and equipment signal both reported `axe`. Keyboard focus plus Enter also selected a slot. The Continue surface closed the main menu while preserving a discovered item and restoring input/pause.
- Runtime screenshots exist for HUD, main, equipment, pause and puzzle at exactly 640×360 in `docs/ui/reference/runtime_comparison/`.
- JSON source assets use TextureRect or NinePatchRect with exact margins. The HUD mockup world placeholder is omitted. The only programmatic artwork on approved screens is puzzle relation shafts and arrowheads.
- No approved scene references deleted legacy PNGs. `project.godot` and the unrelated README files were not edited in this refactor.

The runtime comparisons retain known differences: Godot fallback typography versus the compositor fonts; GPU tint and nine patch scaling versus Pillow; neutral main menu background instead of the mockup checker placeholder; real/simulated gameplay behind HUD and dimmed modals instead of mockup scenery; actual equipment and evidence state in place of fictional copy. No coordinate corrections were applied. See `docs/ui/reference/REFERENCE_UI_IMPLEMENTATION.md` for details.

To repeat in the editor, run `res://tests/interactables/ui_lab.tscn` and evaluate `await get_tree().current_scene.run_checks()`. Run `res://tests/interactables/puzzle_lab.tscn` the same way. The five screen roots can also be opened directly in the editor; visual content is constructed when the scenes run.
