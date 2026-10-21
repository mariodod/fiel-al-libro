# THE ANIMATION BRIEF — the two hero rigs

> The brief for the rigs and the animation sets of 2.7 and 2.8, and for the
> hit reactions of 2.6. Written to be handed to an AI that can run Blender
> headless, and to be worked on by hand if it has to be.
>
> Last updated: **2026-10-21**

---

## 0. The tool is installed

```
.\tools\blender.ps1 --version
.\tools\blender.ps1 -b --factory-startup -P <script.py> -- --out assets\models
```

Blender **5.2.2 LTS**, Python 3.13, glTF exporter available (verified by a
headless smoke test: a rig, an action, a keyframe, exported to `.glb`).

`tools/blender.ps1` finds the binary wherever winget put it, exactly like
`tools/godot.ps1` does for Godot, and it runs from the repository root so a
script writes into *this* project.

**Do not retarget and do not share actions between the two characters.** The
design document says it twice, and it is the whole point of 2.7 and 2.8:
*"Distinct animation sets sell the asymmetry better than any mechanic. A
reskinned Quixote makes the whole idea collapse."*

---

## 1. What you are expected to produce

A **headless Blender 5.x Python script** (or a small set of them) that builds
two humanoid rigs, authors the animation sets on them, and exports one `.glb`
per character.

Not a description, not a plan, not a tutorial: **runnable scripts, and the
`.glb` files they produce.** Blender is free and it has everything needed —
no ZBrush, no Marvelous, no Substance, no paid asset packs. Mixamo (free) may
be used as a *reference for proportions* only; the clips below must be
hand-authored on our own skeleton.

## 2. The look

> **"Gouache on plaster"** — the world looks like a 16th-century Spanish
> painting that has started moving. Warm ochres and bone whites, olive scrub,
> iron grey, dried-blood accents. Not grimdark. Not photoreal. *Lit*, and a
> little bit dry. (GDD.md §15.1)

Reference stack, in order: **Goya** (*Los Caprichos*, *Los Disparates*, *El
sueño de la razón*), **Velázquez** (the buffoons, the dwarfs — nobility as
performance), **Navarrete el Mudo / Sánchez Coello / Juan de Flandes** (the
actual look of 16th-c. Spain), **El Greco's Spanish period** (the vertical,
the elongated), **Okami** (the ink line, the flat colour), **Sable** (low-poly
stylised with painted texture), **Hellblade** (a mental state rendered as a
layer over reality).

**Rules that make this achievable solo** (GDD.md §15.2):

- **Silhouette first.** No face detail at all below 3 m; costume and hat do
  the work.
- **Low-poly + hand-painted textures + triplanar materials.** 200–800 tris per
  character, 2K painted textures, one shared triplanar material.
- **Vertex colour for art direction.** Tweak mood per region without new
  textures.
- **One shader family for the whole game.** The truth-layer shader is applied
  to every material; change the world by changing a uniform, not by making new
  assets.
- **The line-art pass does the heavy lifting** for "painterly" — a
  screen-space edge shader in ink is 200 lines and instantly makes low-poly
  read as illustration.

### Palette

Use only these, and vary them in value and hue rather than by adding new
colours:

`#C08A3E` ochre · `#8A5A28` dark ochre · `#E8DCC0` bone white · `#C9B896`
dirty bone · `#6E7345` olive · `#4A4E2E` dark olive · `#4C4A46` iron grey ·
`#2E2C2A` black iron · `#7A2E22` dried blood · `#6B4A2C` wood · `#8A8C90`
steel

## 3. The two characters

Legible as **different men** from twenty metres away, with the sound off.

### Don Quixote — *El de la Espalda Dorsada* (GDD.md §5.1)

A gaunt, threadbare nobleman. Front-line fighter with terrible tactical
sense.

- **Tall and thin.** All elbows.
- A **lance** (long, two-handed, worn) and a **broken sword** at his hip.
- A **basin** on his head — a rusted barber's basin, the Mambrino helmet of
  the novel. This is his silhouette; it must read instantly.
- Faded nobleman's clothes: a dusty **ochre** doublet gone grey at the
  elbows, **bone-white** sleeves, an **iron-grey** strap across the chest, a
  **dried-blood** stain on one sleeve that never comes off.
- He fights as a man who believes he is a knight: committed, wide, and
  slightly too slow.

### Sancho Panza — *El de la Insignia* (GDD.md §5.2)

A stout, practical peasant squire. Control and deception, not force.

- **Short and round**, the opposite build to Quixote. Wide stance, low centre
  of gravity.
- A **sack** on his back — his luggage, his job, his whole station in life.
- A **flail** — a short chain with a heavy ball — in his right hand.
- An **olive** tunic, **brown** leather, sunburnt skin. Nothing about him is
  elegant.
- He fights like a man who has been in a few scuffles: unglamorous,
  practical, and he **parries**.

## 4. The rig

- A simple humanoid skeleton, ~16 bones, Mixamo-like readable names so
  Mixamo reference clips stay usable: `root`, `hips`, `spine`, `chest`,
  `neck`, `head`, `shoulder_l/r`, `upperarm_l/r`, `forearm_l/r`, `hand_l/r`,
  `thigh_l/r`, `shin_l/r`, `foot_l/r`.
- **The bone names must be identical in both characters**, so the game code
  can address them the same way. The *animations* must not be.
- Weapons and props parent to a hand bone (or a dedicated `weapon_r` bone for
  the flail's chain, so the ball can swing on its own).
- 200–800 triangles per character. Low-poly, hard-edged, no smoothing across
  more than 30°, no subdivision, no hair cards, no cloth sim.
- **Vertex colours are the art-direction channel.** If you add textures they
  must be 2K, tileable, hand-painted in the gouache style, and must **not**
  bake in any lighting, ambient occlusion or shadow — the game has one sun,
  one ambient sky, and a screen-space ink-outline pass. Everything must read
  in flat colour.

## 5. The clips, and the timings they must hit

**These timings are not artistic preferences — they are the game's numbers.**
The combat code opens a hitbox and an invulnerability window on exact
frames, and the animations have to land inside them or the game will look
wrong. Every duration below is a literal constant from the game's data files.

### Both characters

| clip | length | notes |
|---|---|---|
| `idle` | 2.0 s loop | breathing, weight shifting, the weapon at rest. NOT a statue. |
| `walk` | 0.9 s loop | matches a 4.2 m/s ground speed. |
| `run` | 0.62 s loop | matches 6.8 m/s. |
| `roll` | **Quixote 0.25 s / Sancho 0.40 s** | The dodge. See below — the two are not the same move. |
| `light_1` | 0.45 s | **Contact frame at 0.08 s.** |
| `light_2` | 0.45 s | **Contact frame at 0.08 s.** |
| `light_3` | 0.45 s | **Contact frame at 0.08 s.** |
| `heavy` | 0.90 s | **Contact frame at 0.12 s.** |
| `block` | 0.20 s into a hold | The guard comes up in 0.20 s. |
| `hit` | **Quixote 0.35 s / Sancho 0.25 s** | The flinch. The knockback is at frame 0. |
| `stagger` | **Quixote 1.3 s / Sancho 1.5 s** | The poise breaking. The character goes down and cannot act. |
| `death` | 1.2 s | A fall, not a collapse. |
| `interact` | 1.2 s | The Examine gesture: leaning in, reading. |

### Quixote only

- `idle_lost` — 2.0 s loop, the madness idle (Locura ≥ 50). He is not
  menacing; he is *certain*. Shoulders up, chin up, the lance held like a
  banner.

### Sancho only

- `parry` — **0.18 s.** A sharp snap of the buckler up. It is the tightest
  window in the game and it has to look like a *decision*, not a flourish.
- `desvelar` — 0.6 s. A forward gesture with the sack, as if throwing
  something at a thing. It strips the Book skin off a target for 8 seconds.

### The rules the timings encode — read this before animating anything

- **The contact frame** is the frame the weapon passes through the target.
  The hitbox opens 0.04 s after the button press and lives 0.12 s (light) or
  0.16 s (heavy). So the light's contact must be between 0.04 s and 0.16 s,
  and the heavy's between 0.04 s and 0.20 s. Put the contact at 0.08 s and
  0.12 s respectively. **Do not let the contact drift off the frame** — the
  game resolves the hit from a timer, not from your keyframes.
- **The chain** (`light_1 → light_2 → light_3`) is a 0.8 s window and the
  player's button cooldown is 0.45 s, so the second and third swings can
  begin while the first is still recovering. Author them so the chain reads
  as **one continuous motion**: `light_2` must begin from `light_1`'s
  recovery pose, and `light_3` from `light_2`'s. Each step is harder than
  the last (14 → 20 → 26 damage).
- **The dodge is the whole point of the two characters.** Quixote's roll
  covers **4 m in 0.25 s** — a fast, panicked lunge that ends upright and
  slightly overcommitted. Sancho's covers **2 m in 0.40 s** — a slow, heavy
  tumble that ends on one knee. They are not the same animation at different
  speeds. The character is **invulnerable for exactly the clip's length**, so
  the body must be committed for the whole of it.
- **The parry window is 0.18 s from the moment the guard goes up.** `block`
  and `parry` must be authored so that the first 0.18 s of the guard is the
  parry — a crisp "catch", not a slow lean.
- The **stagger** is a real punishment: 1.3–1.5 s of nothing.

## 6. Motion style

- **Weight and gravity.** Two men in heavy clothes in the heat. Nothing
  floats.
- **Deliberate, not snappy.** The timing of the reference is Spanish
  16th-century: a held pose, a turn of the head, a slow lowering of a spear.
  No squash-and-stretch, no anime snappy timing, no "gamey"
  anticipation-and-snap.
- **A little dry.** The emotion is underneath. Quixote's grandness and
  Sancho's practicality are in the *timing* of a gesture, not in a facial
  expression — there are no faces.
- Read the whole thing as **a 16th-century painting that has started
  moving**. If a clip could be a still from a Velázquez painting, it is
  right; if it could be a fighting game, it is wrong.

## 7. Export contract

- One file per character: `assets/models/quixote.glb` and
  `assets/models/sancho.glb`. Each contains the mesh, the rig, and **all its
  clips as separate named actions**, with the action names exactly as in the
  tables above.
- Export settings: apply transforms; **mesh compression disabled** (it
  destroys vertex colours); materials extracted; no LOD stripping; 30 fps
  animation sampling.
- Also write the `.blend` sources to `assets/models/` — they are the
  editable master.
- Do not generate textures or write anything into `assets/textures/`.
- `.blend` and `.glb` are **LFS-tracked**; the `.import` sidecars are
  committed as plain text (TECH_STACK.md §4.1).

## 8. Before you finish: print a report and check it

The script must print a table and fail loudly (non-zero exit) if any of these
is false:

1. Triangle count per character is between 200 and 800.
2. Every clip exists, and its length is within 2 frames of the table above.
3. Every light clip's contact frame is inside `[0.04 s, 0.16 s]`; every heavy
   clip's is inside `[0.04 s, 0.20 s]`.
4. Quixote's `roll` is 0.25 s and Sancho's is 0.40 s, and the two clips are
   **not** the same motion (compare the joint angles at the midpoint and
   assert they differ).
5. The two characters share **no action data** for any clip name they have in
   common.
6. The bone names are identical in both rigs.

Then write a short `assets/models/README_animations.md` naming each clip, its
length, its contact frame, and one line on what the pose is doing.

## 9. What is NOT in this task

- No faces, no eyes, no hair, no cloth simulation.
- No mount clips (Rocinante, Dapple) — separate task.
- No NPC or enemy clips — separate task.
- No sound, no music, no VFX.
- No changes to the game's code, data or scene files. Assets only.

## 10. When you are done

Report: the two `.glb` paths, the triangle counts, the full clip table with
contact frames, the verification output, and a short list of anything you had
to decide that this brief did not pin down — the owner will want to review
those choices, not discover them.

---

## 11. After the assets: the wiring

The rigs are useless until the game plays them, and that is a **code** task,
not an art one:

- `src/characters/character_pawn.gd` is a `CharacterBody3D` with **no
  `AnimationPlayer`** yet. It needs one, an `AnimationTree` or a small state
  machine, and the mapping from the states the code already has to the clip
  names above: `idle`, `walk`, `run`, `roll`, `light_1/2/3`, `heavy`, `block`,
  `parry`, `hit`, `stagger`, `death`, `interact`, `desvelar`, `idle_lost`.
- The state machine must read the **same numbers** the animation was authored
  against: the dodge's i-frames, the attack's active window, the stagger's
  duration, the parry's window.
- The prop meshes currently in `src/world/slice.tscn` (the lance, the basin,
  the sack, the flail) are placeholders and should be replaced by the
  rigged ones.
- The truth-layer shader is applied to every material, so the rigged
  characters must keep the **same material family** as the rest of the game.
