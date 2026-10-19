# NEXT SESSION — Fiel al Libro

> Pick the project up here. Everything below is written so that you do not
> have to re-derive anything.
>
> Last updated: **2026-10-19** · after: *"Phase 1, weeks 1–2: the grey box, the
> reading rule, and the first playtest protocol"*

---

## 0. Where things stand — 30 seconds

| | |
|---|---|
| **Phase** | Phase 1. **Weeks 1–2 are done.** Week 3–4 (combat) has not started. |
| **The premise** | **Proven.** The playtest says so. |
| **The build** | `res://src/world/slice.tscn` — the main scene. Two primitives, one truth toggle, two characters reading the same world differently. |
| **Tests** | 11 suites, 187 assertions, green, enforced in CI. |
| **Commits** | `46f67c7` the grey box · `c0061f5` the first playtest · `630439c` the stranger's run and the T/L fix · *(the page turn)* |
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
| `V` | Sancho's second sight (off by default: the two readings disagree) |
| `L` | Quixote's Locura: Lucid ↔ Lost |
| `F1` / `F2` | help / the perception tags |

The three-beat demo, and the thing to judge: **`T`**, then **`TAB`**. The windmill becomes a
giant; through Sancho's eyes it is a windmill again; the tag above it says
*"Don Quijote: gigante"*. Same world, two readings.

---

## 3. The three things to do next, in this order

### A. The Examine verb — **highest priority, do this first**

> *"Seeing the rock i wanted to interact with it, even more the book i expected to be
> able to interact with it and read it."* — run 6
> *"Wanted to interact with book and giant."* — the stranger

**Two independent people, one of them a stranger, reached for the thing that surprised
them.** It was scheduled for week 5–7. Pull it forward.

**The cheapest version that answers the note** (do this one, not the whole `Lectura`
system): the player walks up to an object and presses `E`, and the game tells them what
the object is — in *their* truth and in the other one.

```
A rock.                            ← what you see
He would call it a book.           ← what the other one sees
```

Most of the data already exists: `TruthObjectData.reality_name_key` /
`book_name_key` are the names in each truth, and `EventBus.lectura_entered` /
`anamorphosis_spotted` are already wired for the real system.

Where it goes: a raycast in `PlayerController` (there is a `TODO(Phase 1)` for exactly
this), a small UI panel, and a `TruthObject` method that returns the two names. **One
afternoon.**

Why it is first: a player who cannot touch the thing that made them curious will not come
back. This is the difference between a demo and a game.

### B. A stranger who does not know the keys

The stranger inferred what `T` did from its effect (*"expected change to be immediate"*).
That is a finding: the mechanic does not yet teach itself.

Give the build to somebody who has **never seen it and never been told what any key
does**. Do not explain. Write down what they do in the first thirty seconds, and
especially whether they find the *swap* on their own. If they do not, that is a tutorial
problem, and it is a week 3–4 problem.

### C. Quixote's reaction — B5, the barks

> *"When quixote goes back to seeing reality some reaction from his side should happen."*

When Quixote stops being able to see the giant, something has to happen **on his side**:
a bark, a line, a beat. The mechanic is proven; this is about making it a *character*.

The companion AI already has a bark pool (`CompanionAI._maybe_bark`) and `EventBus.toast`
exists. The barks have to be about *what they are looking at*, not generic.

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
- **Do not cut the Locura meter.** It is pillar P2 and the stranger's "L" is the one
  untested lever in the build.
- **Do not touch `assets/manifiesto/_SAMPLE.bk_ch08.molinos.json`.** It is the format
  documentation and it has a content bug (below) that only the owner can decide on.
- **Do not add languages.** Three shipped; the remaining three are a month-4 problem.

---

## 6. If you only have an hour

1. Run the build. Play it for ten minutes with the tags **off** (`F2`).
2. Read `docs/PLAYTEST_NOTES.md` §6 and add a line to the observation log about what
   *you* feel now, after the fixes. Six lines is what the last one came to.
3. Open `TODO.md` and set three goals for the week. No more than three.

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

---

## 8. The command set

| | |
|---|---|
| `tools\play.cmd` | play the grey box (any scene: `tools\play.cmd res://…`) |
| `.\tools\godot.ps1 --headless res://tests/test_runner.tscn` | the tests |
| `.\tools\godot.ps1 --headless --editor --quit` | import (run after adding assets) |
| `.\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe` | build |
| `powershell -ExecutionPolicy Bypass -File tools\setup.ps1` | the one-command setup |

**If you changed a `.gdshader`, re-import before you run.** A game run does not re-import;
it uses the cached shader, and you will spend twenty minutes debugging a shader that is
not the one on disk. (`HANDOVER.md` §7.)
