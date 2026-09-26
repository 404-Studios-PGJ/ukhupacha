# Geometry Audit — Current Final Mockups

## Scope and classification rules

This audit covers the five PNGs currently in `ukhupacha_ui_work/mockups/`. It was made from the exact compositor instructions in `generate_mockups.py`; the images were not changed.

- **A. ORIGINAL_ASSET** means a pack PNG appears at its native pixels, with no scaling, tint, crop, tiling or layering transformation.
- **B. ASSET_COMPOSITE** means pack PNG pixels are present, but were scaled, nine-sliced, tinted, alpha-adjusted, or layered with other assets.
- **C. TEXT** means text rendered with local fonts.
- **D. PRIMITIVE_GEOMETRY** means pixels made by Pillow drawing operations or by a programmatic solid fill.
- **E. BACKGROUND_PLACEHOLDER** means temporary non-UI scenery/background. Where a placeholder was itself drawn with primitives, it is reported as **D+E**, not hidden under E.

Strict consequence: there are **no A entries**. Every pack image in the five mockups was at least scaled and/or tinted, so all asset-derived visuals are B. Text glyphs, including their optional text stroke, are C rather than D. Borders, bevels, corner ornaments, bar outlines and separators contained inside pack PNGs are B.

## Shared programmatic background field

Every screen starts with the same programmatic field. Accent color changes by screen. This field is **D+E** and is visible wherever later opaque assets do not cover it.

| ID | Exact primitive specification | Type | Fill / stroke | Layer | Purpose | Noticeable | Replace with pack UI asset? | Suggested replacement type |
|---|---|---|---|---|---|---|---|---|
| BG-1 | `(0, 0, 640, 360)` | solid canvas fill | fill `#1b1d1f`; no outline | z0 | temporary backing | Yes, at screen edges and gaps | No; ultimately replace with game/menu background content, not a UI asset | background/environment art |
| BG-2 | 203 rectangles, each `23×23`; top-left coordinates are the row lists below | filled rectangles | fill `#202426`; no outline | z1 | checker/module texture | Yes | No; it is a placeholder field, not functional UI | background/environment art or pack panel field if retained |
| BG-3 | nine visible clipped 1 px diagonal lines, exact visible bounds listed below | line | stroke is the screen accent; no fill | z2 | atmospheric/technical texture | Yes | Usually no; replace only if this menu background remains abstract | separator / stripe / background ornament |

### BG-2 exact rectangle coordinates

Pillow rectangle endpoints were `(x, y)` through `(x+22, y+22)`, inclusive, hence each rasterized rect is `23×23`. Every coordinate below is an individual visible-before-occlusion primitive. Later assets cover portions of this set.

- `y=0,48,96,144,192,240,288,336`: `x=0,48,96,144,192,240,288,336,384,432,480,528,576,624`
- `y=24,72,120,168,216,264,312`: `x=24,72,120,168,216,264,312,360,408,456,504,552,600`

That is 8×14 + 7×13 = **203 rectangles**. The exact rect for each pair is `(x, y, 23, 23)`.

### BG-3 exact visible line bounds

The source segment is `(x,360) → (x+180,0)`. Canvas clipping produces these exact visible pixel bounds:

| Line | Bounding rect `(x,y,w,h)` |
|---|---|
| 1 | `(0, 0, 141, 282)` |
| 2 | `(41, 0, 180, 360)` |
| 3 | `(121, 0, 180, 360)` |
| 4 | `(201, 0, 180, 360)` |
| 5 | `(281, 0, 180, 360)` |
| 6 | `(361, 0, 180, 360)` |
| 7 | `(441, 0, 180, 360)` |
| 8 | `(521, 122, 119, 238)` |
| 9 | `(601, 282, 39, 78)` |

The tenth requested line begins at `x=680` and is entirely outside the 640×360 canvas, so it is not visible and is excluded. BG-3 color is `#4f9b68` on HUD, pause and puzzle; `#76518f` on main menu; `#c99745` on equipment.

---

## `hud.png`

### A. ORIGINAL_ASSET

None.

### B. ASSET_COMPOSITE

Every item below was scaled and/or tinted from a named pack PNG.

| Visible component | Rect `(x,y,w,h)` | Source |
|---|---|---|
| left vitals frame | `(10,10,212,72)` | Flat `Frame03a` nine-sliced, warm-charcoal tint |
| heart symbol | `(22,20,26,20)` | TravelBook `IconHeart01a`, red tint |
| HP bar frame | `(52,18,148,18)` | Flat `Bar07a`, cream tint |
| HP fill | `(57,24,118,6)` | Flat `BarFill01d`, red tint |
| energy symbol | `(24,49,22,24)` | TravelBook `IconEnergy01a`, green tint |
| stamina bar frame | `(52,47,148,18)` | Flat `Bar07a`, cream tint |
| stamina fill | `(57,53,91,6)` | Flat `BarFill01c`, green tint |
| right loadout frame | `(458,10,172,72)` | Flat `Frame03a` nine-sliced, warm-charcoal tint |
| weapon slot | `(470,20,46,46)` | Flat `FrameSlot03a`, gold tint |
| weapon star glyph | `(483,31,20,19)` | TravelBook `IconStar01a`, cream tint |
| shield slot | `(545,20,46,46)` | Flat `FrameSlot03a`, purple tint |
| shield star glyph | `(558,31,20,19)` | TravelBook `IconStar01a`, cream tint |
| four anomaly/world points | `(286,144,15,15)`, `(355,129,15,15)`, `(376,218,15,15)`, `(255,229,15,15)` | TravelBook `Point01a`, purple tint |
| interaction popup | `(181,299,278,45)` | TravelBook `Popup01a` nine-sliced, warm-charcoal tint |
| command glyph | `(194,310,15,27)` | TravelBook `CommandPress01a`, light-gold tint |
| interaction marker | `(205,307,38,27)` | TravelBook `Marker01a`, green tint |

### C. TEXT

`86 / 100`; `STAMINA`; `WEAPON`; `SHIELD`; `II`; `03`; `E  ACCESS ARCHIVE NODE`; `HELIX // CLEARANCE REQUIRED`.

### D. PRIMITIVE_GEOMETRY

In addition to shared BG-1/BG-2/BG-3:

| Visual description | Exact rect `(x,y,w,h)` | Primitive | Fill | Outline | Layer | Purpose | Noticeable | Replace with real pack asset? | Suggested type |
|---|---|---|---|---|---|---|---|---|---|
| central dark world-space disc | `(210,78,220,220)` | filled ellipse | `#242b29` | none | z3, behind all HUD assets and anomaly points | temporary gameplay/world mass | Yes | No; replace with actual gameplay view | game-world background, not UI |
| inner rotated field | `(236,86,168,200)` | filled four-point polygon | `#2e3430` | none | z4, above disc, below points/HUD | temporary top-down room/floor suggestion | Yes | No; replace with actual gameplay view | game-world background, not UI |

### E. BACKGROUND_PLACEHOLDER

BG-1/BG-2/BG-3 plus the ellipse and polygon represent a temporary top-down Helix play space. The four purple point assets sit in that placeholder as anomaly/world markers. None represents final game art.

---

## `main_menu.png`

### A. ORIGINAL_ASSET

None.

### B. ASSET_COMPOSITE

| Visible component | Rect `(x,y,w,h)` | Source |
|---|---|---|
| large central cover/backplate | `(27,16,586,328)` | TravelBook `BookCover01a`, scaled and warm-charcoal tinted |
| offset title frame | `(57,46,326,116)` | Flat `Frame03a` nine-sliced, dark-purple tint |
| title plaque | `(43,52,350,48)` | Flat `Banner04a`, gold tint |
| SURFACE marker / rule | `(52,182,46,32)` / `(160,197,112,6)` | TravelBook `Marker01a` / `Line01a`, green tint |
| FAULT marker / rule | `(52,224,46,32)` / `(160,239,112,6)` | same sources, gold tint |
| BELOW marker / rule | `(52,266,46,32)` / `(160,281,112,6)` | same sources, purple tint |
| dominant Begin button surface | `(345,173,235,58)` | Flat `InputField02a` nine-sliced, gold tint |
| Begin button end caps | `(333,186,32,32)` and `(560,186,32,32)` | Flat `Select01a_2`, green tint |
| Begin play icon | `(358,192,20,20)` | TravelBook `IconPlay01a`, cream tint |
| Continue surface and icon | `(369,242,187,37)` / `(382,250,20,20)` | Flat `InputField01a`; TravelBook `IconArrow01a` |
| Archive surface and icon | `(369,285,187,37)` / `(382,293,20,20)` | Flat `InputField01a`; TravelBook `IconHome01a` |
| two upper-right points | `(569,42,18,18)` and `(586,58,12,12)` | TravelBook `Point01a`, gold and purple tint |

### C. TEXT

`UKHUPACHA`; `DESCENT PROTOCOL`; `HELIX EXPEDITION // 01`; `SURFACE`; `FAULT`; `BELOW`; `BEGIN DESCENT`; `CONTINUE`; `ARCHIVE`; `v0.1 // SIGNAL 7`.

### D. PRIMITIVE_GEOMETRY

Only shared BG-1/BG-2/BG-3. No additional rectangles, borders, separators, plaques, arrows, nodes, corner shapes or ornaments were programmatically drawn. All such UI details come from the listed pack composites.

### E. BACKGROUND_PLACEHOLDER

The large background behind the menu is two layers: the shared dark checker/diagonal field is temporary abstract menu atmosphere, while the large inset shape is an actual TravelBook `BookCover01a` asset composite. It does **not** represent a game-world scene.

---

## `equipment_menu.png`

### A. ORIGINAL_ASSET

None.

### B. ASSET_COMPOSITE

| Visible component | Rect `(x,y,w,h)` | Source |
|---|---|---|
| dossier cover | `(19,28,602,316)` | TravelBook `BookCover01a`, warm-charcoal tint |
| left and right pages | `(55,57,266,272)` and `(319,57,266,272)` | TravelBook `BookPageLeft01a` / `BookPageRight01a`, paper tint |
| title banner | `(125,8,390,52)` | Flat `Banner04a` nine-sliced, gold tint |
| title end markers | `(116,25,40,28)` and `(484,25,40,28)` | TravelBook `Marker01a`, light-gold tint |
| LOADOUT/PACK/NOTES tabs | `(70,55,84,25)`, `(161,55,84,25)`, `(252,55,84,25)` | TravelBook `Frame01a` nine-sliced; green, charcoal, purple tint |
| heading rule | `(82,112,208,5)` | TravelBook `Line01a`, gold tint |
| selected-item surround | `(81,128,82,82)` | TravelBook `Select01a`, green tint |
| inner selected slot | `(99,145,46,46)` | Flat `FrameSlot03a`, gold tint |
| selected star glyph | `(111,157,22,20)` | TravelBook `IconStar01a`, cream tint |
| EQUIPPED badge | `(173,178,116,28)` | TravelBook `FrameSelect01a` nine-sliced, green tint |
| four field-kit slots | `(82,222,44,44)`, `(133,222,44,44)`, `(184,222,44,44)`, `(235,222,44,44)` | TravelBook `Slot01a`, gold/purple/muted-green/charcoal tints |
| three field-kit stars | `(95,234,18,17)`, `(146,234,18,17)`, `(197,234,18,17)` | TravelBook `IconStar01a`, cream tint |
| POWER bar/frame and fill | `(407,142,132,9)` / `(411,145,81,4)` | TravelBook `Bar01a` / `Fill01a`, charcoal/red tint |
| GUARD bar/frame and fill | `(407,170,132,9)` / `(411,173,42,4)` | same sources, charcoal/green tint |
| REACH bar/frame and fill | `(407,198,132,9)` / `(411,201,24,4)` | same sources, charcoal/gold tint |
| field-note panel | `(346,230,208,64)` | TravelBook `Popup01a` nine-sliced, cream tint |
| READY tick | `(526,300,23,19)` | TravelBook `IconTick01a`, green tint |

### C. TEXT

`EXPEDITION DOSSIER`; `LOADOUT`; `PACK`; `NOTES`; `SELECTED LOADOUT`; `ROOTCUTTER` (twice); `BLADE // TIER II`; `EQUIPPED`; `FIELD KIT  04 / 08`; `ROOTCUTTER / HX-17`; `Recovered Helix tool`; `POWER`; `27`; `GUARD`; `14`; `REACH`; `08`; `FIELD NOTE 07`; `Cuts vine, cable and the`; `thin membranes below.`; `READY`.

### D. PRIMITIVE_GEOMETRY

Only shared BG-1/BG-2/BG-3. The page divide, ruled details, corners, title supports, tabs, bars, slots and note border are embedded in or derived from pack assets.

### E. BACKGROUND_PLACEHOLDER

The large area behind the dossier is the shared abstract dark checker field with gold diagonals. The visually dominant dossier itself is a TravelBook cover plus page assets, not drawn geometry. The outer abstract field is temporary menu atmosphere, not a location.

---

## `pause_menu.png`

### A. ORIGINAL_ASSET

None.

### B. ASSET_COMPOSITE

| Visible component | Rect `(x,y,w,h)` | Source |
|---|---|---|
| large cover/backplate | `(77,24,486,316)` | TravelBook `BookCover01a`, warm-charcoal tint |
| inner pause field | `(118,53,404,257)` | Flat `Frame03a` nine-sliced, dark-purple tint |
| title banner | `(165,30,310,52)` | Flat `Banner04a` nine-sliced, gold tint |
| title end markers | `(156,47,40,28)` and `(444,47,40,28)` | TravelBook `Marker01a`, light-gold tint |
| dominant Resume surface | `(175,121,290,61)` | Flat `InputField02a` nine-sliced, gold tint |
| Resume end caps | `(163,135,32,32)` and `(445,135,32,32)` | Flat `Select01a_2`, green tint |
| Resume play icon | `(188,141,20,20)` | TravelBook `IconPlay01a`, cream tint |
| secondary-action shelf | `(158,195,324,88)` | TravelBook `Popup01a` nine-sliced, warm-charcoal tint |
| Dossier surface/icon | `(175,207,134,29)` / `(188,211,20,20)` | Flat `InputField01a`; TravelBook `IconHome01a` |
| Settings surface/icon | `(331,207,134,29)` / `(344,211,20,20)` | Flat `InputField01a`; TravelBook `IconGear01a` |
| Restart surface/icon | `(175,243,134,29)` / `(188,247,20,20)` | Flat `InputField01a`; TravelBook `IconRestart01a` |
| Exit surface/icon | `(331,243,134,29)` / `(344,247,20,20)` | Flat `InputField01a`; TravelBook `IconCross01a` |
| two lateral markers | `(93,137,46,32)` and `(501,137,46,32)` | TravelBook `Marker01a`, purple tint |

### C. TEXT

`FIELD PAUSED`; `HELIX EXPEDITION // 00:18:42`; `RESUME DESCENT`; `DOSSIER`; `SETTINGS`; `RESTART`; `EXIT`; `THE SIGNAL CONTINUES BELOW`.

### D. PRIMITIVE_GEOMETRY

Only shared BG-1/BG-2/BG-3. No additional pause-panel geometry was drawn.

### E. BACKGROUND_PLACEHOLDER

The large area behind the pause overlay is the shared dark checker/green-diagonal field. It nominally stands in for a dimmed gameplay view, but it is not a capture or game-world image. The cover and purple inset above it are pack asset composites.

---

## `puzzle_terminal.png`

### A. ORIGINAL_ASSET

None.

### B. ASSET_COMPOSITE

| Visible component | Rect `(x,y,w,h)` | Source |
|---|---|---|
| outer terminal chassis | `(12,10,616,340)` | Flat `Frame03a` nine-sliced, warm-charcoal tint |
| green header chassis | `(25,23,590,42)` | Flat `Frame03a` nine-sliced, green tint |
| anomaly badge | `(499,28,101,30)` | Flat `FrameMarker03a` nine-sliced, dark-purple tint |
| evidence-card paper panels A/B/C | `(35,83,168,116)`, `(221,83,168,116)`, `(407,83,168,116)` | TravelBook `Popup01a` nine-sliced, cream tint |
| evidence markers A/B/C | `(27,91,42,29)`, `(213,91,42,29)`, `(399,91,42,29)` | TravelBook `Marker01a`, green/gold/purple tint |
| evidence medallions A/B/C | `(53,124,45,45)`, `(239,124,45,45)`, `(425,124,45,45)` | TravelBook `Select01a`, green/gold/purple tint |
| evidence star glyphs A/B/C | `(66,136,19,18)`, `(252,136,19,18)`, `(438,136,19,18)` | TravelBook `IconStar01a`, cream tint |
| verified ticks A/B/C | `(170,172,20,16)`, `(356,172,20,16)`, `(542,172,20,16)` | TravelBook `IconTick01a`, green tint |
| recovered-knowledge panel | `(35,235,413,90)` | TravelBook `Popup01a` nine-sliced, paper tint |
| recovered-knowledge marker | `(24,247,44,31)` | TravelBook `Marker01a`, gold tint |
| recovered-knowledge rule | `(78,271,338,5)` | TravelBook `Line01a`, gold tint |
| valid-state chip | `(466,239,135,34)` | Flat `FrameMarker01a` nine-sliced, green tint |
| valid-state tick | `(475,247,19,15)` | TravelBook `IconTick01a`, cream tint |
| false-state chip | `(466,282,135,34)` | Flat `FrameMarker02a` nine-sliced, red tint |
| false-state cross | `(477,290,17,17)` | TravelBook `IconCross01a`, cream tint |

### C. TEXT

`HELIX ARCHIVE // RELATION ENGINE`; `ANOMALY 03`; card letters `A`, `B`, `C`; `ROOT MAP`; `SHIFT LOG`; `DEEP TONE`; `BIOLOGICAL`; `TEMPORAL`; `UNKNOWN`; `EVIDENCE VERIFIED` (three instances); `CAUSES`; `REVEALS`; `RECOVERED KNOWLEDGE`; `The archive roots predate the Helix site.`; `Pattern match: UKHU / threshold / descent`; `LINK VALID`; `FALSE LINK`; `ARCHIVE RESPONSE: BELOW IS NOT EMPTY`.

### D. PRIMITIVE_GEOMETRY

In addition to shared BG-1/BG-2/BG-3:

| Visual description | Exact rect `(x,y,w,h)` | Primitive | Fill | Outline | Layer | Purpose | Noticeable | Replace with real pack asset? | Suggested type |
|---|---|---|---|---|---|---|---|---|---|
| A→B relation shaft | `(119,207,187,2)` | 2 px line from `(119,207)` to `(305,207)` | none | `#4f9b68` | above evidence cards, below relation label | relation logic | Yes | Optional; current geometry is functional-only | separator / line / connector |
| A→B arrowhead | `(298,203,8,9)` | filled triangle with vertices `(298,203)`, `(305,207)`, `(298,211)` | `#4f9b68` | none | same relation layer | direction | Yes | Optional; current geometry is functional-only | arrow / marker / handle |
| B→C relation shaft | `(305,207,187,2)` | 2 px line from `(305,207)` to `(491,207)` | none | `#76518f` | above evidence cards, below relation label | relation logic | Yes | Optional; current geometry is functional-only | separator / line / connector |
| B→C arrowhead | `(484,203,8,9)` | filled triangle with vertices `(484,203)`, `(491,207)`, `(484,211)` | `#76518f` | none | same relation layer | direction | Yes | Optional; current geometry is functional-only | arrow / marker / handle |

The line bounding heights are reported as the visible raster extent of a Pillow width-2 horizontal line. Triangle bounds use inclusive vertex extents.

### E. BACKGROUND_PLACEHOLDER

The area behind the terminal chassis is the shared dark checker/green-diagonal field. It is abstract temporary atmosphere. The large dark terminal body itself is not placeholder geometry: it is a scaled and tinted Flat `Frame03a` composite.

---

## Geometry summary

Counts below use **visible primitive groups**, because BG-2 and BG-3 are authored as repeated fields. Parenthetical values give raw primitive draw calls: BG-1 = 1, BG-2 = 203, BG-3 = 9 visible lines. “Replaceable” means a pack UI asset is a plausible direct substitute. “Functional-only” means relation geometry allowed by the brief. Background placeholders are counted separately because their eventual replacement is game/menu background content, not a UI-pack element.

| screen | visible primitive count | replaceable | functional-only | background-placeholder groups |
|---|---:|---:|---:|---:|
| `hud.png` | 5 groups (215 raw primitives) | 0 | 0 | 5 |
| `main_menu.png` | 3 groups (213 raw primitives) | 0 | 0 | 3 |
| `equipment_menu.png` | 3 groups (213 raw primitives) | 0 | 0 | 3 |
| `pause_menu.png` | 3 groups (213 raw primitives) | 0 | 0 | 3 |
| `puzzle_terminal.png` | 7 groups (217 raw primitives) | 4 | 4 | 3 |

### Large-background meaning by screen

| Screen | What the large background currently represents |
|---|---|
| HUD | Temporary top-down Helix gameplay space: checker/diagonal field plus a dark circular/diamond room suggestion. |
| Main menu | Abstract menu atmosphere behind a real TravelBook cover composite; not a game location. |
| Equipment | Abstract menu atmosphere behind the real cover-and-pages dossier composite. |
| Pause | Stand-in for a dimmed gameplay view behind the pack-derived pause overlay. |
| Puzzle terminal | Abstract technical atmosphere behind the pack-derived terminal chassis. |

No replacement assets are selected or recommended by filename in this audit. The “suggested type” entries only identify the category a future manually chosen replacement would need to fulfill.
