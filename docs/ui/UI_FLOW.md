# UI runtime — reference visual layer

`ui/ui_flow.tscn` is instantiated once per session by its host. It finds the Player through group `player`; `bind_player()` can rebind a replaced Player. HUD reads `get_hud_state()` at startup and connects available health, stamina and equipment signals. Missing Player members are guarded.

The host connects `restart_requested(reason: StringName)` before New Game or Retry. The UI closes its modal, resets `Level1Progress`, emits the request, then rebinds and rereads Player state. Without a connected host, restart returns false and does not partially reset the session. `run/main_scene` is unchanged.

Esc and Tab open or close pause and equipment before GUI navigation consumes them. UIFlow records and restores Player input, tree pause and previous GUI focus. Switching to Controls or Equipment while a modal is open keeps the same lock. Equipment lists only discovered items and waits for `equipment_changed` before confirming a request. PuzzleTerminalView retains record selection, invalid relation feedback, retry, terminal closing and lock restoration.

## Approved visual layer

The five screens read their exact 640×360 composition from `docs/ui/reference/layout/*.json`. `UIBuild.build_reference()` constructs source PNG textures, NinePatchRects and real Labels at JSON positions and z order. `UIAssets` resolves only the 36 approved PNGs in `assets/ui/`. See `docs/ui/reference/RUNTIME_ASSET_MANIFEST.md` and `REFERENCE_UI_IMPLEMENTATION.md` for mapping and visual limits. Runtime screenshots are in `docs/ui/reference/runtime_comparison/`.

HUD leaves gameplay visible. Equipment, pause and puzzle add a translucent dim over gameplay. Main menu uses a neutral temporary background. Obsolete checker/diagonal and world illustration geometry is not rendered. Only puzzle relation shafts and arrowheads remain programmatic artwork. `HybridGeometry` is inert but retained for the existing laboratory's class dependency.

The current fallback font is temporary. Pack texture tint uses `ui/theme/ink.gdshader`; no source PNG bytes or system fonts were copied. Controls, death, ending and interaction dialogs remain utility styled until they have approved reference layouts.

The approved main menu has Begin, Continue and Archive surfaces. Begin uses the existing New Game contract. Continue closes the main menu and resumes the current session; it does not load a save, because no save contract exists. Archive currently opens the existing Controls utility screen. Pause routes Resume to close, Dossier to equipment, Settings to Controls, Restart to Retry, and Exit to main menu.
