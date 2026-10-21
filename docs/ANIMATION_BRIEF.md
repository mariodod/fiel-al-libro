# THE ANIMATION BRIEF — the two hero rigs

> The brief for the rigs and the animation sets of 2.7 and 2.8, and for the
> hit reactions of 2.6. Written to be handed to an AI that can run Blender
> headless, and to be worked on by hand if it has to be.
>
> Last updated: **2026-10-21**

---

## 0. The tool is installed, and the first build is done

```
.\tools\blender.ps1 --version
.\tools\blender.ps1 -b --factory-startup -P tools\build_fiel_al_libro_animations.py
```

Blender **5.2.2 LTS**, Python 3.13, glTF exporter available (verified by a
headless smoke test: a rig, an action, a keyframe, exported to `.glb`).

`tools/blender.ps1` finds the binary wherever winget put it, exactly like
`tools/godot.ps1` does for Godot, and it runs from the repository root so a
script writes into *this* project.

**The first build is committed.** `tools/build_fiel_al_libro_animations.py`
builds both rigs and exports `assets/models/quixote.glb` and
`assets/models/sancho.glb`, with the editable masters in
`assets/models/blend/` (behind a `.gdignore`, because Godot's importer
would otherwise try to import the `.blend` and need a configured Blender
path). `tests/test_rigs.gd` pins the clips and the lengths.

### Three traps the first build fell into, and the rules that came out of them

1. **The frame rate.** The glTF exporter converts Blender *frames* into glTF
   *seconds* by dividing by the scene's frame rate, and Blender's default
   scene is 24 fps. A clip authored on a 30 fps grid and exported from a
   24 fps scene arrives **25 % long** — the engine reads seconds, so a
   0.45 s light attack plays as 0.58 s. The scene is now set to 30 fps
   before anything is authored, and the script **verifies the exported
   file** (§8, check 7) rather than the frames it wrote.
2. **Verify the artifact, not the intent.** Every other check measures what
   the script *meant* to write. The one that matters reads the `.glb` back
   and measures the seconds in the file, because that is what the engine
   will see.
3. **A clip must CONTAIN the window it covers.** The parry's window is
   0.18 s and the clip was 0.167 s: the animation ended while the game
   still thought the parry was open. Every clip now declares the window it
   covers, and the build fails if it is shorter.

### And two things the review found that a number cannot

- The **light attack's contact pose** had the lance pointing at the sky:
  a thrust is a rotation in the *horizontal* plane (the shoulder's Y), not
  a lift. The heavy's contact had it right; the light's did not, and the
  difference is one number in one keyframe.
- The two characters are visibly different men, which is the point of
  2.7 and 2.8: a gaunt nobleman with a lance and a basin, and a squat
  peasant with a sack and a flail.

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

- `parry` — **0.20 s (6 frames).** A sharp snap of the buckler up. It is
  the tightest window in the game and it has to look like a *decision*,
  not a flourish. Six frames, not five: the window is 0.18 s and the clip
  has to outlast it.
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
  animation sampling — **and set the scene to 30 fps before authoring**,
  because the exporter divides the frames by the scene's frame rate and
  Blender's default is 24 (see §0).
- The editable `.blend` masters go in `assets/models/blend/`, with a
  `.gdignore` beside them: Godot's importer would otherwise try to import
  the `.blend` too, and a `.blend` import needs a configured Blender path,
  which a headless build does not have.
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
7. **The exported files, measured in seconds.** Read the `.glb` back and
   check that every clip in the file is as long as the table says it is.
   This is the check that catches the frame-rate trap, and it is the only
   one that sees what the engine will see.
8. **Every clip covers the window it has to cover** — the roll the
   invulnerability, the hit reaction the reel, the stagger the punishment,
   the parry its window.

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

## 11. After the assets: the wiring — DONE

The rigs are in the game. The pawn drives the clips, and the mapping
from the game's states to the clip names is in
`src/characters/character_pawn.gd`:

| the game | the clip |
|---|---|
| standing | `idle` — or `idle_lost`, when Quixote's Locura has taken him |
| walking / running | `walk` / `run`, with the stride rate scaled to the ground actually covered |
| the dodge | `roll` |
| the light attack | `light_1` → `light_2` → `light_3`, by the step of the chain |
| the heavy attack | `heavy` |
| the guard | `block` — and `parry` for Sancho, whose buckler snaps up |
| a hit that landed | `hit` |
| a broken poise | `stagger` |
| the examine | `interact` |
| the Desvelar | `desvelar` |
| death | `death` |

The order of those is the order of importance: a dead character is
dead, a staggered one cannot act, a reeling one is hurt, an action is an
action, a dodge is a dodge, an attack is an attack, a guard is a guard,
and only then does the character walk or stand.

Three things that had to be got right:

- **The rig is a grandchild.** The AnimationPlayer is a child of the
  glb's root node, which is a child of the character. A search that
  only looks one level down finds nothing, and a character with no rig
  does not animate — quietly, and with no error anywhere.
- **The vertex colours have to be switched on.** Godot's glTF importer
  does not turn them on by itself, and the rigged characters paint
  themselves with them. Without that line the whole cast is the
  material's white.
- **The rig faces +Z, the game faces -Z.** glTF's convention is +Z
  forward and Blender's is -Y, so the exporter turns the model; the
  scene turns it back.

`tests/test_animation.gd` pins all of it: the rig is found, the idle
plays, the walk plays, the dodge rolls, the chain advances, the hit
flinches, the poise staggers, the guard guards, Sancho's guard parries,
the madness has its own posture, and an action holds the floor for its
length.

**What is still not done:** the *feel*. The clips are grey-box
animation, and the next pass is the art direction — the poses that read
as a Velazquez rather than as a fighting game.
