# WORLD MAP — Fiel al Libro

> **Draft.** A hand-drawn map of Spain in the manner of a 1605 portolan, for
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

## What is missing

- **The Book/Reality read of each region.** The SVG has one wash per region;
  the game needs two. That is the point of drawing it in vector: the wash can
  be swapped for a shader uniform instead of redrawn.
- **The region fragments.** GDD.md §20.1: one passage per region that names
  the place and sets the register. The map is where they live, but the writing
  is the owner's.
- **A PNG export.** Godot can load the SVG directly, but a baked PNG at a
  fixed size is safer for the map screen.
