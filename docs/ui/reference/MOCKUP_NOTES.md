# UKHUPACHA UI Mockup Notes

All five images are 640×360 visual mockups. Source PNGs are only read by `generate_mockups.py`; none are overwritten. Recoloring and nearest-neighbor scaling are mockup-only compositing operations and preserve the source silhouette and pixel treatment.

## `hud.png`

- **Source assets:** Flat `Frame03a`, `Bar07a`, `BarFill01c/01d`, `FrameSlot03a`; TravelBook `IconHeart01a`, `IconEnergy01a`, `IconStar01a`, `Popup01a`, `CommandPress01a`, `Marker01a`, `Point01a`.
- **Reference influence:** `P5+3nq.png` for compact modular grouping; `book_VuIjJu.png` for popup/marker treatment.
- **Geometry used:** subtle gameplay-space placeholder, faint background diagonals, and no large UI surface.
- **Improvement:** vitals and loadout now read as authored edge clusters with real frames, slots and symbols; the interaction prompt is a layered popup rather than a plain rectangle.

## `main_menu.png`

- **Source assets:** TravelBook `BookCover01a`, `Marker01a`, `Line01a`, `Point01a`, play/arrow/home icons; Flat `Frame03a`, `Banner04a`, `InputField01a/02a`, `Select01a_2`.
- **Reference influence:** `book_VuIjJu.png` for cover depth and prominent banner; `book_xnX+Kr.png` for purposeful quiet space; `P5+3nq.png` for dominant-action contrast.
- **Geometry used:** faint background field and tiny diagonal atmosphere only.
- **Improvement:** a strong offset title plate, discovery-axis markers, one dominant action and a compact secondary group replace the generic centered stack.

## `equipment_menu.png`

- **Source assets:** TravelBook `BookCover01a`, both `BookPage` assets, `Frame01a`, `FrameSelect01a`, `Select01a`, `Slot01a`, `Line01a`, `Bar01a`, `Fill01a`, `Popup01a`, `IconStar01a`, `IconTick01a`; Flat `FrameSlot03a`.
- **Reference influence:** primarily `book_eaAPYF.png`, with selection and slot density from `book_VuIjJu.png`.
- **Geometry used:** background pattern only; the dossier, tabs, selection, stat bars, slots and note are asset surfaces.
- **Improvement:** it now reads as a designed expedition dossier with an explicit selected loadout, tier, equipped state, field kit, stats and recovered note—not a simple grid.

## `pause_menu.png`

- **Source assets:** TravelBook `BookCover01a`, `Popup01a`, `Marker01a`, play/home/gear/restart/cross icons; Flat `Frame03a`, `Banner04a`, `InputField01a/02a`, `Select01a_2`.
- **Reference influence:** `book_5Xdte4.png` for title/sheet hierarchy; `book_VuIjJu.png` for layered cover depth; main-menu mockup for family continuity.
- **Geometry used:** faint background field only.
- **Improvement:** Resume is unmistakably dominant, while four secondary actions share one framed shelf; the cover, title banner and side markers keep it related to the main menu.

## `puzzle_terminal.png`

- **Source assets:** Flat `Frame03a`, `FrameMarker01a/02a/03a`; TravelBook `Popup01a`, `Marker01a`, `Select01a`, `IconStar01a`, `IconTick01a`, `IconCross01a`, `Line01a`.
- **Reference influence:** `P5+3nq.png` and `book_6LG9Yl.png` for terminal structure; `book_xnX+Kr.png` for master-detail knowledge presentation; `book_VuIjJu.png` for evidence-card layering.
- **Geometry used:** the two relation connectors/arrows and subtle background field; these are the only functional lines without a suitable pack equivalent.
- **Improvement:** three distinct evidence cards, readable relation logic, simultaneous valid/false state chips, and a warm recovered-knowledge ledger create the most distinctive Hybrid Discovery screen.

