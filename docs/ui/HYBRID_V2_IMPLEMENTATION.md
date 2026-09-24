# Hybrid Discovery v2 — Godot 4.7.2 implementation specification

## 1. Runtime contract

- Logical viewport: **640×360**.
- Reference stretch: configure the project viewport for 640×360 and use integer scaling where the display permits it.
- All UI roots use `Control` nodes. HUD uses a `CanvasLayer`; menu scenes can be direct full-rect `Control` roots.
- Never scale `CharacterBody2D`, the gameplay world, or camera content to implement UI scaling.
- All text remains runtime `Label` content. No required texture contains game text.
- All texture paths below are relative to the future Godot project UI asset root and correspond directly to files in `selected_final/`.
- Set every selected PNG import to nearest-neighbor filtering disabled, mipmaps disabled, repeat disabled unless explicitly needed, and lossless compression.
- Prefer `modulate`/`self_modulate` for the palette treatments. Do not generate separate recolored PNGs.

### Coordinate notation

`A(l,t,r,b)` means anchors left/top/right/bottom. `O(l,t,r,b)` means offsets. For a fixed top-left node at `(x,y)` with size `(w,h)`, use `A(0,0,0,0)` and `O(x,y,x+w,y+h)`. `z` is `z_index` relative to the screen root. Approximate positions below are authoritative reference positions from the v2 compositions; minor one-pixel corrections are allowed after visual inspection in Godot.

### Palette

| Token | Value | Runtime use |
|---|---|---|
| `dark_base` | `#1b1d1f` | Screen background, neutral card body |
| `warm_charcoal` | `#2a2422` | Title plates, dossier headers, secondary navigation |
| `helix_green` | `#4f9b68` | Primary action, stamina, valid relation, success |
| `muted_green` | `#6f8f70` | Helix metadata, supporting system labels |
| `gold` | `#c99745` | Selection rail, divider, objective emphasis |
| `light_gold` | `#e0bd6d` | Focus state, highlighted label, relation result |
| `ukhu_purple` | `#76518f` | Anomaly and recovered-knowledge marker |
| `dark_purple` | `#453651` | Anomaly header surface |
| `health_red` | `#a94b4b` | HP and invalid relation |
| `warm_cream` | `#d8c7a2` | Primary text and bright glyphs |

Use theme colors for Labels and StyleBoxFlat resources. Use texture modulation for pack sprites. Use `CanvasItem.self_modulate` on an individual texture when a parent should not tint its children.

## 2. Scalable texture rules

The source packs do not provide nine-patch metadata. The following are starting values only. For every entry: **VERIFY VISUALLY IN GODOT** at the minimum and largest target sizes before locking margins.

| Texture | Suggested starting patch margins L/T/R/B | Usage |
|---|---:|---|
| `panels/UI_Flat_Frame02a.png` (96×64) | 8/8/8/8 | Dossier, evidence, structural panels |
| `panels/UI_Flat_Banner03a.png` (64×20) | 5/5/5/5 | Tier banner |
| `panels/UI_TravelBook_Popup01a.png` (62×30) | 5/5/5/5 | Recovered knowledge |
| `buttons/UI_Flat_Button01a_*.png` (32×32) | 7/7/7/7 | Primary button state textures |
| `bars/UI_Flat_Bar01a.png` (32×8) | 3/2/3/2 if stretched | Compact progress outline |

For `TextureButton`, use nine-patch stretching if supported by the chosen setup, or place a state-switched `NinePatchRect` behind a transparent `Button`/`TextureButton`. Keep corner pixels at a 1:1 source ratio. Do not bilinearly resize textures.

## 3. Reusable components

### 3.1 HybridHeader

- Scene: `ui/components/hybrid_header.tscn`
- Root: `Control`, minimum size `(320,46)`; screen headers usually `(640,46)`.
- Children:
  - `Background: ColorRect`, full rect, `dark_base` or transparent.
  - `TitlePlate: Control`, optional clipped polygon drawn by `_draw()` or a `Polygon2D` behind Controls.
  - `Title: Label`, left aligned.
  - `Metadata: Label`, right aligned.
  - `Rule: ColorRect`, bottom anchored, height 2, `gold` or `helix_green`.
  - `Marker: TextureRect`, optional `decorations/UI_TravelBook_Marker01a.png` or `icons/UI_TravelBook_IconStar01a.png`.
- Textures: optional marker/star only; the plate and rule are geometry.
- States: `neutral`, `helix`, `discovery`, `anomaly`.
- Signals: `header_action_requested(action: StringName)` only if an optional back/action control is enabled.
- Exposed properties: `title`, `metadata`, `state`, `show_marker`, `marker_texture`, `rule_color`, `title_color`, `plate_width`.

### 3.2 PrimaryActionButton

- Scene: `ui/components/primary_action_button.tscn`
- Root: `Control`, minimum size `(160,40)`, focus mode `ALL` through its interactive child.
- Children:
  - `StateFrame: NinePatchRect`, full rect; swaps `buttons/UI_Flat_Button01a_1..4.png`.
  - `FocusOutline: Panel`, inset 2; StyleBoxFlat border width 2, `light_gold`.
  - `Content: HBoxContainer`, centered, separation 8.
  - `Icon: TextureRect`, optional 17×16 source sprite, integer display size.
  - `Text: Label`, runtime label.
  - `HitTarget: TextureButton` or `Button`, full rect and visually transparent.
- Textures: four Flat button states; optional play/check/cross icon.
- States: `normal`, `hover`, `focused`, `pressed`, `disabled`; focus and hover use `_2`, pressed `_3`, disabled `_4`, normal `_1`.
- Signals: `pressed`, `focus_entered`, `focus_exited`, `mouse_entered`, `mouse_exited` forwarded from `HitTarget`.
- Exposed properties: `text`, `icon`, `disabled`, `action_name`, `normal_modulate`, `focus_modulate`, `show_focus_outline`.

### 3.3 SecondaryNavAction

- Scene: `ui/components/secondary_nav_action.tscn`
- Root: `Control`, minimum size `(120,34)`.
- Children: `Background: Panel` with StyleBoxFlat warm-charcoal fill; `BottomRule: ColorRect` height 2; optional `Icon: TextureRect`; `Text: Label`; transparent `Button` hit target.
- Textures: optional pause/restart/cross icon. Background is primitive geometry.
- States: normal rule `#51483f`, hover/focus rule `gold`, pressed background darkened, disabled text `#887f70`.
- Signals: `pressed`, `focus_entered`, `focus_exited`.
- Exposed properties: `text`, `icon`, `disabled`, `selected`, `action_name`.

### 3.4 CompactStatusRail

- Scene: `ui/components/compact_status_rail.tscn`
- Root: `Control`, minimum/target size `(176,44)`.
- Children:
  - `RailBackground: Panel`, full rect; StyleBoxFlat dark translucent fill, one-pixel warm border.
  - `TopRule: ColorRect`, `(7,3,157,2)`, gold.
  - `Rows: VBoxContainer`, `O(4,10,170,41)`, separation 1.
  - Each row: `HBoxContainer` containing `Icon: TextureRect`, `Bar: TextureProgressBar`, `Value: Label`.
- Textures: heart, energy, Bar01 outline, BarFill01c HP, BarFill01a stamina; critical HP can use BarFill01d.
- States: HP normal/critical, stamina normal/exhausted, hidden.
- Signals: `health_changed(value, maximum)`, `stamina_changed(value, maximum)` are data-facing component signals only if desired; otherwise update via properties.
- Exposed properties: `health`, `health_max=100`, `stamina`, `stamina_max=100`, `show_values`, `critical_threshold`.

### 3.5 EquipmentSlot

- Scene: `ui/components/equipment_slot.tscn`
- Root: `Control`, minimum size `(32,44)` including optional caption; interactive square remains 32×32.
- Children: `HitTarget: TextureButton` 32×32; `SelectedOverlay: TextureRect` 32×32; `ItemIcon: TextureRect` centered; `Caption: Label` beneath; optional `UnavailableOverlay: ColorRect`.
- Textures: FrameSlot01a normal, FrameSlot01b hover, FrameSlot01c unavailable, Select01a_1..4 selection pulse/frames.
- States: `empty`, `available`, `hover`, `selected`, `equipped`, `unavailable`; unavailable disables focus and input.
- Signals: `slot_focused(slot_id)`, `slot_pressed(slot_id)`, `equip_requested(slot_id)`.
- Exposed properties: `slot_id`, `caption`, `item_texture`, `state`, `selected`, `equipped`, `discovered`.

### 3.6 DossierPanel

- Scene: `ui/components/dossier_panel.tscn`
- Root: `PanelContainer`, minimum size `(360,220)`.
- Children:
  - `Frame: NinePatchRect`, full rect, Frame02.
  - `ContentMargin: MarginContainer`, 16/14/16/14.
  - `ItemHeader: Control`, minimum `(298,50)`, warm clipped geometry.
  - `ItemName: Label`, `Category: Label`, optional `Marker: TextureRect`.
  - `TierBanner: NinePatchRect`, Banner03, with `TierLabel: Label`.
  - `DescriptionLabel: Label`, autowrap.
  - `StatsPanel: PanelContainer` containing runtime stat rows.
  - `EquippedButton: PrimaryActionButton`.
- Textures: Frame02, Banner03, star/marker, Flat check icon and primary button states.
- States: item selected, equipped, equip available, undiscovered (component hidden rather than showing secret data).
- Signals: `equip_requested(item_id)`, `item_action_focused(item_id)`.
- Exposed properties: `item_id`, `item_name`, `category`, `tier`, `description`, `stats`, `equipped`, `show_anomaly_marker`.

### 3.7 EvidenceCard

- Scene: `ui/components/evidence_card.tscn`
- Root: `Control`, minimum/target size `(164,94)`.
- Children: `Frame: NinePatchRect` Frame02; `Header: Panel` height 23; `Category: Label`; `SelectionArrow: TextureRect` or primitive triangle; `Title: Label`; `Summary: Label`; `DetailLines: VBoxContainer` or runtime labels; optional `AnomalyStar: TextureRect`; transparent `Button` hit target.
- Textures: Frame02, optional Flat arrow, TravelBook star.
- States: `normal`, `hover`, `selected`, `related`, `anomaly`, `unavailable`.
- Signals: `evidence_selected(evidence_id)`, `relation_endpoint_requested(evidence_id)`, `reread_requested(evidence_id)`.
- Exposed properties: `evidence_id`, `category`, `title`, `summary`, `variant`, `selected`, `available`, `related`.

### 3.8 EvidenceRelation

- Scene: `ui/components/evidence_relation.tscn`
- Root: `Control`, minimum size `(42,16)`, mouse filter `IGNORE` unless relation selection is interactive.
- Children: `Line: Line2D`, `StartNode/EndNode: Control` drawing circles, `ArrowHead: Polygon2D`; optional `HitTarget: Button` with no visual style.
- Textures: none required. Flat arrow may be used as an optional endpoint glyph.
- States: `neutral`, `candidate`, `valid` (green/gold), `rejected` (red), `anomaly` (purple).
- Signals: `relation_pressed(relation_id)` if interactive.
- Exposed properties: `relation_id`, `from_point`, `to_point`, `state`, `line_width=2`, `animated=false`.

### 3.9 RecoveredKnowledgePanel

- Scene: `ui/components/recovered_knowledge_panel.tscn`
- Root: `PanelContainer`, minimum size `(280,54)`.
- Children: `Frame: NinePatchRect` TravelBook Popup; `InnerBorder: Panel`; `Marker: TextureRect`; `Heading: Label`; `Body: Label` with autowrap; optional `Star: TextureRect`.
- Textures: TravelBook Popup, marker, star.
- States: hidden, revealed, focused/readable, acknowledged.
- Signals: `reread_requested(entry_id)`, `acknowledged(entry_id)`.
- Exposed properties: `entry_id`, `heading`, `body`, `revealed`, `show_star`, `accent_color`.

### 3.10 InteractionPrompt

- Scene: `ui/components/interaction_prompt.tscn`
- Root: `Control`, minimum/target size `(164,24)`.
- Children: `Background: Panel` warm-charcoal clipped/angled StyleBox or custom draw; `Glyph: TextureRect`; `Action: Label`; optional `Marker: TextureRect`.
- Textures: GamepadA, CommandPress, CommandHold; optional TravelBook marker.
- States: hidden, press, hold, unavailable, anomaly.
- Signals: `prompt_shown(action_name)`, `prompt_hidden(action_name)` for accessibility/telemetry if needed; input itself remains in gameplay logic.
- Exposed properties: `action_name`, `display_text`, `input_mode`, `hold`, `available`, `anomaly`, `glyph_texture`.

## 4. HUD — `ui/hud.tscn`

### Node hierarchy

```text
HUD (CanvasLayer, layer 10)
└── SafeArea (Control, full rect)
    ├── StatusRail (CompactStatusRail)
    ├── EquipmentBlock (Control)
    │   ├── Background (Panel)
    │   ├── TopRule (ColorRect)
    │   ├── WeaponSlot (EquipmentSlot)
    │   └── ShieldSlot (EquipmentSlot)
    └── InteractionPrompt (InteractionPrompt)
```

### Layout and visual order

| Node | Anchors / offsets | Position / size | z | Type / component | Texture and modulation | State |
|---|---|---:|---:|---|---|---|
| `SafeArea` | `A(0,0,1,1) O(0,0,0,0)` | 0,0 / 640×360 | 0 | Control | None | Always |
| `StatusRail` | `A(0,0,0,0) O(8,8,184,52)` | 8,8 / 176×44 | 10 | CompactStatusRail | Heart red, energy green, Flat bars modulated | HP/stamina visible |
| `EquipmentBlock` | `A(1,0,1,0) O(-94,8,-8,56)` | 546,8 / 86×48 | 10 | Control | Geometry background, gold rule | Visible |
| `WeaponSlot` | local `O(5,7,37,51)` | 551,15 / 32×44 | 11 | EquipmentSlot | selected Flat slot, gold | Selected/equipped |
| `ShieldSlot` | local `O(44,7,76,51)` | 590,15 / 32×44 | 11 | EquipmentSlot | Flat normal/unavailable | Runtime state |
| `InteractionPrompt` | `A(.5,1,.5,1) O(-84,-64,80,-40)` | 236,296 / 164×24 | 20 | InteractionPrompt | Prompt glyph cream/gold; optional purple marker | Hidden unless contextual |

HP and stamina maximum values are both `100`. Set TextureProgressBar `min_value=0`, `max_value=100`, `step=1`. Weapon and shield item art remains runtime data; temporary v2 sword/shield geometry is not a required asset.

## 5. Main menu — `ui/main_menu.tscn`

### Node hierarchy

```text
MainMenu (Control, full rect)
├── Background (ColorRect)
├── Architecture (Control; custom primitive geometry)
├── TitleComposition (Control)
│   ├── OuterPlate (Control; clipped geometry)
│   ├── InnerBorder (Panel)
│   ├── Title (Label)
│   ├── Subtitle (Label)
│   ├── DividerLine (TextureRect)
│   ├── DividerPoint (TextureRect)
│   └── DiscoveryStar (TextureRect)
├── Navigation (Control)
│   ├── SectionLabel (Label)
│   ├── NewGame (PrimaryActionButton)
│   ├── Controls (SecondaryNavAction)
│   └── Exit (SecondaryNavAction)
├── HelixDiagram (Control; custom primitive geometry)
└── Footer (Label)
```

### Layout

| Node | Anchors / offsets | Position / size | z | Type / component | Texture / modulation | Interaction |
|---|---|---:|---:|---|---|---|
| `Background` | full rect | 0,0 / 640×360 | 0 | ColorRect | `dark_base` | None |
| `Architecture` | full rect | 0,0 / 640×360 | 1 | Control `_draw()` | dark geometry | None |
| `TitleComposition` | `O(0,0,462,124)` | 0,0 / 462×124 | 5 | Control / HybridHeader-derived | Geometry plus decorations | None |
| `OuterPlate` | local `O(36,28,420,96)` | 36,28 / 384×68 | 5 | Control | warm charcoal; gold border | None |
| `Title` | local `O(62,30,380,65)` | 62,30 / 318×35 | 7 | Label | warm cream | Runtime text `UKHUPACHA` |
| `Subtitle` | local `O(64,68,385,87)` | 64,68 / 321×19 | 7 | Label | muted green | Runtime text |
| `DividerLine` | local `O(148,99,268,107)` | 148,99 / 120×8 | 7 | TextureRect | TravelBook Line ×4 integer, gold | Decorative |
| `DividerPoint` | local `O(48,98,58,108)` | 48,98 / 10×10 | 7 | TextureRect | TravelBook Point ×2, purple | Decorative |
| `DiscoveryStar` | local `O(374,45,398,67)` | 374,45 / 24×22 | 8 | TextureRect | TravelBook Star ×2, purple | Decorative |
| `Navigation` | `O(54,145,324,259)` | 54,145 / 270×114 | 10 | Control | None | Focus group |
| `SectionLabel` | local `O(4,0,160,16)` | 58,145 / 156×16 | 10 | Label | gold | Runtime text |
| `NewGame` | local `O(0,17,270,67)` | 54,162 / 270×50 | 11 | PrimaryActionButton | Flat states green; play light gold | Default focus; pressed starts game |
| `Controls` | local `O(0,80,126,114)` | 54,225 / 126×34 | 11 | SecondaryNavAction | primitive warm row | Opens controls |
| `Exit` | local `O(140,80,266,114)` | 194,225 / 126×34 | 11 | SecondaryNavAction | primitive warm row | Exit request |
| `HelixDiagram` | `O(398,104,606,292)` | 398,104 / 208×188 | 4 | Control `_draw()` | green arcs, gold nodes | None; mouse ignore |
| `Footer` | `A(0,1,0,1) O(12,-20,180,0)` | 12,340 / 168×20 | 20 | Label | muted | Runtime/build metadata |

The Helix diagram is primitive geometry: two arcs, one vertical line, four circles, four horizontal rules, and one marker. It requires no PNG.

## 6. Equipment menu — `ui/equipment_menu.tscn`

### Node hierarchy

```text
EquipmentMenu (Control, full rect)
├── Background (ColorRect)
├── Header (HybridHeader)
├── LoadoutRail (PanelContainer)
│   ├── Frame (NinePatchRect)
│   ├── ActiveKitLabel (Label)
│   ├── ActiveSlots (HBoxContainer)
│   │   ├── WeaponSlot (EquipmentSlot)
│   │   └── ShieldSlot (EquipmentSlot)
│   ├── Divider (Control)
│   └── DiscoveredList (VBoxContainer of SecondaryNavAction/item rows)
└── ItemDossier (DossierPanel)
    ├── ItemHeader / ItemName / Category / Marker
    ├── TierBanner / TierLabel
    ├── DescriptionLabel
    ├── StatsPanel / StatRows
    └── EquippedButton
```

### Layout

| Node | Anchors / offsets | Position / size | z | Type / component | Texture / modulation | State/data |
|---|---|---:|---:|---|---|---|
| `Background` | full rect | 0,0 / 640×360 | 0 | ColorRect | dark base | None |
| `Header` | `A(0,0,1,0) O(0,0,0,46)` | 0,0 / 640×46 | 20 | HybridHeader | gold bottom rule; optional purple marker | Runtime title/count |
| `LoadoutRail` | `O(18,62,144,316)` | 18,62 / 126×254 | 5 | PanelContainer | Frame02, warm modulation, gold edge | Visible |
| `ActiveKitLabel` | local `O(16,14,110,31)` | 34,76 / 94×17 | 7 | Label | light gold | Runtime text |
| `ActiveSlots` | local `O(16,39,114,90)` | 34,101 / 98×51 | 7 | HBoxContainer | slot textures | Weapon selected; shield runtime |
| `Divider` | local `O(16,94,108,102)` | 34,156 / 92×8 | 7 | Control | gold line and endpoints | None |
| `DiscoveredList` | local `O(16,109,112,235)` | 34,171 / 96×126 | 7 | VBoxContainer | primitive rows | Only discovered items instantiated |
| `ItemDossier` | `O(158,62,620,316)` | 158,62 / 462×254 | 5 | DossierPanel | Frame02 neutral modulation | Selected item data |
| `ItemHeader` | local `O(18,14,342,64)` | 176,76 / 324×50 | 7 | Control | warm clipped geometry, gold edge | Runtime item |
| `TierBanner` | local `O(352,14,444,38)` | 510,76 / 92×24 | 8 | NinePatchRect | Banner03, gold modulation | Runtime tier label |
| `DescriptionLabel` | local `O(20,100,236,174)` | 178,162 / 216×74 | 8 | Label | cream, autowrap | Runtime description |
| `StatsPanel` | local `O(250,77,444,175)` | 408,139 / 194×98 | 8 | PanelContainer | primitive dark surface | Runtime stats/numbers |
| `EquippedButton` | local `O(274,198,440,236)` | 432,260 / 166×38 | 9 | PrimaryActionButton | green/gold/check | Equipped or actionable |

Discovered-only behavior: create or reveal rows only for discovered equipment. Do not show hidden names. All item names, tier text, descriptions, stat labels, values, and counts are Labels populated from game data.

## 7. Pause menu — `ui/pause_menu.tscn`

### Node hierarchy

```text
PauseMenu (Control, full rect, process mode ALWAYS)
├── Dimmer (ColorRect)
├── PauseHeader (HybridHeader/custom clipped plate)
├── SessionMetadata (VBoxContainer)
├── Navigation (Control)
│   ├── Resume (PrimaryActionButton)
│   └── UtilityRow (HBoxContainer)
│       ├── Controls (SecondaryNavAction)
│       ├── Retry (SecondaryNavAction)
│       └── MainMenu (SecondaryNavAction)
├── SessionRule (ColorRect)
└── SessionLabel (Label)
```

### Layout

| Node | Anchors / offsets | Position / size | z | Type / component | Texture / modulation | Interaction |
|---|---|---:|---:|---|---|---|
| `Dimmer` | full rect | 0,0 / 640×360 | 0 | ColorRect | `#0b0c0d` with ~82% opacity | Blocks gameplay input |
| `PauseHeader` | `O(0,0,474,153)` | 0,0 / 474×153 | 5 | HybridHeader/custom Control | warm clipped plate, gold divider | Runtime title |
| `SessionMetadata` | `O(450,32,580,90)` | 450,32 / 130×58 | 7 | VBoxContainer | gold/cream/green text; purple star | Runtime floor/depth |
| `Resume` | `O(52,181,350,235)` | 52,181 / 298×54 | 10 | PrimaryActionButton | Flat state textures green; play icon | Default focus; resume |
| `UtilityRow` | `O(52,252,476,286)` | 52,252 / 424×34 | 10 | HBoxContainer, separation 12 | None | Focus neighbors set explicitly |
| `Controls` | local 0,0 / 126×34 | 52,252 | 11 | SecondaryNavAction | primitive | Opens controls |
| `Retry` | local 138,0 / 126×34 | 190,252 | 11 | SecondaryNavAction | optional restart icon | Confirm then retry |
| `MainMenu` | local 276,0 / 148×34 | 328,252 | 11 | SecondaryNavAction | primitive | Confirm then main menu |
| `SessionRule` | `O(52,302,476,303)` | 52,302 / 424×1 | 8 | ColorRect | warm line | None |
| `SessionLabel` | `O(52,311,360,329)` | 52,311 / 308×18 | 8 | Label | muted | Runtime session status |

Pause must capture focus when shown, set `Resume` as default focus, and restore prior gameplay focus/input mode when closed. No script is created in this phase.

## 8. Puzzle terminal — `ui/puzzle_terminal.tscn`

### Node hierarchy

```text
PuzzleTerminal (Control, full rect)
├── Background (ColorRect)
├── Header (HybridHeader)
├── RelationWorkspace (PanelContainer)
│   ├── WorkspaceTitle (Label)
│   ├── RecoveredCount (Label)
│   ├── Cards (Control)
│   │   ├── PublicRecord (EvidenceCard)
│   │   ├── InternalClassification (EvidenceCard)
│   │   └── Anomaly (EvidenceCard)
│   ├── RelationPublicInternal (EvidenceRelation)
│   ├── RelationInternalAnomaly (EvidenceRelation)
│   └── FeedbackRow (HBoxContainer)
│       ├── RejectedFeedback (PanelContainer)
│       └── ValidFeedback (PanelContainer)
├── RecoveredKnowledge (RecoveredKnowledgePanel)
└── FooterCommands (HBoxContainer)
```

### Layout and state behavior

| Node | Anchors / offsets | Position / size | z | Type / component | Texture / modulation | State/data |
|---|---|---:|---:|---|---|---|
| `Background` | full rect | 0,0 / 640×360 | 0 | ColorRect | `#111315` | Always |
| `Header` | `A(0,0,1,0) O(0,0,0,48)` | 0,0 / 640×48 | 20 | HybridHeader | green rule | Runtime node/security state |
| `RelationWorkspace` | `O(18,58,622,260)` | 18,58 / 604×202 | 2 | PanelContainer | primitive base/border | Always |
| `WorkspaceTitle` | local `O(14,8,250,24)` | 32,66 / 236×16 | 4 | Label | gold | Runtime/static UI label |
| `RecoveredCount` | local `O(450,8,586,24)` | 468,66 / 136×16 | 4 | Label | muted | Runtime count |
| `PublicRecord` | local `O(14,33,178,127)` | 32,91 / 164×94 | 5 | EvidenceCard | Frame02 neutral; warm header | Normal/selected |
| `InternalClassification` | local `O(220,33,384,127)` | 238,91 / 164×94 | 5 | EvidenceCard | Frame02; gold selected edge | Selected/related |
| `Anomaly` | local `O(426,33,590,127)` | 444,91 / 164×94 | 5 | EvidenceCard | Frame02 warm/dark purple header; purple star | Anomaly/selected |
| `RelationPublicInternal` | local `O(178,71,220,87)` | 196,129 / 42×16 | 7 | EvidenceRelation | gold Line2D/nodes/arrow | Candidate/rejected history |
| `RelationInternalAnomaly` | local `O(384,71,426,87)` | 402,129 / 42×16 | 7 | EvidenceRelation | purple Line2D/nodes/arrow | Valid anomaly link |
| `RejectedFeedback` | local `O(14,143,243,181)` | 32,201 / 229×38 | 6 | PanelContainer | red primitive surface + Flat cross | Visible after invalid relation |
| `ValidFeedback` | local `O(264,143,590,181)` | 282,201 / 326×38 | 6 | PanelContainer | green primitive surface + Flat check | Visible on valid relation/unlock |
| `RecoveredKnowledge` | `O(18,274,622,328)` | 18,274 / 604×54 | 10 | RecoveredKnowledgePanel | TravelBook Popup warm; purple marker/star | Hidden until unlocked, then revealed |
| `FooterCommands` | `A(0,1,1,1) O(18,-20,-18,0)` | 18,340 / 604×20 | 20 | HBoxContainer | Labels only | Runtime bindings/status |

### Evidence interaction model

1. Each available `EvidenceCard` owns focus and emits `evidence_selected`.
2. First selection sets a relation origin and applies the selected gold edge.
3. Moving focus previews an `EvidenceRelation` in `candidate` state; confirming a second card requests evaluation.
4. Invalid evaluation shows `RejectedFeedback`, sets the relevant relation red, and keeps evidence available.
5. Valid evaluation shows `ValidFeedback`, sets the line green or purple according to its anomaly role, updates the unlocked state, and reveals `RecoveredKnowledgePanel`.
6. Public Record, Internal Classification, Anomaly, evidence titles, summaries, feedback text, recovered text, and counts are runtime Labels.

Relation lines must be `Line2D` plus primitive circle endpoints and polygon arrowheads inside `EvidenceRelation`. Do not pre-render relation PNGs. Set each line and arrow to mouse-filter ignore unless the relation itself is selectable.

## 9. Visual-order summary

For every screen, render in this order: background (`z=0`), architecture/large structural geometry (`z=1`), panel surfaces (`z=2–5`), internal decorative rules (`z=6–8`), interactive components (`z=10–12`), focus overlays (`z=15`), headers/context prompts/footer overlays (`z=20`). Tooltips or modal confirmation dialogs should begin at `z=30` within the same CanvasLayer or use a higher dedicated CanvasLayer.

## 10. Reproduction coverage

Every Hybrid Discovery v2 element maps to one of these runtime mechanisms:

- Selected PNG: Flat frames, banners, button states, slot states, progress textures, semantic icons, prompts, TravelBook popup/line/marker/point/star.
- Primitive geometry: clipped warm plates, architecture backdrop, gold dividers, focus borders, Helix diagram, rail backgrounds, item stat tracks, evidence relation graph, feedback surfaces, temporary sword/shield pictograms.
- Runtime Label: all titles, menu actions, item/evidence data, tier, descriptions, values, counts, prompt labels, terminal status, and recovered knowledge.

The mockup uses a system font only as a temporary visual guide. A final game font is outside this asset subset and must be assigned through a Godot Theme later.
