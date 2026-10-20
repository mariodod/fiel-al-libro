# TODO — Fiel al Libro

> Three goals per week. No more. Update this file on Monday.
> See `ROADMAP.md` §6 for the weekly ritual.
> **Picking this up? Read `docs/NEXT_SESSION.md` first.**

## Now (Phase 1 — the premise is proven; build the game around it)

- [x] **Week 1–2 grey box** — `res://src/world/slice.tscn`. A windmill that is a giant, a
      rock that is a book, one truth toggle, and two characters reading the same world
      differently. TAB swaps; the world visibly changes because *you* changed.
- [x] The reading rule, pinned down in code and in tests: `src/systems/perception.gd`
- [x] The truth-layer shader actually renders (it had never rendered — HANDOVER §7.7)
- [x] **The playtest.** Six runs by the owner, one by a stranger. The premise holds: run 4
      — *"less interesting when both see the same thing"*. The stranger was surprised by
      the *swap*. Write-up: `docs/PLAYTEST_NOTES.md` §6.
- [x] **Six of the eight "but"s fixed and shipped:** camera-relative movement, the camera
      cuts on a swap instead of sliding, the truth fade 0.9s → 0.3s, the perception tags
      are a toggle (`F2`), the camera's yaw is smoothed so it stops whipping sideways, and
      **T and L now do visibly different things** (the world's look follows the world;
      only the objects follow the reader).
- [x] **The page turn.** Pressing `T` turns a page: a sheet of paper crosses the screen
      carrying a line of the 1605 original, while the world changes behind it. GDD.md
      §4.3 — *"Pages curl… the occasional line of the actual 1605 Spanish text, faint, as
      if the world is being written under your feet."*
- [x] The first real Manifiesto fragment, loadable at runtime:
      `assets/manifiesto/bk.ch01.apertura.json` (the 1605 wording, verified)
- [x] **B6 — the Examine verb.** Press `E` next to a thing and the game tells you what it
      is: the object, the name each truth gives it, and the name each of the two of you is
      calling it right now. The third line is recomputed every frame, so it moves when the
      world moves. `src/systems/examine.gd`, `src/ui/examine_panel.gd`.
- [x] **B9 — the Examine panel gives a perception, not the truth table.** The second
      playtest: *"Examining shouldn't give away all the information. It should give the
      information the character sees."* The panel printed `Realidad: roca · Libro: libro`
      and `Don Quijote: libro · Sancho: roca` — the whole mechanic, handed over. It now
      prints one character's perception: the name, the description, the title, the text on
      the page, and **the one detail that does not add up**. The truth table and the other
      character are gone. `src/data/truth_face.gd`, `src/ui/examine_panel.gd`.
- [x] **B5 — the reaction.** When a character's reading changes, they say so, with their
      name on it: *"Don Quijote: ¡Un libro! ¡Mirad, un libro! ¿Quién lo ha puesto aquí?"*
      `src/systems/reaction.gd`, `src/ui/bark_line.gd`.
- [x] **B3, in part — the barks are heard.** `EventBus.toast` had no listener at all, so
      every bark the companion ever said went into the void. There is a voice now.
- [x] **The dodge (2.5).** `Space` dodges: a directional burst, a window of
      invulnerability, 20 stamina, and it ends with your feet planted. **And the
      stamina comes back** — it did not before: nothing in the build restored it, so
      the second dodge of a run was the last one.
      `src/data/abilities/dodge_quixote.tres`, `src/characters/character_pawn.gd`.
- [x] **B10 — something to dodge, and somewhere you cannot run.** The second playtest:
      *"For the dodge it is difficult to assess if it's fine at this stage without any
      enemies or space limitations."* There is now a **training dummy** (a telegraphed
      swing, a health bar, `K` to reset it) in a **walled yard** to the west, and the
      swings that make the dodge a decision: `LMB` light, `RMB` heavy, both costing
      stamina. `src/world/training_dummy.gd`, `src/systems/attack_hitbox.gd`.
- [x] **The dodge, retuned.** The owner read the numbers and did not like them: the roll
      is **4 m** now (not 6), **Sancho's is half of that (2 m)**, and **Quixote's
      invulnerability is 0.25 s** (not 0.4) because he is not a fighter. The distance and
      the window are **data** now — `roll_distance` and `iframe_seconds` in
      `src/data/abilities/dodge_quixote.tres` and `dodge_sancho.tres` — and the speed
      follows from them.
- [x] **The lock-on (2.5).** `M` locks onto the thing you are looking at: the character
      turns towards it and walks around it, the camera pulls back and frames both, and
      the lock is given up when the target goes down or you swap characters.
      `src/systems/lock_on.gd`, `src/systems/camera_follow.gd`.
- [x] **`H` hides the HUD.** It is the developer's readout — it spells out both readings.
      A stranger must not have it.

### This week's three goals

1. **A stranger who does not know the keys.** The build is ready for it and the owner is
   the only one who can run it. The mechanic has to teach itself. Give it to somebody who
   has never seen it, say nothing, and write down what they do in the first thirty
   seconds. Press `H` before you hand it over.
2. **Judge the dodge, with the new numbers.** The roll is 4 m for Quixote and 2 m for
   Sancho, and Quixote is only untouchable for a quarter of a second. That is a much
   tighter window than before: the question is whether a dodge is still worth 20
   stamina when it saves you for 0.25 s. Play it in the yard and write down what
   changed.
3. **B3, the rest: the companion's chatter.** The barks are visible now, but the idle
   ones are still picked at random from a pool of two. They should be about what the
   companion is actually looking at — the `TODO(Phase 1)` in `companion_ai.gd` says so,
   and `Examine.find_target` is the tool: the AI can ask what it is looking at.

### Still owed, and it is not code

- [ ] **The other fourteen runs.** Seven data points is a sample, not a signal.
- [ ] **Press `L` properly.** The stranger saw the madness; nobody has *tested* it. Push
      Quixote to Lost and press `T`: the world stops changing for him. That is the
      mechanic behind the meter. (B5 now makes the change audible — it still needs a run.)

### Named work, straight out of the playtest

- [x] **B6 — the Examine verb.** Built. Untested.
- [x] **B5 — Quixote's reaction.** Built. Untested.
- [x] **B9 — the Examine panel shows a perception, not the truth table.** Built. Untested.
- [x] **B10 — the training dummy and the walled yard.** Built. Untested.
- [ ] **B3 — the shipped game owes the companion barks.** The barks are heard now, and
      they fire when a reading changes. What is missing is the *idle* chatter: lines
      about the thing in front of them, not a random draw from a pool of two.
- [ ] **The sample Manifiesto fragment carries the 1615 wording, not the 1605.** DLC 1 is
      the 1615 book, so this is load-bearing. Only the owner can re-source it. See
      `docs/NEXT_SESSION.md` §7.

## Next (Phase 1 — weeks 3–4, combat)

- [ ] `PlayerController`: walk, run, dodge, lock-on, a soft camera (2.5) — 🟡 the **lock-on**
      is the rest of it, and the dummy is the target to lock onto
- [ ] Combat: light combo, heavy, dodge, block/parry, stamina, poise, hit reactions (2.6) —
      🟡 the dodge, the stamina and the swings that land are in
- [ ] **Quixote rig** — silhouette, lance, 8 animations (2.7)
- [ ] **Sancho rig** — a *different* silhouette, sack + flail (2.8)
- [ ] Sancho's `Desvelar` — the form-swap VFX (2.9). The playtest is already asking for it.
- [ ] The asymmetry rules: Humanity cost, and Sancho's control kit (2.10)

## Later (Phase 1, weeks 5–12)

- [ ] The windmill Venture, in both forms (2.11)
- [ ] `Lectura` mode, and three anamorphoses (2.12, 2.13) — *the basic Examine beat comes
      first, see B6*
- [ ] One Verdict — the world changes layer (2.15)
- [ ] The Posada: checkpoint, the shelf, 2 NPCs, the musician (2.16)
- [ ] The shelf UI, `Biblioteca` wired to real data, and the first book (2.17–2.19)
- [ ] The Manuscript UI shell: title, HUD, dialogue, shelf, codex, pause (2.20)
- [ ] 4 environment kits, the credits song, the min-spec performance pass (2.21–2.23)
- [ ] **Ship the itch.io demo** (2.25)

## Later (after the slice)

- [ ] Region streaming and the chapter graph (`RegionGraph` in `GameState`)
- [ ] The full 15-book library with real passives
- [ ] The Manifiesto facsimile reader (real 1605 text + modern rendering)
- [ ] The 15 Spanish-myth books with correct public-domain passives
- [ ] The *Ensayo* (D5) — the player-staged simulation
- [ ] The endings and the manuscript prologue
- [ ] The 5 region kits beyond the slice
- [ ] Localization to 6 languages (288 Manifiesto modernizations — the long pole)
- [ ] Steam page, capsule art, trailer, wishlist campaign
- [ ] 2.5D pivot evaluation, if the 3D camera fights us

## Still open (admin, not game work — these have long lead times)

- [ ] **Set up the monthly cloud backup** (Blobs / Backblaze B2 / Google Drive) — *you are one disk failure from losing two years*
- [ ] Apply the Steam Direct $100 application
- [ ] **Trademark: manual register searches** (TMview, OEPM, USPTO, WIPO) — 1–2 hours, checklist in `docs/IP_CLEARANCE.md` §4
- [ ] **Trademark: file the COMPOSITE mark** `FIEL AL LIBRO: LA LOCURA Y LA VERDAD` (EUIPO classes 9+41, ~€1,150, then USPTO ~$700). The bare phrase is descriptive and weak. Register `fielallibro.es`/`.com` first.
- [ ] **Play "Hidalgo" and "Dark Bound"** before locking the vertical slice — the closest thematic neighbours in the market
- [ ] Read the novel end to end and pick the first 16 Manifiesto fragments (D7).
      **The text is now on disk:** run `powershell -ExecutionPolicy Bypass -File
      tools\fetch_reference.ps1`. `reference\quijote_1605_parte1.txt` is the 1605 first
      part (all 52 chapters, *Curioso Impertinente* included, unwrapped for reading);
      `reference\quijote_1615_parte2.txt` is the 1615 volume; and
      `reference\quijote_1605_facsimil_ocr.txt` is the 1605 printing itself, for checking
      a wording. **Check every fragment against the printing** — the 1605 and 1615
      editions differ, and DLC 1 is the 1615 book.

## Parked (decide later, don't forget)

- [ ] Co-op networking (the architecture is already co-op-ready)
- [ ] GodotSteam integration (achievements, cloud saves, rich presence)
- [ ] Steam Workshop for user-made anamorphosis locations
- [ ] The "Códigos" screen — in-game translation import
- [ ] In-game .po import from a file picker
- [ ] Mobile export (probably never — say so out loud and stop thinking about it)
