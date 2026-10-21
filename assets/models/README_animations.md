# Fiel al Libro — Hero Animations & Rig Specification

> Art Direction: **"Gouache on plaster"** (16th-century Spanish painting moving).
> Assets built headless for Godot 4.7 souls-like action RPG.

## Models Produced
- `quixote.glb` / `quixote.blend` — Don Quixote (*El de la Espalda Dorsada*), gaunt nobleman, lance & Mambrino basin.
- `sancho.glb` / `sancho.blend` — Sancho Panza (*El de la Insignia*), stout squire, sack, flail & buckler.

---

## 1. Don Quixote Animation Set

| Clip | Length | Contact Frame | Action Description |
|---|---|---|---|
| `idle` | 2.00 s (60 f) | — | Gaunt breathing, subtle weight shift from heel to toe, lance rested at shoulder |
| `idle_lost` | 2.00 s (60 f) | — | Locura >= 50 madness idle. Shoulders up, chin raised proud, lance held aloft like a banner |
| `walk` | 0.90 s (27 f) | — | Long, deliberate, slightly gangly strides matching 4.2 m/s |
| `run` | 0.62 s (19 f) | — | Urgent gangly gallop matching 6.8 m/s, tall frame bobbing |
| `roll` | 0.25 s (8 f) | — | 4 m fast panicked forward lunge, ending upright and overcommitted |
| `light_1` | 0.45 s (14 f) | 0.08 s (f2) | Committed lance thrust forward; recovers with lance pushed low to the right |
| `light_2` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_1: rising diagonal sweep across body to upper-left |
| `light_3` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_2: heavy two-handed downward plunge straight forward |
| `heavy` | 0.90 s (27 f) | 0.12 s (f4) | Wide two-handed horizontal cleaving sweep; massive arc and recovery |
| `block` | 0.20 s (6 f) | — | Brings lance diagonally across chest with both hands into guard hold |
| `hit` | 0.35 s (11 f) | — | Sharp flinch with knockback at frame 0, staggers back trying to maintain dignity |
| `stagger` | 1.30 s (39 f) | — | Poise break: drops to knees, lance tip scrapes dirt, slow agonizing recovery |
| `death` | 1.20 s (36 f) | — | A knight's fall: drops straight back with one hand on lance, motionless on ground |
| `interact` | 1.20 s (36 f) | — | Examine gesture: tall frame bends deeply forward, peering down with scholarly intensity |

---

## 2. Sancho Panza Animation Set

| Clip | Length | Contact Frame | Action Description |
|---|---|---|---|
| `idle` | 2.00 s (60 f) | — | Low wide stance, belly breathing, flail hanging loose, looking around suspiciously |
| `walk` | 0.90 s (27 f) | — | Short quick waddling peasant steps matching 4.2 m/s |
| `run` | 0.62 s (19 f) | — | Heavy determined trot matching 6.8 m/s, leaning forward against luggage sack |
| `roll` | 0.40 s (12 f) | — | 2 m heavy somersault tumble, tucking into ball and landing on one knee |
| `light_1` | 0.45 s (14 f) | 0.08 s (f2) | Practical horizontal flail sweep from right to left, wrapping flail to left flank |
| `light_2` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_1: backhand flail whip back from left to right |
| `light_3` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_2: heavy overhead downward flail smash into dirt |
| `heavy` | 0.90 s (27 f) | 0.12 s (f4) | Heavy overhead wind-up slamming entire body weight into flail impact |
| `block` | 0.20 s (6 f) | — | Snaps buckler on left forearm up into high guard position |
| `parry` | 0.18 s (5 f) | — | Crisp forward punch snap of buckler to deflect incoming blow |
| `hit` | 0.25 s (8 f) | — | Practical grunt flinch absorbing impact into shoulders/sack, fast recovery |
| `stagger` | 1.50 s (45 f) | — | Poise break: knocked onto backside, weighed down by sack, scrambling up |
| `death` | 1.20 s (36 f) | — | Collapses heavily sideways under sack weight before going limp |
| `interact` | 1.20 s (36 f) | — | Practical examination: squints, squats low, inspects by poking forward |
| `desvelar` | 0.60 s (18 f) | — | Reaches back to sack and flings arm forward in unveiling gesture (strips Book skin 8s) |

---

## 3. Technical Constraints & Verification Summary
- **Geometry**: Quixote (540 tris), Sancho (620 tris) — within 200–800 limit.
- **Coloring**: Vertex colors in linear RGB matching gouache palette (`#C08A3E`, `#6E7345`, `#4C4A46`, etc.). No texture maps.
- **Skeleton**: 21 bones, human-readable Mixamo-compatible naming identical on both rigs.
- **Asymmetry**: Zero shared action datablocks; all animations hand-authored with distinct movement styles.
