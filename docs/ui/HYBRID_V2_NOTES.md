# Hybrid Discovery v2

Hybrid Discovery v2 keeps the Flat Theme as the interface system and uses TravelBookLite as a recovered-knowledge layer. The five mockups are static 640×360 compositions. They use only PNGs already present in `candidates/`, simple geometry, color overlays, and temporary text.

## Palette

| Role | Color | Usage |
|---|---|---|
| Dark base | `#1b1d1f` | Main background and gameplay field |
| Warm charcoal | `#2a2422` | Title plates, dossier headings, secondary navigation |
| Helix green | `#4f9b68` | Primary action, success, stamina, terminal link |
| Muted green | `#6f8f70` | Helix metadata and supporting status text |
| Gold/amber | `#c99745` | Selection rails, structural rules, objective emphasis |
| Light gold | `#e0bd6d` | Primary focus, highlighted labels, relation state |
| Ukhu purple | `#76518f` | Anomaly nodes and recovered-knowledge markers |
| Dark purple | `#453651` | Anomaly header surfaces |
| Health red | `#a94b4b` | HP and rejected relation state |
| Warm cream | `#d8c7a2` | Titles, labels, and readable foreground text |

Gold and cream carry more of the visible hierarchy than v1. Purple is localized to anomaly and recovered-knowledge details. Green remains tied to Helix systems, interaction, stamina, and successful actions.

## HUD

Original candidate assets used:

- `icons/UI_TravelBook_IconHeart01a.png`
- `icons/UI_TravelBook_IconEnergy01a.png`
- `slots/UI_Flat_Select01a_2.png`
- `slots/UI_Flat_FrameSlot01a.png`
- `prompts/UI_TravelBook_GamepadA01a.png`
- `decorations/UI_TravelBook_Marker01a.png`

Operations:

- Heart and energy icons are recolored red and green without smoothing.
- Flat slot textures are recolored gold and warm charcoal; the shield and temporary sword marks are simple layout guides.
- The interaction plaque combines warm-charcoal geometry, a gold outline, the gamepad glyph, and a purple TravelBook marker.
- HP/stamina and equipment frames are compact custom composites sized within the v1 footprint.

Hierarchy improvement: open-ended rails and gold top edges establish a crafted frame without increasing permanent screen coverage. Bars remain subordinate to gameplay, while the selected weapon gets one clear gold focal state.

## Main menu

Original candidate assets used:

- `buttons/UI_Flat_Button01a_2.png`
- `buttons/UI_Flat_ButtonPlay01a.png`
- `icons/UI_TravelBook_IconStar01a.png`
- `decorations/UI_TravelBook_Marker01a.png`
- `decorations/UI_TravelBook_Line01a.png`
- `decorations/UI_TravelBook_Point01a.png`

Operations:

- The Flat hover button is reconstructed as a wide primary New Game action and recolored Helix green.
- The play icon is recolored light gold.
- TravelBook line and point sprites are enlarged only by integer nearest-neighbor scaling and recolored gold/purple.
- The purple star and gold marker are used as small discovery accents.
- The large title plate, clipped left header shape, Helix orbital diagram, and open secondary navigation are simple layout compositions.

Hierarchy improvement: the centered dialog and three equal buttons from v1 are replaced by a wide title structure, one dominant action, two lower-weight navigation choices, and a Helix visual signature occupying intentional negative space.

## Equipment menu

Original candidate assets used:

- `panels/UI_Flat_Frame02a.png`
- `panels/UI_Flat_Banner03a.png`
- `slots/UI_Flat_Select01a_2.png`
- `slots/UI_Flat_FrameSlot01a.png`
- `buttons/UI_Flat_Button01a_2.png`
- `buttons/UI_Flat_ButtonCheck01a.png`
- `icons/UI_TravelBook_IconStar01a.png`
- `decorations/UI_TravelBook_Marker01a.png`

Operations:

- Flat Frame02 is reconstructed with fixed corners as both the loadout rail and main dossier panel, using warm and neutral variants.
- Flat Banner03, previously excluded from the runtime shortlist, is reconstructed and recolored gold for the overlapping Tier II label.
- Flat slot states are recolored into normal and selected loadout states.
- The equipped button combines a green Flat button, gold outline, and recolored check glyph.
- The item header, stat slip, separators, bar fills, sword, and shield are temporary composite geometry and labels.

Hierarchy improvement: the selected item owns a shaped warm header, overlapping tier banner, narrative field-notes area, separate performance slip, and a single dominant equipped state. The left rail reads as an expedition kit index rather than a generic inventory grid.

## Pause menu

Original candidate assets used:

- `buttons/UI_Flat_Button01a_2.png`
- `buttons/UI_Flat_ButtonPlay01a.png`
- `icons/UI_TravelBook_IconStar01a.png`

Operations:

- The main Flat button is reconstructed and recolored green for Resume Expedition.
- The play glyph is recolored light gold and the star is recolored purple.
- The large clipped warm header, gold separator, session metadata, and open utility navigation are simple layout compositions.

Hierarchy improvement: Resume is the only large button. Controls, Retry, and Main Menu become a lower-weight horizontal utility row, while the header shares the asymmetric silhouette and title language of the main menu.

## Puzzle terminal

Original candidate assets used:

- `panels/UI_Flat_Frame02a.png`
- `panels/UI_TravelBook_Popup01a.png`
- `icons/UI_Flat_IconCross01a.png`
- `icons/UI_Flat_IconCheck01a.png`
- `icons/UI_TravelBook_IconStar01a.png`
- `decorations/UI_TravelBook_Marker01a.png`

Operations:

- Flat Frame02 is reconstructed for the three evidence cards; each card receives a distinct corporate, selected, or anomaly header state.
- TravelBook Popup is reconstructed and recolored warm charcoal only for the recovered-knowledge area.
- Check and cross icons are recolored green/red for valid and rejected relations.
- The star and marker are recolored purple and confined to anomaly/recovered data.
- Relation rails, arrowheads, nodes, audit feedback, terminal chrome, and text are simple composited geometry.

Hierarchy improvement: the screen now presents a visible left-to-right reasoning flow between Public Record, Internal Classification, and Anomaly. Rejected and successful relations remain readable simultaneously. The unlocked result leads into a separate warm recovered-knowledge layer, making the Helix/archive boundary visually explicit.

## Reconsidered candidates

- `UI_Flat_Banner03a.png` returns as the compact Tier II label. Its warm banner silhouette is useful when isolated from the otherwise light Flat palette.
- `UI_TravelBook_Popup01a.png` returns as the recovered-knowledge container in the terminal. It is limited to one narrative region and does not turn the terminal into a book page.
- `UI_TravelBook_Marker01a.png` returns as a small transition/discovery marker in the HUD, menu, equipment header, and recovered-knowledge strip.
- `UI_TravelBook_Line01a.png` and `UI_TravelBook_Point01a.png` return as the main-menu title divider.
- `UI_TravelBook_IconStar01a.png` is used as a restrained purple or gold discovery marker.
- Additional Flat frames were compared. Frame02 remained the strongest layered panel because its corners survive reconstruction cleanly; Frame03 added a color emphasis that competed with the controlled v2 palette.
- The remaining Flat banners were compared but stayed unused because their end treatments made the large title and terminal headers feel more ornamental than technological.
- Full TravelBook pages remain excluded. TravelBook Frame01 was tested for the recovered strip, but Popup01 produced a stronger contained narrative region with less medieval association.

## Reusable Godot components

- `HybridHeader`: clipped title area, metadata label, gold divider, optional discovery marker.
- `PrimaryActionButton`: Flat normal/hover/pressed/disabled textures with green modulation, gold focus outline, optional semantic icon.
- `SecondaryNavAction`: open warm-charcoal row with bottom rule and focus state.
- `CompactStatusRail`: heart/energy glyph, progress fill, numeric value, warm outer rail.
- `EquipmentSlot`: normal, selected, unavailable, weapon, and shield states.
- `DossierPanel`: Flat nine-patch surface with warm item header, tier banner, description slot, and stat slip.
- `EvidenceCard`: public/internal/anomaly variants with selection arrow and relation sockets.
- `EvidenceRelation`: gold or purple rail, directional arrow, valid/rejected feedback state.
- `RecoveredKnowledgePanel`: TravelBook popup nine-patch, purple marker, cream narrative text.
- `InteractionPrompt`: input glyph, action label, optional anomaly marker.

All pack sprites should be imported with filtering disabled. Wide Flat and TravelBook surfaces need explicit NinePatchRect margins so their corners retain their source pixel density.
