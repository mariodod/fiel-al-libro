# NEXT SESSION — Fiel al Libro

> Pick the project up here. Everything below is written so that you do not
> have to re-derive anything.
>
> Last updated: **2026-10-20** · after: *"Phase 1, weeks 1–2: the grey box, the reading
> rule, the first playtest, the Examine verb and the reactions"*

---

## 0. Where things stand — 30 seconds

| | |
|---|---|
| **Phase** | Phase 1. **Weeks 1–2 are done.** Week 3–4 (combat) has not started. |
| **The premise** | **Proven.** The playtest says so. |
| **The build** | `res://src/world/slice.tscn` — the main scene. Two primitives, one truth toggle, two characters reading the same world differently — and now **two verbs**: `E` to examine a thing, and a line of dialogue when the world moves under a character. |
| **Tests** | 13 suites, 226 assertions, green, enforced in CI. |
| **Commits** | `46f67c7` the grey box · `c0061f5` the first playtest · `630439c` the stranger's run and the T/L fix · `f5a3a39` the page turn · `76b995a` the reference texts · *(the Examine verb and the reactions)* |
| **The fun** | Not fully proven. Seven data points is a sample, not a signal. |

**The one thing that matters:** the mechanic is legible and liked. The *game* around it does
not exist yet. Do not spend another week proving the premise; it is proven. Spend the next
week making the premise into a game.

---

## 1. Read these first (10 minutes)

1. **`HANDOVER.md` §5** — the design in 90 seconds. §6 — where each decision lives in the
   code. §7 — the gotchas; every one of them cost real time, and two of them (the
   post-process never rendering, the tree root refusing children) were *silent*.
2. **`docs/PLAYTEST_NOTES.md` §6** — the findings. This is the most valuable document in
   the repository right now: eight "but"s, six of them fixed, two of them named.
3. **`docs/NEXT_STEPS.md` §2** — the plan. Week 1–2 is ticked; week 3–4 is the next
   milestone.
4. **`GDD.md`** — private, on this machine. §4 (the two truths), §7 (combat), §7.4
   (Ventures). If you have not read §4, read it now: everything below depends on it.

---

## 2. Run it

```bash
tools\play.cmd
```

| Key | |
|---|---|
| `WASD` / `Shift` | walk, run (camera-relative) |
| `TAB` | swap character — the camera cuts, the objects morph |
| `T` | the world's truth flips — **a page turns** |
| `E` | **examine the thing in front of you** — the two faces, and what each of you calls it |
| `V` | Sancho's second sight (off by default: the two readings disagree) |
| `L` | Quixote's Locura: Lucid ↔ Lost |
| `F1` / `F2` | help / the perception tags |

The three-beat demo, and the thing to judge: **`T`**, then **`TAB`**. The windmill becomes a
giant; through Sancho's eyes it is a windmill again; the tag above it says
*"Don Quijote: gigante"*. Same world, two readings.

**The new beat:** stand next to the rock and press **`E`**.

```
La roca
Realidad: roca · Libro: libro
Don Quijote: libro · Sancho: roca
```

The third line is recomputed every frame, so it moves when the world moves. And when a
character's reading changes, they say so — *"Don Quijote: ¡Un libro! ¡Mirad, un libro!
¿Quién lo ha puesto aquí?"*

---

## 3. The three things to do next, in this order

### A. A stranger who does not know the keys — **the owner's test, and the build is ready**

The stranger inferred what `T` did from its effect (*"expected change to be immediate"*).
That is a finding: the mechanic does not yet teach itself.

Give the build to somebody who has **never seen it and never been told what any key
does**. Do not explain. Write down what they do in the first thirty seconds, and
especially whether they find the *swap* on their own. If they do not, that is a tutorial
problem, and it is a week 3–4 problem.

The one new thing they will meet is the Examine prompt (`E — Examinar`). Watch what
they do with it.

### B. Week 3–4, task 2.5: the verbs

`PlayerController` has walk, run and a camera-relative direction. Before combat can be
anything but a numbers test it needs **dodge, lock-on and a soft camera**. The input map
already has the actions (`dodge`, `lock_on`, `block`); nothing reads them yet. This is
the rest of `docs/NEXT_STEPS.md` §2's 2.5, and it is the week 3–4 milestone.

### C. B3, the rest: the companion's chatter

The barks are heard now, and they fire when a character's reading changes. What is
missing is the *idle* chatter: lines about the thing in front of them, not a random draw
from a pool of two. The `TODO(Phase 1)` in `src/characters/companion_ai.gd` says exactly
this, and `Examine.find_target` is the tool: the AI can ask what it is looking at.

---

## 3b. What was just built, and is untested

Both of these came out of the first playtest, and **neither has been played by a
human**. They are the next run's material.

### B6 — the Examine verb

> *"Seeing the rock i wanted to interact with it, even more the book i expected to be
> able to interact with it and read it."* — run 6
> *"Wanted to interact with book and giant."* — the stranger

`E` near a thing, and the game tells you what it is: the object, the name each truth
gives it, and the name each of the two of you is calling it right now. The third line
is recomputed from the reading rule every frame, so it moves when the world moves.

`src/systems/examine.gd` (the rule) · `src/ui/examine_panel.gd` (the panel) ·
`src/characters/player_controller.gd` (the targeting).

**The question for the next run:** does the panel teach the two-truths idea, or does it
give it away too cheaply? A player who already knows the rock is a book in the Book's
reading has one less reason to press `T`.

### B5 — the reaction

> *"When quixote goes back to seeing reality some reaction from his side should happen."*

When a character's reading changes, they say so, with their name on it. The barks used
to be emitted into the void — `EventBus.toast` had **no listener at all** — so the
companion was a label and not a character. It is a character now.

`src/systems/reaction.gd` (the rule) · `src/ui/bark_line.gd` (the voice) ·
`src/world/slice.gd` (the trigger).

**The question for the next run:** does the reaction land, or is it a line in a corner?
And is the *pair* — the Book arriving and Reality coming back — the beat the playtest
asked for?

---

## 4. Then week 3–4 — combat

From `docs/NEXT_STEPS.md` §2, in the order listed there:

| # | Task |
|---|---|
| 2.5 | `PlayerController`: walk, run, dodge, lock-on, a soft camera |
| 2.6 | Combat: light combo, heavy, dodge, block/parry, stamina, poise, hit reactions |
| 2.7 | **Quixote rig** — silhouette, lance, 8 animations |
| 2.8 | **Sancho rig** — a *different* silhouette, sack + flail |
| 2.9 | Sancho's `Desvelar` — the form-swap VFX |
| 2.10 | The asymmetry rules: Humanity cost, Sancho's control kit |

**2.7 and 2.8 are the two most under-rated tasks in the plan.** Distinct animation sets sell
the asymmetry better than any mechanic. A reskinned Quixote makes the whole idea collapse.

**2.9 is the one the playtest is already asking for.** "Desvelar" — Sancho strips the Book
skin off a target and reveals its Reality form — is the best-feeling verb in the game, and
the playtest's *"I wanted to interact with the book"* is a player asking for it.

---

## 5. Do not do these yet

- **Do not build more primitives.** Two are enough to test the mechanic; a dozen built on
  an unproven premise is the most expensive way to find out the premise is wrong. (The
  premise is now proven — but the *content* still has to earn its place.)
- **Do not build the whole `Lectura` system.** GDD.md §6 is weeks 5–7: the eye-marks, the
  vantage points, the found fragments, the rewards. The Examine verb is the *verb* the
  system will grow out of, not a smaller version of it. Building the system now builds
  it against an unproven reading of what a reading is.
- **Do not cut the Locura meter.** It is pillar P2 and the stranger's "L" is the one
  untested lever in the build.
- **Do not touch `assets/manifiesto/_SAMPLE.bk_ch08.molinos.json`.** It is the format
  documentation and it has a content bug (below) that only the owner can decide on.
- **Do not add languages.** Three shipped; the remaining three are a month-4 problem.

---

## 6. If you only have an hour

1. Run the build. Play it for ten minutes with the tags **off** (`F2`).
2. Stand next to the rock, press `E`, and read the panel. Then press `T` and read it
   again: the third line has moved. That is the whole mechanic, in one panel.
3. Read `docs/PLAYTEST_NOTES.md` §6 and add a line to the observation log about what
   *you* feel now, after the fixes. Six lines is what the last one came to.
4. Open `TODO.md` and set three goals for the week. No more than three.

---

## 7. Known content bug, for the owner

**`assets/manifiesto/_SAMPLE.bk_ch08.molinos.json` has the wrong edition in its
`original_1605` field.** It carries the **1615** wording:

> *"…de los de lanza en astillero, **galera en coraza y bacía en el casco**."*

The **1605** original reads:

> *"…de los de lanza en astillero, **adarga antigua, rocín flaco y galgo corredor**."*

This is not a detail: **DLC 1 is *El Segundo Libro (1615)*** — the book the world keeps
rewriting itself into. Which edition a fragment comes from is load-bearing, and the
sample is the file every future fragment gets copied from. The sample's own rule 3 exists
to catch exactly this, and it needs a human with an edition.

The new fragment `assets/manifiesto/bk.ch01.apertura.json` (the one the page turn prints)
uses the verified 1605 wording, and it documents the difference. The sample has been left
alone on purpose: it is the owner's file, and it is their call whether the modern
renderings get re-sourced from the 1605 text too — they currently follow the 1615 incipit
as well.

### The reference texts are on disk

```bash
powershell -ExecutionPolicy Bypass -File tools\fetch_reference.ps1
```

| File | What it is |
|---|---|
| `reference\quijote_1605_parte1.txt` | the **1605 first part**, all 52 chapters, the *Curioso Impertinente* in its 1605 place, unwrapped for reading. **This is the copy the fragments are quoted from.** |
| `reference\quijote_1615_parte2.txt` | the 1615 second volume — the book the world rewrites itself into, and DLC 1's material. |
| `reference\quijote_1605_facsimil_ocr.txt` | OCR of the actual 1605 printing (Juan de Cuesta, Madrid 1605). Noisy — the long s is misread — so it is a **variant reference**, not a text to quote from. Use it to check a wording. |

`reference\` is gitignored: two megabytes of public-domain text is not a source.

**Rule 3 still applies.** Every fragment gets checked against an edition before it ships,
and the check is the owner's, not the machine's.

---

## 8. The command set

| | |
|---|---|
| `tools\play.cmd` | play the grey box (any scene: `tools\play.cmd res://…`) |
| `tools\play.cmd res://src/tools/shot.tscn` | **the screenshots** — writes `artifacts/shot_*.png` |
| `.\tools\godot.ps1 --headless res://tests/test_runner.tscn` | the tests |
| `.\tools\godot.ps1 --headless --editor --quit` | import (run after adding assets) |
| `.\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe` | build |
| `powershell -ExecutionPolicy Bypass -File tools\setup.ps1` | the one-command setup |

**If you changed a `.gdshader`, re-import before you run.** A game run does not re-import;
it uses the cached shader, and you will spend twenty minutes debugging a shader that is
not the one on disk. (`HANDOVER.md` §7.)
