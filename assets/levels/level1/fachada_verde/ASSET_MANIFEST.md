# La Fachada Verde production asset manifest

P0-A DESCENTS = RESOLVED by the manually approved staircase. This records asset availability, not constructed or gameplay-validated descent areas.

## Batch 01 assets used by the current Reception/Offices scene

| Production path | Scene use | Previous path |
|---|---|---|
| architecture/floorswalls_LRK.png | interior_tiles.tres TileSet floor/wall atlas | assets/staging/fachada_verde_extracted/pack_01/atlases/floorswalls_LRK.png |
| architecture/doorswindowsstairs_LRK.png | map entrance/security doors and windows | assets/staging/fachada_verde_extracted/pack_01/atlases/doorswindowsstairs_LRK.png |
| furniture/desk_LRK.png | props/desk.tscn, counters and office desks | assets/staging/fachada_verde_extracted/pack_01/static/livingroom_LRK_x0014_y0158_w0052_h0036.png |
| furniture/sofa_LRK.png | props/sofa.tscn, reception seating | assets/staging/fachada_verde_extracted/pack_01/static/livingroom_LRK_x0014_y0030_w0052_h0036.png |
| furniture/chair_LRK.png | props/chair.tscn, reception and office chairs | assets/staging/fachada_verde_extracted/pack_01/static/livingroom_LRK_x0110_y0213_w0020_h0029.png |
| furniture/bookcase_LRK.png | props/shelf.tscn, records/archive shelves | assets/staging/fachada_verde_extracted/pack_01/static/cabinets_LRK_x0014_y0014_w0052_h0052.png |
| props/plant_LRK.png | reception plant sprites | assets/staging/fachada_verde_extracted/pack_01/static/decorations_LRK_x0046_y0078_w0020_h0035.png |
| props/entrance_mat_LRK.png | entrance mat | assets/staging/fachada_verde_extracted/pack_01/static/livingroom_LRK_x0014_y0254_w0068_h0036.png |
| props/workstation_screen_LRK.png | reception check-in and office monitors | assets/staging/fachada_verde_extracted/pack_01/static/livingroom_LRK_x0356_y0340_w0040_h0024.png |

Only the nine Batch 01 PNGs referenced by this scene, its TileSet and its four prop scenes were promoted. The staging copies remain unchanged.

## Batch 02 IMPORT_NOW (25 unique files)

- mining/gold_rush/free_floor_TileSheet.png
- mining/gold_rush/free_walls&doors_TileSheet.png
- mining/gold_rush/free_props_TileSheet.png
- architecture/tilesFloor.png
- architecture/tilesWalls.png
- laboratory/land_of_pixels/tilesStuff.png
- security/foundation/electrical_box_closed.png
- security/foundation/alarm_light_off.png
- security/foundation/alarm_light_on.png
- technical/foundation/pipe_single_v1.png
- technical/foundation/valve.png
- security/foundation/security_camera_right.png
- security/foundation/security_camera_front.png
- security/foundation/sign_direction_sec.png
- security/foundation/sign_direction_lab.png
- security/foundation/room_label_ctrl.png
- security/foundation/room_label_lab.png
- security/foundation/sign_caution.png
- security/foundation/sign_biohazard.png
- laboratory/land_of_pixels/culture_tank.png (approved residual crop)
- security/hazard_barrier_module.png (approved residual crop)
- laboratory/land_of_pixels/monitor_terminal.png (approved residual crop)
- animations/land_of_pixels/spriteSheet_lightBulbSmallAnimation_16x16.png
- animations/land_of_pixels/spriteSheet_lightingBulb02_68x73.png
- animations/land_of_pixels/spriteSheet_tiledLiquids_16x16.png

IMPORT_LATER (171 unique sources) and DO_NOT_IMPORT (33) remain outside production. No other Batch 02 assets were copied. Atlases and protected animation sheets remain intact.

## Manually approved staircase

Source: /home/nivek/Descargas/mapas/nuevo/stairs_descent_red.png
Destination: transitions/stairs_descent_red.png
SHA-256 for source and copy: 296f237bec4ec9a7281b8e5f13a9937f81c48aeff6fb64dc9cd93c560cdf5442. Dimensions: 189 x 206 pixels. The user accepts its diagonal side/three-quarter perspective. Preserve it byte-for-byte and reuse it for Security-to-Laboratory and Laboratory-to-Cave/Mining descents with different surrounding environmental composition. This migration constructs neither descent.

## Pixel integrity

Hashes of all 9 Batch 01 and 25 Batch 02 copied PNGs match their sources. Dimensions are unchanged. No graphics were generated, redrawn, cropped, recolored, resized or interpolated.
