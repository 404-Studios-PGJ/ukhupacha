# La Fachada Verde — Reception + Offices construction report

Production scene: `res://levels/level1/level1_fachada_verde.tscn`.
Branch: `feat/level1-fachada-verde`. Main scene unchanged. No commit, push, merge, rebase, or branch change.

1. **Files created:** `level1_fachada_verde.tscn`, `level1_fachada_verde.gd` + `.uid`, `interior_tiles.tres`, `props/desk.tscn`, `props/sofa.tscn`, `props/shelf.tscn`, `props/chair.tscn`, `verify_section.gd` + `.uid`, `VERIFICATION.json`, and this report, all under `levels/level1/`.
2. **Existing files modified:** none. All Player, enemy, UI, audio, interactable and project settings files remain unchanged. Existing untracked files are preserved.
3. **Scene path:** `levels/level1/level1_fachada_verde.tscn`.
4. **Hierarchy:**

```text
LaFachadaVerde
├── Structure
│   ├── Floor (TileMapLayer)
│   ├── Walls (TileMapLayer)
│   └── Existing-image entrance mat, doors and windows (Sprite2D)
├── World (Y sort)
│   ├── Reception (counter, seating, plants)
│   ├── Player (real production instance)
│   │   └── Camera2D (level-owned child)
│   └── Offices
│       ├── WorkCourt
│       ├── Archive
│       └── RecordsOffice
├── Interactables (four reserved Marker2D slots)
├── Navigation (spawn, reveal, transition, court, boundary markers)
├── Gameplay
│   ├── InteractionSystem (existing script)
│   ├── MusicRegionA (existing script)
│   └── Three encounter/spawn reservation markers
└── UIFlow (existing scene; HUD, pause, equipment, death/retry)
```

5. **Player measurements through MCP:** visible idle alpha bounds 14 × 32 px in a 64 × 64 texture frame, native scale 1. Collision 14 × 10 px centered at (0, -5). Walk 80 px/s; run 140 px/s. Melee reaches 18 px unarmed, 28 sword, 30 axe from pivot (0, -12). Dodge nominally 220 px/s for 0.20 s (44 px); observed input test moved 47.67 px, consistent with discrete physics ticks. No Player changes.
6. **Grid:** 16 px native LRK source grid, baked authored cells on two TileMapLayers sharing an external TileSet. Architecture atlas source ID 0. Floors at atlas cells (6,6) white planks, (10,13) dark geometric tile, (2,6) wood; walls at (2,1) cream cap and (2,3) light panel. No procedural generation or runtime level construction.
7. **Used asset families:** only staged pack_01 LRK architecture, living-room/table/chair, cabinet/bookcase and decoration families. All nine used PNGs were visually inspected through MCP before placement. Exact paths are listed below.
8. **Scaling:** every environmental family remains at native ×1, integer authored positions, nearest texture filtering. No source PNG changes or recoloring. Door leaves use native 30 × 48 atlas regions; windows use 48 × 30 regions. Horizontal mirroring pairs the existing door leaf as a double door.
9. **Reception:** usable floor 416 × 304 px, x=48..464, y=416..720. Public entrance/spawn (256,688), mat and closed entrance doors behind it; four seats in two ordered waiting banks, three plants, three adjoining check-in table modules, one screen and staff chair. The central aisle remains open; the route turns east toward the north connector. Light floor, glazed wall accents and ordered sparse furniture establish the public facade.
10. **Offices:** work court 512 × 208 px (256..768, 96..304); archive 192 × 208 (48..240, 96..304); records office 224 × 176 (528..752, 336..512). Main work court has a north workstation row, a lower two-desk island and a displaced chair. Archive has densely grouped bookcases and an expediente desk. The side records office provides a quieter information/equipment space. Dark floors and a wood archive distinguish the office composition from reception.
11. **Passages:** reception connector 128 px wide, approximately 112 px long; archive opening 96 px; records opening 96 px; office-to-boundary approach opening 128 px, with 112 × 128 px clear approach floor. Entrance/security double-door artwork spans 60 px and is closed in this pass; it is not an open traversal doorway. Physical opening tests use the real 14 × 10 Player shape.
12. **Collision:** world layer 1, matching existing Player mask 5. Both wall tile types have full 16 × 16 collision polygons matching the visible cells. Reusable StaticBody2D props use rectangles: desk 48 × 26 at y=-16; sofa 46 × 20 at y=-14; shelf 48 × 16 at y=-10; chair 14 × 12 at y=-8. Tall shelves block at their base. Plants, screens, windows and rugs add no micro-collisions. Door endpoint blocking comes from the visible wall strip under the door art, not an enlarged invisible boundary.
13. **Reserved interactions:** reception terminal (180,496); record terminal (640,420); expediente (176,288); optional equipment (560,416). Invisible markers only; no invented narrative or framework.
14. **Combat reservation:** center (528,200), approach spawn markers (288,240) and (736,240). The central office core contains approximately 288 × 96 px clear maneuvering floor between furniture bands. No enemies spawned or balanced; encounter behavior remains for a later pass.
15. **Security boundary:** marker (832,112), double closed doors centered near (832,72) on the north wall. Future continuation is north; no Security room, descent, laboratory, mining, boss or rupture content exists.
16. **MCP traversal:** real Player controlled with input actions through its existing physics/controller code, without teleporting for the final trace. Reached reception reveal, connector, office court, security boundary (~832.33,111.67), archive expediente slot, records terminal/equipment slots, then returned to entrance (~254.67,687.74). All final waypoint batches passed. Results are in `VERIFICATION.json`. Runtime screenshots inspected reception, office court, records office and future-access framing at the actual 640 × 360 viewport.
17. **Collision checks:** 37/37 passed: 22 real-body motion probes plus 15 authored-route floor continuity checks. Includes wall directions, both corridor jambs, desk, sofa, shelf, chairs, office island and open connections. Actual movement into the counter stopped at y=487.00, matching its footprint. An early sofa-block test stopped movement and the Player escaped through the central aisle. Actual dodge moved 47.67 px in the office court. The north security boundary stopped the Player at y≈106.
18. **Errors:** final run `r1268837-8` had no parser/runtime errors; log contained only the MCP helper registration message, with no dropped entries. Both new scripts passed MCP parse diagnostics. During QA setup a rejected live script patch left a missing helper method, causing one eval error; restarting and patching while stopped resolved it. Long eval batches hit the bridge's 8-second limit, and one scripted return attempted to cross a chair; the final short batches route around furniture and all pass. Initial background-window throttling/input timeout was resolved by focus recovery. These were verification setup issues, not unresolved production errors.
19. **Missing assets:** no construction-blocking visual asset missing for this section. Dedicated Helix branding and richer computer keyboard/console art remain partial as the supplied audit states. Blank wall surfaces remain available for later branding.
20. **Classification deviations:** the Inside_C crop at x=585,y=398,w=33,h=33 looks like a round lamp/base rather than a monitor; the x=242,y=310,w=119,h=27 crop looks like a rail rather than a counter. Both rejected, classification CSV unchanged. The LRK table module is adapted into the check-in counter; the classified black display screen serves as the workstation screen. Modern Interiors 48px was visually reviewed but not mixed into this native LRK composition.
21. **Git status:** existing untracked entries plus the new `levels/` directory (exact status below).
22. **Whitespace:** `git diff --check` passed. Because the level is intentionally untracked, its newly authored text files were also checked separately for trailing whitespace and whitespace-only blank lines. No staging/commit was performed.

## Exact PNG sources used

All paths are relative to `assets/staging/fachada_verde_extracted/pack_01/`.

- `atlases/floorswalls_LRK.png`
- `atlases/doorswindowsstairs_LRK.png`
- `static/livingroom_LRK_x0014_y0158_w0052_h0036.png` — desk/check-in module
- `static/livingroom_LRK_x0014_y0030_w0052_h0036.png` — seating
- `static/livingroom_LRK_x0110_y0213_w0020_h0029.png` — chair
- `static/livingroom_LRK_x0356_y0340_w0040_h0024.png` — screen
- `static/livingroom_LRK_x0014_y0254_w0068_h0036.png` — entrance mat
- `static/cabinets_LRK_x0014_y0014_w0052_h0052.png` — bookcase/cabinet
- `static/decorations_LRK_x0046_y0078_w0020_h0035.png` — greenery

Original staging provenance and license/credit records remain untouched. No new bitmap/vector art, environmental ColorRect, Polygon2D, draw methods, generated texture or recoloring was introduced.

## Camera compatibility

The integrated reference scene and Player had no Camera2D. A minimal level-owned camera follows the existing Player at zoom 1 with offset (0,-48), no smoothing or new controller. Bounds (0,-48)..(944,784) keep the north door below the HUD. This is the only camera addition; Player/camera systems were not rewritten.

## Git status at signoff

```text
?? .agents/
?? README_GIAN.md
?? README_JHON.md
?? README_KEVIN.md
?? README_NAYELI.md
?? assets/staging/
?? levels/
?? skills-lock.json
```

## Reproducing MCP verification

Open and run the production scene directly. In game_eval:
`return load('res://levels/level1/verify_section.gd').new().run(get_tree().current_scene)`.

For physical traversal use `await ...traverse(current_scene, [['label', Vector2(x,y)], ...])` with short batches under eight seconds. Follow the recorded waypoints in `VERIFICATION.json`; move through the approach before returning west from the closed north gate. Furniture correctly blocks direct shortcuts. The verifier is not attached to the production scene and has no effect on normal play.
