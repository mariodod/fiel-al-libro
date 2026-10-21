# NEXT SESSION — Fiel al Libro

> Pick the project up here. Everything below is written so that you do not
> have to re-derive anything.
>
> Last updated: **2026-10-20** · after: *"Phase 1, weeks 1–2: the grey box, the
> reading rule, the first playtest, the Examine verb and the reactions"* +
> *"the second playtest: the Examine panel gives the mechanic away, and the
> dodge cannot be judged without an enemy and a wall"*

---

## 0. Where things stand — 30 seconds

| | |
|---|---|
| **Phase** | Phase 1. **Weeks 1–2 are done.** Week 3–4 (combat) is under way. |
| **The premise** | **Proven.** The playtest says so. |
| **The build** | `res://src/world/slice.tscn` — the main scene. Two primitives, one truth toggle, two characters reading the same world differently — and now the **verbs**: `E` to examine, `Space` to dodge, a light attack that chains, a heavy attack, `F` for the guard, `M` to lock on, `X` for Sancho's Desvelar, and a line of dialogue when the world moves under a character. The two characters are **rigged and animated** (14 clips each), the **companion is in the fight** (it fights what you are locked onto, and it parries), there is a **walled yard** with a training dummy and a straw man in it, and to the **south** there is the **era of Montiel** and the **Venture of Montiel** — the first boss, in two forms. |
| **Tests** | 24 suites, 529 assertions, green, enforced in CI. |
| **The fun** | Not fully proven. Seven data points is a sample, not a signal. |

**The one thing that matters:** the mechanic is legible and liked. The *game*
around it does not exist yet. Do not spend another week proving the premise;
it is proven. Spend the next week making the premise into a game.

---

## 1. Read these first (10 minutes)

1. **`HANDOVER.md` §5** — the design in 90 seconds. §6 — where each decision
   lives in the code. §7 — the gotchas; every one of them cost real time.
2. **`docs/PLAYTEST_NOTES.md` §6** — the findings. This is the most valuable
   document in the repository right now: nine "but"s, six of them fixed, and
   the two newest ones (§7) are what this session is about.
3. **`docs/NEXT_STEPS.md` §2** — the plan. Week 1–2 is ticked; week 3–4 is the
   current milestone.
4. **`GDD.md`** — private, on this machine. §4 (the two truths), §7 (combat).
   If you have not read §4, read it now: everything below depends on it.

---

## 2. Run it

```bash
tools\play.cmd
```

| Key | |
|---|---|
| `WASD` / `Shift` | walk, run (camera-relative) |
| `TAB` | swap character — the camera cuts, the objects morph |
| `T` | the world's truth flips — **Quixote only**. Sancho cannot turn the world over. |
| `E` | **examine the thing in front of you** — *what this character sees* |
| `Space` | **dodge** — a burst, a window of invulnerability, stamina |
| `LMB` / `RMB` | **light attack / heavy attack** — the light one chains three |
| `F` | **the guard** — hold it. Sancho's buckler parries; Quixote's lance cannot |
| `M` | **lock on** — the target you are looking at; the camera frames both |
| `X` | **Desvelar** — Sancho strips the Book skin off a thing, for eight seconds |
| `K` | reset the yard (the dummy, the straw man, and anyone who fell) |
| `V` | Sancho's second sight (off by default: the two readings disagree) |
| `L` | Quixote's Locura: Lucid ↔ Lost |
| `F1` / `F2` / `H` | help / the perception tags / the HUD |

**The new beat:** walk west, into the **walled yard**, and swing at the
**training dummy**. It telegraphs, it hits back, and the walls mean you cannot dodge
forever. That is the rig the dodge has been missing.

**The newest beat:** walk **south**, to the era of Montiel, and fight the
**windmill Venture**. It has two forms and they are two different fights: as a **mill**
it does not move, its sails deny the ground within four metres, and it topples with a
long, readable tell; as the **giant** it walks, it reaches further than your roll, and
it has half the health. Press `T` as Quixote and the world turns over — and the Venture
turns with it. Swap to Sancho and press `X`: the Book skin comes off, the Venture is
back in its Reality form for eight seconds, and the swing it was in the middle of never
arrives. The squire does not kill. He controls.

**The changed beat:** `E` no longer prints a truth table. It prints **what the
character sees** — a description, the text on the page if it is a book, and the
one detail that does not add up.

---

## 3. The three things to do next, in this order

### A. A stranger who does not know the keys — **the owner's test, and the build is ready**

The stranger inferred what `T` did from its effect (*"expected change to be
immediate"*). That is a finding: the mechanic does not yet teach itself.

Give the build to somebody who has **never seen it and never been told what any
key does**. Do not explain. Write down what they do in the first thirty
seconds, and especially whether they find the *swap* on their own. If they do
not, that is a tutorial problem, and it is a week 3–4 problem.

**Press `H` before you hand it over.** The HUD is the developer's readout; it
spells out both readings. A stranger must not have it. `F2` hides the floating
tags as well.

### B. Week 3–4, task 2.5: the soft camera, and 2.6: a real fight

What is in: walk, run, a soft camera, the dodge (a burst, a window of
invulnerability, stamina that comes back), a light attack that **chains
three** (14 → 20 → 26), a heavy attack, the **guard** (`F`) and the
**parry** (Sancho's buckler can; Quixote's lance cannot), the **poise**
and the stagger it causes, the training dummy, the walled yard, the
**lock-on** (`M`): the target you are looking at, the character turning
towards it and walking around it, and the camera framing both — and
**2.9, Desvelar** (`X`): Sancho strips the Book skin off a thing for
eight seconds, and both characters see its true form.

**And 2.10, the asymmetry rules**, which are what the whole combat design
is built on: Quixote **cannot harm the innocent** (the blow does not
land, and it costs 20 Humanity), Sancho **cannot meaningfully damage an
enemy** (40 % of the damage, all of the poise — he staggers, he does not
kill). The yard shows both: a **straw man** for the first, and a dummy
that only Quixote can break for the second.

**And 2.11, the Venture of Montiel**, the first boss, in the era to the south: two
forms, two movesets, and the two levers that change the shape of the fight — the
knight's `T` (the world's truth IS the boss's truth) and the squire's `X` (the Desvelar
puts the boss back in its Reality form and cancels the swing it was in the middle of).
The fight is the first thing in the game that asks the player to *use the asymmetry as a
plan* rather than as a rule.

What is not in: the **animations**. 2.7 and 2.8 want eight clips each,
and the hit reactions want to be animations rather than a flash and a
push. That is the next real piece of work, and it is not code.

**Before any of it: a minute in the yard.** The chain, the guard, the
parry, the poise, the straw man and the Desvelar are all in, and all the
numbers are data. The question is whether **swapping to Quixote to break
the dummy** feels like the answer it is meant to be, and whether the
straw man makes the player hesitate. The dodge's own numbers are settled
for now — 4 m for Quixote, 2 m for Sancho, and a quarter of a second of
invulnerability for the knight, who is not a fighter.

### C. B3 — the companion's chatter: DONE, and it needs a run

The idle barks were a random draw from a pool of two. The companion now
says something **about the thing it is looking at** — the rock, the mill,
the dummy — and about what the player is doing: locked onto something, or
on the ground. The rule is one line: *a line about the thing, or an idle
line, never the same thing twice in a row.*

What is missing is **content**: the idle pool is three lines a character,
and the game has a hundred objects. The rule survives; the content does
not. `src/systems/chatter.gd` is where the next hundred lines go.

---

## 4. Then week 3–4 — the rest of combat

| # | Task |
|---|---|
| 2.5 | The **soft camera** and the **lock-on** (`M`) — ✅ done |
| 2.6 | The chain, the guard, the parry, the poise and the hit reaction — ✅ done |
| 2.7 | **Quixote rig** — ✅ the rig and 14 clips, wired to the game's states |
| 2.8 | **Sancho rig** — ✅ the rig and 15 clips, and no action shared with Quixote's |
| 2.9 | Sancho's `Desvelar` — the verb ✅; the **VFX** are still plain |
| 2.10 | The asymmetry rules: Quixote cannot harm innocents without a Humanity cost; Sancho cannot meaningfully damage — ✅ both, and the yard shows them |
| 2.11 | **The windmill Venture** — ✅ the boss, its two forms and the two movesets; the truth resolution and the fragment reward are not in |

**2.7 and 2.8 are the two most under-rated tasks in the plan.** Distinct
animation sets sell the asymmetry better than any mechanic. A reskinned
Quixote makes the whole idea collapse. The sets are built and wired; the
**poses** are still grey-box, and the next pass is the one that makes them
read as Velazquez rather than as a fighting game.

---

## 5. Do not do these yet

- **Do not build more primitives.** Two are enough to test the mechanic; a dozen
  built on an unproven premise is the most expensive way to find out the premise
  is wrong. (The premise is now proven — but the *content* still has to earn
  its place.)
- **Do not build the whole `Lectura` system.** GDD.md §6 is weeks 5–7: the
  eye-marks, the vantage points, the found fragments, the rewards. The Examine
  verb is the *verb* the system will grow out of, not a smaller version of it.
  What the Examine panel now does — a description plus **one detail that does
  not add up** — is the seed of it. That is the whole of it for now.
- **Do not touch the Locura meter.** It is pillar P2 and the stranger's "L" is the
  one untested lever in the build.
- **Do not add languages.** Three shipped; the remaining three are a month-4 problem.

---

## 6. If you only have an hour

1. Run the build. Play it for ten minutes with the tags **off** (`F2`).
2. Go to the yard, let the dummy swing at you, and dodge *through* it. Feel
   the window of invulnerability — a quarter of a second for Quixote, twice
   that for Sancho. That is the number 2.6 has to be judged against.
3. Read `docs/PLAYTEST_NOTES.md` §7 and add a line to the observation log
   about what you feel now.
4. Open `TODO.md` and set three goals for the week. No more than three.

---

## 7. The second playtest — 20 October 2026, the owner's notes

Two notes came back from playing the build with the Examine panel and the
dodge in it. Both are answered in the code now; both need a run.

**"Examining shouldn't give away all the information. It should give the
information the character sees."** The panel printed `Realidad: roca · Libro:
libro` and `Don Quijote: libro · Sancho: roca` — the whole mechanic, handed
over, before the player had touched anything. The panel now prints **only the
reader's own perception**: a description of the thing as this character sees
it, the text on the page if it is a book, and one detail that does not add up
(*"Pesa más de lo que un libro de ese tamaño debería pesar."*). The truth
table is not in the panel any more. Neither is the other character.

**"For the dodge it is difficult to assess if it is fine at this stage
without any enemies or space limitations."** Fair: a dodge on an empty plain
is a dash, and you cannot tell a good one from a bad one. So the slice now has
a **training dummy** in a **walled yard**: it swings on a rhythm, it hurts,
you can hit it, and the walls mean there is nowhere to run. It is the
missing task 2.6b from the plan, written down and built.

**What still needs judging:** the dodge's *numbers*. The owner has already
retuned them once: the roll is **4 m** for Quixote and **2 m** for Sancho,
and Quixote's invulnerability is **0.25 s** instead of 0.4 s, because he is
not a fighter. The numbers are data now (`roll_distance` and
`iframe_seconds` in `src/data/abilities/dodge_quixote.tres` and
`dodge_sancho.tres`), and the speed follows from them. The dummy's numbers
are data too: wind-up 0.62 s, reach 2.9 m, arc 110°.

**And the lock-on is in.** `M` picks the target you are looking at, the
character turns towards it and walks around it, and the camera stands on
the line between them and frames both. It is half a camera tool and half a
combat tool, and the camera half is the one that matters: a fight you
cannot see is not a fight.

Full write-up: `docs/PLAYTEST_NOTES.md` §7.

---

## 8. The command set

| | |
|---|---|
| `tools\play.cmd` | play the grey box (any scene: `tools\play.cmd res://…`) |
| `tools\play.cmd res://src/tools/shot.tscn` | **the screenshots** — writes `artifacts/shot_*.png` |
| `.\tools\godot.ps1 --headless res://tests/test_runner.tscn` | **the tests** |
| `.\tools\godot.ps1 --headless --editor --quit` | import (run after adding assets) |
| `.\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe` | build |
| `powershell -ExecutionPolicy Bypass -File tools\setup.ps1` | **the one-command setup** |

**If you changed a `.gdshader`, re-import before you run.** A game run does not
re-import; it uses the cached shader, and you will spend twenty minutes
debugging a shader that is not the one on disk. (`HANDOVER.md` §7.)
