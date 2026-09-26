# Approved reference UI implementation

The five approved 640×360 JSON layouts drive the visual layer. `UIBuild.build_reference()` reads each layout, creates texture backed Controls for every `source_asset`, runtime Labels for text, and groups them by `parent_group`. It applies `rect`, `z`, tint, composition, flip flags, and exact `patch_margins`. `UIAssets` resolves each approved source filename to the one runtime PNG in `assets/ui/`. The 36 PNGs are unchanged; Godot generated their `.import` sidecars. Screen root filtering is nearest neighbor.

The existing UIFlow, HUD, equipment, menu, and terminal scripts retain their behavior. Only their visual construction and state display were adapted. Transparent Button hit areas sit over the approved button and slot art, with a thin focus outline for keyboard navigation. No text is baked into PNGs.

## Files and retained logic

- `ui/hud.gd`, `ui/equipment_menu.gd`, `ui/menu_screen.gd`, `ui/puzzle_terminal.gd` and the four Control root `.tscn` files were refactored for the reference layouts. HUD remains a CanvasLayer using `ui/hud.tscn`.
- `ui/ui_flow.gd` retains its session, player, pause, input, focus, reset and navigation contracts. It routes the new Dossier, Continue and Archive hit areas. Continue resumes the current session without a save load operation; Archive currently opens Controls as a utility placeholder.
- `ui/ui_build.gd` remains the shared builder and state helper. Its reference path creates all approved art and text; legacy utility helpers remain for controls, ending, death, dialogs and the lab. Utility rules now use the approved line PNG.
- `ui/ui_assets.gd` remains the central lookup and palette access. Deleted legacy texture paths are removed.
- `ui/hybrid_geometry.gd` is an inert compatibility shell because the existing `ui_lab` script instantiates that class. It draws nothing, and no approved screen instantiates it.
- `ui/theme/ukhupacha_theme.tres` remains the single fallback theme for utility controls, text and focus. Old texture styleboxes were removed; approved screen surfaces come directly from PNG nodes.
- `ui/theme/ink.gdshader` remains in use on texture nodes. It approximates the mockup compositor's grayscale contrast and 62% color blend on the GPU. Source PNG bytes are unchanged.

## Geometry and backgrounds

Only the puzzle A→B and B→C shafts and arrowheads remain programmatic artwork, as permitted by the geometry audit. The HUD world disc, central polygon, checker field, diagonal lines, old plates, Helix motif and weapon silhouettes are gone. HUD displays the actual world. Equipment, pause and puzzle use a simple translucent dim over it. Main menu uses neutral `#1B1D1F` backing until environment art exists.

Every screen UI element with a `source_asset` is rendered through its PNG. The four HUD anomaly points belong to `game_world_placeholder` and are intentionally omitted with that mockup world illustration. Nine patch margins come directly from JSON. The `parent_group` hierarchy and z order are preserved by the reference builder. No coordinate corrections were applied; all approved `rect` values are unchanged.

## State mapping and visual limits

Health, stamina, weapon, shield and tier continue to follow the Player snapshot/signals. Equipment discovery controls slot visibility. The equipment dossier replaces fictional ROOTCUTTER copy with the selected gameplay item; unknown power/reach values display `--`, while shield state displays ON/OFF. The mockup's stat fill art remains visible at reduced alpha as decoration, not a claim of gameplay stats. Puzzle cards use the existing record A/B/C state and retain the existing relation logic; verified marks track the flags. Recovered cultural knowledge remains pending validation rather than adopting fictional mockup copy.

The runtime uses Godot's fallback font. Its glyph shapes, baselines and widths differ visibly from the compositor fonts, especially the serif titles and tiny mono metadata. Tint and nine patch rendering are close but not pixel identical to Pillow. The HUD comparison was captured in the simulated UI lab, with that lab visible behind it; gameplay itself supplies the background in production. The main menu background is intentionally neutral. Controls, death, ending and interaction dialogs remain utility styled because no new approved layouts exist for them.

Runtime comparisons: `runtime_comparison/hud_runtime.png`, `main_menu_runtime.png`, `equipment_menu_runtime.png`, `pause_menu_runtime.png`, and `puzzle_terminal_runtime.png`. They are 640×360. No ±1 px corrections were needed or applied.
