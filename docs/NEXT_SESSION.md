# NEXT SESSION — Fiel al Libro

> Pick the project up here. Everything below is written so that you do not
> have to re-derive anything.
>
> Last updated: **2026-11-13** · after: *"All of Phase 1 weeks 1–12 coding tasks
> complete (2.11–2.22). Only 2.23 (performance pass, blocked on headless import),
> 2.24 (balance pass, needs playtest data), 2.25 (itch.io demo, external work)
> remain."*

---

## 0. Where things stand — 30 seconds

| | |
|---|---|
| **Phase** | Phase 1. **Weeks 1–12 complete.** All coding tasks from NEXT_STEPS.md §2 are done: Venture boss, Lectura mode, three anamorphoses, Desvelar mid-fight, One Verdict, the Posada, shelf UI, Biblioteca wiring, one book, Manuscript UI shell, 15 environment kits, credits song. |
| **The premise** | **Proven.** The playtest says so. |
| **The build** | `res://src/world/slice.tscn` — the main scene. Two primitives, one truth toggle, two characters reading the same world differently — and now **all combat verbs**: `E` to examine, `Space` to dodge, a light attack that chains, a heavy attack, `F` for the guard, `M` to lock on, `X` for Sancho's Desvelar, and a line of dialogue when the world moves under a character. The two characters are **rigged and animated** (14 clips each), the **companion is in the fight** (it fights what you are locked onto, and it parries), there is a **walled yard** with a training dummy and a straw man in it, and to the **south** there is the **era of Montiel** and the **Venture of Montiel** — the first boss, in two forms. Press **G** to open the **world map** — a Spain-shaped portolan showing the five regions and which ones you've found; the map tints gilded in Book truth, chalky in Reality truth, and fragment markers appear when their page is found. **The Biblioteca shelf** (press `I`), **Manuscript UI shell** (shelf/codex/dialogue/pause pages), and **Lectura mode** (press `Q`) are all built into the shell. |
| **Tests** | 25 suites, 687 assertions, green, enforced in CI. |
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
3. **`docs/NEXT_STEPS.md` §2** — the plan. Weeks 1–12 are all done except 2.23
   (performance pass), 2.24 (balance pass), 2.25 (itch.io demo).
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
| `G` | **open the world map** — the five regions, which ones you've found |
| `V` | Sancho's second sight (off by default: the two readings disagree) |
| `L` | Quixote's Locura: Lucid ↔ Lost |
| `F1` / `F2` / `H` | help / the perception tags / the HUD |
| `I` | **Biblioteca shelf** — collected and equipped books |
| `2` | **Manifiesto codex** — collected fragments |

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

### A. Fix the performance test (2.23) — **blocked on headless import**

Headless Godot on this Windows machine does not generate `.godot/imported/*.scn`
cache for `.glb` files, so `slice.tscn` cannot load and `tests/test_performance.tscn`
hangs. **Try:** opening the Godot editor GUI once (non-headless) to trigger `.glb`
import cache generation, then re-run `res://tests/test_performance.tscn`. If that
fails, write a lightweight performance test that skips `slice.tscn` and measures
core systems only (EventBus, Locura, GameState).

### B. Run a stranger playtest

The build is ready; the mechanic has to teach itself. Give the build to somebody
who has **never seen it and never been told what any key does**. Do not explain.
Write down what they do in the first thirty seconds, and especially whether they
find the *swap* on their own.

**Press `H` before you hand it over.** The HUD is the developer's readout; it
spells out both readings. A stranger must not have it. `F2` hides the floating
tags as well.

### C. Decide what to cut or ship

**2.24 Balance pass** needs playtesting data — run a stranger session first, then
judge dodge numbers (4m/2m), iframe windows (0.25s/0.5s), and dummy stats.

**2.25 Ship the itch.io demo** — export + Steam page + wishlist campaign. External
work outside the codebase.

---

## 4. Do not do these yet

- **Do not build more primitives.** Two are enough to test the mechanic; a dozen
  built on an unproven premise is the most expensive way to find out the premise
  is wrong. (The premise is now proven — but the *content* still has to earn
  its place.)
- **Do not add languages.** Six registered (en, es, fr, de, it, pt_BR) but only
  en/es/fr are shipped with working translations. de/it/pt_BR have no PO header
  and Godot silently ignores them — this is intentional until someone writes
  those translations.
- **Do not add more books.** One book (*La Leyenda del Tío Andalus*) is in as
  a proof of concept; 47 more Manifiesto fragments are a Phase 2 writing task.

---

## 5. Do not touch these

- **Do not touch the Locura meter.** It is pillar P2 and the stranger's "L" is the
  one untested lever in the build.
- **Do not build more environment kits.** 15 exist (field, inn, road, windmill +
  bridge, castle, cave, church, cliff, fog_plane, mountain, river, theatre, village,
  inn_courtyard); only `ch_01` slice uses them inline. More kits are Phase 2 content.

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
