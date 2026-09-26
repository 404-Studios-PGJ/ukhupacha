# Hybrid Discovery v2 final asset manifest

All 37 PNGs are unchanged copies of standalone source sprites. No derived raster asset, baked text, spritesheet, or mockup is included. Paths are relative to `~/Descargas/menus/`.

Abbreviations: `TR` TextureRect, `TB` TextureButton, `TP` TextureProgressBar, `NP` NinePatchRect. “Mod” means Godot `modulate`/`self_modulate` is expected. Every scalable texture marked NP requires visual margin confirmation in Godot: **VERIFY VISUALLY IN GODOT**.

| Final file | Original source path | Pack | Size | Target use | Screens | Node | Mod | NP | Status |
|---|---|---|---:|---|---|---|---|---|---|
| `bars/UI_Flat_Bar01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Bar01a.png` | Essential / Flat | 32×8 | Compact progress outline | HUD | TP/TR | Yes, warm charcoal | Optional | Unchanged |
| `bars/UI_Flat_BarFill01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_BarFill01a.png` | Essential / Flat | 32×3 | Stamina/progress fill | HUD, equipment | TP | Yes, Helix green | No | Unchanged |
| `bars/UI_Flat_BarFill01c.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_BarFill01c.png` | Essential / Flat | 32×3 | HP fill | HUD | TP | Yes, health red | No | Unchanged |
| `bars/UI_Flat_BarFill01d.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_BarFill01d.png` | Essential / Flat | 32×3 | Critical HP alternate | HUD | TP | Yes, dark red | No | Unchanged |
| `bars/UI_Flat_BarFill01e.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_BarFill01e.png` | Essential / Flat | 32×3 | Gold stat/selection fill | Equipment | TP | Yes, gold | No | Unchanged |
| `buttons/UI_Flat_Button01a_1.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Button01a_1.png` | Essential / Flat | 32×32 | Primary normal state | Main, pause, equipment | TB/NP | Yes | Yes | Unchanged |
| `buttons/UI_Flat_Button01a_2.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Button01a_2.png` | Essential / Flat | 32×32 | Primary hover/focus state | Main, pause, equipment | TB/NP | Yes | Yes | Unchanged |
| `buttons/UI_Flat_Button01a_3.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Button01a_3.png` | Essential / Flat | 32×32 | Primary pressed state | Main, pause, equipment | TB/NP | Yes | Yes | Unchanged |
| `buttons/UI_Flat_Button01a_4.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Button01a_4.png` | Essential / Flat | 32×32 | Primary disabled state | Main, pause, equipment | TB/NP | Yes, gray | Yes | Unchanged |
| `buttons/UI_Flat_ButtonPlay01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_ButtonPlay01a.png` | Essential / Flat | 17×16 | New Game/Resume glyph | Main, pause | TR | Yes, light gold | No | Unchanged |
| `buttons/UI_Flat_ButtonCheck01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_ButtonCheck01a.png` | Essential / Flat | 17×16 | Equipped/confirm glyph | Equipment | TR | Yes, light gold | No | Unchanged |
| `buttons/UI_Flat_ButtonCross01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_ButtonCross01a.png` | Essential / Flat | 17×16 | Cancel/destructive glyph option | Menus | TR | Yes | No | Unchanged |
| `panels/UI_Flat_Frame02a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Frame02a.png` | Essential / Flat | 96×64 | Structural panel surface | All screens | NP | Yes | Yes | Unchanged |
| `panels/UI_Flat_Banner03a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Banner03a.png` | Essential / Flat | 64×20 | Tier/compact metadata banner | Equipment | NP | Yes, gold | Yes | Unchanged |
| `panels/UI_TravelBook_Popup01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Popup01a.png` | Book Styles / TravelBookLite | 62×30 | Recovered knowledge surface | Puzzle | NP | Yes, warm charcoal | Yes | Unchanged |
| `slots/UI_Flat_FrameSlot01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_FrameSlot01a.png` | Essential / Flat | 32×32 | Slot normal | HUD, equipment | TB/TR | Yes | No | Unchanged |
| `slots/UI_Flat_FrameSlot01b.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_FrameSlot01b.png` | Essential / Flat | 32×32 | Slot hover/focus | HUD, equipment | TB/TR | Yes | No | Unchanged |
| `slots/UI_Flat_FrameSlot01c.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_FrameSlot01c.png` | Essential / Flat | 32×32 | Slot unavailable/disabled | Equipment | TB/TR | Yes, gray | No | Unchanged |
| `slots/UI_Flat_Select01a_1.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Select01a_1.png` | Essential / Flat | 32×32 | Selected slot frame 1 | HUD, equipment | TR | Yes, gold | No | Unchanged |
| `slots/UI_Flat_Select01a_2.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Select01a_2.png` | Essential / Flat | 32×32 | Selected slot frame 2 / v2 still | HUD, equipment | TR | Yes, gold | No | Unchanged |
| `slots/UI_Flat_Select01a_3.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Select01a_3.png` | Essential / Flat | 32×32 | Selected slot frame 3 | Equipment | TR | Yes, gold | No | Unchanged |
| `slots/UI_Flat_Select01a_4.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_Select01a_4.png` | Essential / Flat | 32×32 | Selected slot frame 4 | Equipment | TR | Yes, gold | No | Unchanged |
| `icons/UI_Flat_IconArrow01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_IconArrow01a.png` | Essential / Flat | 16×12 | Relation/navigation arrow | Puzzle, menus | TR | Yes | No | Unchanged |
| `icons/UI_Flat_IconCheck01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_IconCheck01a.png` | Essential / Flat | 17×14 | Valid relation | Puzzle | TR | Yes, green | No | Unchanged |
| `icons/UI_Flat_IconCross01a.png` | `Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites/UI_Flat_IconCross01a.png` | Essential / Flat | 15×15 | Rejected relation | Puzzle | TR | Yes, red | No | Unchanged |
| `icons/UI_TravelBook_IconEnergy01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconEnergy01a.png` | Book Styles / TravelBookLite | 12×14 | Stamina glyph | HUD | TR | Yes, green | No | Unchanged |
| `icons/UI_TravelBook_IconHeart01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconHeart01a.png` | Book Styles / TravelBookLite | 13×10 | HP glyph | HUD | TR | Yes, red | No | Unchanged |
| `icons/UI_TravelBook_IconPause01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconPause01a.png` | Book Styles / TravelBookLite | 10×13 | Pause indicator | HUD/pause entry | TR | Yes, cream | No | Unchanged |
| `icons/UI_TravelBook_IconRestart01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconRestart01a.png` | Book Styles / TravelBookLite | 11×13 | Retry glyph | Pause | TR | Yes, cream | No | Unchanged |
| `icons/UI_TravelBook_IconStar01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconStar01a.png` | Book Styles / TravelBookLite | 12×11 | Discovery/anomaly marker | Main, equipment, pause, puzzle | TR | Yes, gold/purple | No | Unchanged |
| `icons/UI_TravelBook_IconTick01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconTick01a.png` | Book Styles / TravelBookLite | 15×12 | Collected clue/unlock | Puzzle | TR | Yes, green | No | Unchanged |
| `prompts/UI_TravelBook_CommandPress01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_CommandPress01a.png` | Book Styles / TravelBookLite | 5×9 | Keyboard press prompt | HUD | TR | Yes, cream | No | Unchanged |
| `prompts/UI_TravelBook_CommandHold01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_CommandHold01a.png` | Book Styles / TravelBookLite | 9×11 | Keyboard hold prompt | HUD | TR | Yes, cream | No | Unchanged |
| `prompts/UI_TravelBook_GamepadA01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_GamepadA01a.png` | Book Styles / TravelBookLite | 9×8 | Gamepad action prompt | HUD | TR | Yes, light gold | No | Unchanged |
| `decorations/UI_TravelBook_Line01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Line01a.png` | Book Styles / TravelBookLite | 30×2 | Title divider texture | Main | TR | Yes, gold | No | Unchanged |
| `decorations/UI_TravelBook_Marker01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Marker01a.png` | Book Styles / TravelBookLite | 20×14 | Discovery transition marker | HUD, main, equipment, puzzle | TR | Yes, gold/purple | No | Unchanged |
| `decorations/UI_TravelBook_Point01a.png` | `Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Point01a.png` | Book Styles / TravelBookLite | 5×5 | Divider endpoint/detail | Main | TR | Yes, purple | No | Unchanged |

## Geometry and runtime text intentionally excluded

The following v2 elements require no PNG: clipped title plates, dark backdrops, gold rules, status rails, shield and temporary weapon pictograms, Helix orbital diagram, evidence relation lines/nodes/arrowheads, stat tracks/fills, card header colors, feedback backgrounds, and focus outlines. Build these with Control nodes, StyleBoxFlat resources, Line2D, Polygon2D where appropriate, or `_draw()` in a dedicated Control. All titles, menu labels, item data, evidence text, numerical values, and prompt actions are runtime Labels.
