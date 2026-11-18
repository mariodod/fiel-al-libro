# WORLD MAP — Fiel al Libro

> **Draft / In progress.** A hand-drawn map of Spain in the manner of a 1605 portolan, for
> the map screen the game will have between chapters. See GDD.md §11 (the
> world structure) and §11.4 ("The 'libro' map screen" — hand-drawn, the Book
> version and the Reality version side by side).

## The reference

The map lives at `docs/map/world_map.svg`, drawn at `1200×800` so it can be
redrawn at any size. It is deliberately derived from the **outline of Spain**
the player already knows — Galicia in the north-west, Andalusia in the south,
the Mediterranean shore on the right — so that placing a new region feels like
finding a place on a real map rather than dropping a blob onto an invented one.

## The five regions

Each region is a wash of the game's one palette (`docs/ANIMATION_BRIEF.md`
§2), placed at its true compass position:

| Region | Where it is on the map | What it is |
|--------|------------------------|------------|
| **I · El Camino de la Mancha** | centre, the open plains | Wheat fields, windmills, the first inn |
| **II · Sierra Morena** | the long southern wall of hills | Dry mountain, bandits, the Cave of Montesinos |
| **III · El Toboso y los Montes de Toledo** | south-central | Slow river country, the "enchanted" village |
| **IV · Los Riscos de Medinaceli** | north-east, the sheer cliffs | Fog, a Gothic church, the *Ensayo* |
| **V · El Castillo del Duque** | far north-east | Silk, mirrors, false chivalry |

## The route

A single dashed line — ochre, like a line drawn in ink — runs from La Posada
(the hub) through the regions and back. The player travels it chapter by
chapter; each stop is a Venture, a case, or nothing at all. Fast travel is a
"ride" cutscene between chapters (GDD.md §11.4), so the map never needs to be
seamless: it is a **sequence**, not a continent.

## The places that exist

- **La Posada** — the inn, the checkpoint, the Library shelf (GDD.md §11.1).
- **El molino de Montiel** — the first Venture, the slice, in Region I.
- **Montesinos** — the cave, Region II.
- **La iglesia** — the Gothic church in Los Riscos, Region IV.
- **El castillo del Duque** — false nobility, Region V.

Portugal, Castile, Aragon, Valencia and Andalusia are named around the edge
but are not places you can go — the world is Spain-shaped, not Spain.

## Two versions of everything

The map screen shows **two versions of each region side by side** — the Book
version and the Reality version — and filling it in is a collectible
(GDD.md §11.4). The Book version is gilded, inked-out, brighter; the Reality
version is desaturated, chalky. The SVG is drawn so both can be produced from
the same drawing: the regions are separate groups, so they can be recoloured
independently in the shader.

## The two readings (done)

GDD.md §11.4 wants the Book and Reality versions side by side. The map screen
now shows two maps at once, each drawing the same SVG through
`assets/shaders/map_variant.gdshader`:

| Map | Tint | Saturation |
|---|---|---|
| Reality | cool chalk `(0.94, 0.95, 0.93)` | 0.45 |
| Book | gilded ochre `(1.0, 0.86, 0.62)` | 1.35 |

Fragment markers are drawn on **both** maps (five each), so filling in the two
readings is the collectible. The region list still shows the current truth's
passage and swaps it on `T`.

## What is missing

- **A PNG export.** Godot loads the SVG directly today; a baked PNG at a fixed
  size would be safer for the map screen.

## Region records

All five region `.tres` files now carry a real `fragment_id` and (except
region IV) a `key_venture_id`. Four files previously used a stale
`fragment_key` property that `RegionData` never declared, so they had no map
marker at all. The values follow region I's pattern: the first fragment in the
region's chapter range, and the first key venture listed in GDD.md §11.2.
Region IV is left without a venture because the Ensayo is a case, not a Venture.

### Region pages enter the codex on `find_region`

GDD.md §20.1 calls one fragment per region "the passage that names the place".
`GameState.find_region()` now grants that region's `fragment_id` through
`GameState.grant_codex_page()`, which deduplicates and emits
`EventBus.codex_page_found` so the marker lights immediately. This covers the
two regions that have no Venture to drop a page — La Mancha's aperture and
Los Riscos' found manuscript — and makes the other three consistent rather
than dependent on a Book-truth Venture resolution. Venture page grants use the
same helper.

The aperture fragment was also given a filename matching its internal id
(`bk.ch01.apertura.01.json`); `ManifiestoFragment.path_for()` builds the path
as `<id>.json`, so an id and a filename that disagree make the page unreadable.
All references were updated.

Two map-screen bugs were fixed alongside this: markers were positioned by
looking up the region-position table with the *fragment* id instead of the
region id, and `MapContainer` was a `Node2D` with `set_anchors_preset()` called
on it — a Control-only method that aborted `_build_ui()` before any marker was
created. The container is now a `Control` with size flags, and all five markers
land on their region coordinates.

## Region passages (drafted)

Each region carries `book_fantasy_key` and `reality_fantasy_key` in its `.tres`
(`src/data/regions/`), pointing at `ui.region.<id>.book` / `.reality` in all six
locales. The map screen shows the passage for the current truth and swaps it on
`T`. The wording is a **draft**, like the Manifiesto fragments: it needs the
owner's pass against the novel before it is canonical. The keys and the wiring
are production.
